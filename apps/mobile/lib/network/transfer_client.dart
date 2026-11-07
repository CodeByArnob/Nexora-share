import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../services/android_foreground_service.dart';
import 'protocol_messages.dart';

class TransferClient {
  final void Function(NexoraTransfer progress) onProgress;
  final void Function(NexoraTransfer completed) onCompleted;
  final void Function(String error) onError;

  TransferClient({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  });

  /// Sends a local file to a target peer device over the local network.
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
    required NexoraDevice localDevice,
  }) async {
    if (peer.address == null || peer.port == null) {
      onError('Target device address or port is unavailable');
      return;
    }

    Socket? socket;
    try {
      socket = await Socket.connect(peer.address!, peer.port!, timeout: const Duration(seconds: 10));

      final transferId = const Uuid().v4();
      final fileName = file.path.split(RegExp(r'[\\/]')).last;
      final fileLength = await file.length();
      final startTime = DateTime.now();

      // Start Android Foreground Service for sender
      await AndroidForegroundService.startService(fileName: fileName, isSending: true);

      // 1. Send Hello
      socket.add(encodeFrame({
        'type': 'Hello',
        'payload': {
          'protocol_version': currentProtocolVersion,
          'device': {
            'device_id': localDevice.deviceId,
            'display_name': localDevice.displayName,
            'platform': localDevice.platform,
            'fingerprint': localDevice.fingerprint,
          }
        }
      }));

      // Stream frames from socket
      final frameController = StreamController<Map<String, dynamic>>();
      final buffer = BytesBuilder(copy: false);
      int expectedLength = -1;

      final subscription = socket.listen(
        (data) {
          buffer.add(data);
          while (true) {
            if (expectedLength == -1) {
              if (buffer.length < lengthPrefixSize) break;
              final prefix = buffer.toBytes().sublist(0, lengthPrefixSize);
              final bd = ByteData.view(prefix.buffer);
              expectedLength = bd.getUint32(0, Endian.big);
            }

            final totalRequired = lengthPrefixSize + expectedLength;
            if (buffer.length < totalRequired) break;

            final all = buffer.takeBytes();
            final payload = all.sublist(lengthPrefixSize, totalRequired);
            if (all.length > totalRequired) {
              buffer.add(all.sublist(totalRequired));
            }
            expectedLength = -1;

            try {
              final msg = decodeFramePayload(payload);
              frameController.add(msg);
            } catch (_) {}
          }
        },
        onError: (e) => frameController.addError(e),
        onDone: () => frameController.close(),
      );

      final frameStream = frameController.stream.asBroadcastStream();

      // Wait for Hello response
      final helloMsg = await frameStream.firstWhere((m) => m['type'] == 'Hello').timeout(const Duration(seconds: 5));
      if (helloMsg.isEmpty) {
        throw Exception('Peer handshake failed');
      }

      // Compute full file SHA-256 for integrity verification
      Digest? digestResult;
      await for (final d in sha256.bind(file.openRead())) {
        digestResult = d;
      }
      final fileSha256 = (digestResult ?? sha256.convert(const [])).toString();

      // 2. Send TransferOffer
      socket.add(encodeFrame({
        'type': 'TransferOffer',
        'payload': {
          'transfer_id': transferId,
          'sender': {
            'device_id': localDevice.deviceId,
            'display_name': localDevice.displayName,
            'platform': localDevice.platform,
          },
          'manifest': {
            'transfer_id': transferId,
            'total_files': 1,
            'total_bytes': fileLength,
            'chunk_size': defaultChunkSize,
            'files': [
              {
                'file_id': 'f-1',
                'name': fileName,
                'size_bytes': fileLength,
                'sha256_hash': fileSha256,
              }
            ]
          }
        }
      }));

      // Wait for Accept or Reject
      final responseMsg = await frameStream
          .firstWhere((m) => m['type'] == 'TransferAccept' || m['type'] == 'TransferReject')
          .timeout(const Duration(seconds: 30));

      if (responseMsg['type'] == 'TransferReject') {
        final reason = (responseMsg['payload'] as Map<String, dynamic>)['reason'] as String? ?? 'Declined';
        onError('Transfer declined by ${peer.displayName}: $reason');
        await AndroidForegroundService.stopService();
        await subscription.cancel();
        socket.destroy();
        return;
      }

      // 3. Stream File in 1 MB chunks with backpressure
      final totalChunks = fileLength == 0 ? 1 : ((fileLength + defaultChunkSize - 1) ~/ defaultChunkSize);
      final raf = await file.open(mode: FileMode.read);
      int bytesSent = 0;
      DateTime lastUpdate = DateTime.now();

      for (int i = 0; i < totalChunks; i++) {
        final offset = i * defaultChunkSize;
        final chunkSize = (fileLength - offset).clamp(0, defaultChunkSize);
        raf.setPositionSync(offset);
        final chunkBytes = raf.readSync(chunkSize);
        final chunkHash = sha256.convert(chunkBytes).toString();

        socket.add(encodeFrame({
          'type': 'ChunkData',
          'payload': {
            'transfer_id': transferId,
            'file_id': 'f-1',
            'chunk_index': i,
            'total_chunks': totalChunks,
            'offset': offset,
            'data': chunkBytes,
            'chunk_sha256': chunkHash,
          }
        }));

        // Await ChunkAck from receiver for backpressure
        await frameStream
            .firstWhere((m) => m['type'] == 'ChunkAck' && (m['payload']['chunk_index'] as int) == i)
            .timeout(const Duration(seconds: 15));

        bytesSent += chunkBytes.length;

        // Emit progress
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds >= 300 || bytesSent >= fileLength) {
          lastUpdate = now;
          final elapsedSeconds = now.difference(startTime).inMilliseconds / 1000.0;
          final speedBps = elapsedSeconds > 0 ? (bytesSent / elapsedSeconds) : 0.0;
          final remainingBytes = (fileLength - bytesSent).clamp(0, fileLength);
          final eta = speedBps > 0 ? (remainingBytes / speedBps).round() : 0;
          final percent = fileLength > 0 ? ((bytesSent / fileLength) * 100).round() : 100;

          final progressTransfer = NexoraTransfer(
            transferId: transferId,
            direction: TransferDirection.send,
            remoteDeviceId: peer.deviceId,
            remoteDeviceName: peer.displayName,
            totalFiles: 1,
            totalBytes: fileLength,
            bytesTransferred: bytesSent,
            speedBytesPerSec: speedBps,
            etaSeconds: eta,
            currentFile: fileName,
            state: TransferState.inProgress,
            createdAt: startTime,
          );

          onProgress(progressTransfer);

          await AndroidForegroundService.updateProgress(
            fileName: fileName,
            progressPercent: percent,
            speed: progressTransfer.formattedSpeed,
          );
        }
      }

      await raf.close();

      // 4. Send TransferComplete
      socket.add(encodeFrame({
        'type': 'TransferComplete',
        'payload': {
          'transfer_id': transferId,
          'verified_files': 1,
        }
      }));

      await AndroidForegroundService.stopService();

      final completedTransfer = NexoraTransfer(
        transferId: transferId,
        direction: TransferDirection.send,
        remoteDeviceId: peer.deviceId,
        remoteDeviceName: peer.displayName,
        totalFiles: 1,
        totalBytes: fileLength,
        bytesTransferred: fileLength,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: fileName,
        state: TransferState.completed,
        createdAt: startTime,
        completedAt: DateTime.now(),
      );

      onCompleted(completedTransfer);

      await subscription.cancel();
      socket.destroy();
    } catch (e) {
      await AndroidForegroundService.stopService();
      onError('Transfer failed: $e');
      socket?.destroy();
    }
  }
}
