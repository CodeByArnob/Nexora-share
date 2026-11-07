import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../services/android_foreground_service.dart';
import 'file_transfer_manifest.dart';
import 'protocol_messages.dart';
import 'retry_policy.dart';

class TransferClient {
  final void Function(NexoraTransfer progress) onProgress;
  final void Function(NexoraTransfer completed) onCompleted;
  final void Function(String error) onError;

  TransferClient({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  });

  /// Sends a single file to a target peer device.
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromFiles([file]);
    await sendManifest(peer: peer, manifest: manifest, localDevice: localDevice);
  }

  /// Sends multiple files in a single batch to a target peer device.
  Future<void> sendFiles({
    required NexoraDevice peer,
    required List<File> files,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromFiles(files);
    await sendManifest(peer: peer, manifest: manifest, localDevice: localDevice);
  }

  /// Recursively scans and streams an entire directory to a target peer device.
  Future<void> sendDirectory({
    required NexoraDevice peer,
    required Directory directory,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromDirectory(directory);
    await sendManifest(peer: peer, manifest: manifest, localDevice: localDevice);
  }

  /// Streams a full multi-file/folder manifest with bounded chunking and resume support.
  Future<void> sendManifest({
    required NexoraDevice peer,
    required TransferManifest manifest,
    required NexoraDevice localDevice,
    int resumeOffset = 0,
  }) async {
    if (peer.address == null || peer.port == null) {
      onError('Target device address or port is unavailable');
      return;
    }

    final retryPolicy = const RetryPolicy(maxAttempts: 3);
    final Socket socket;
    try {
      socket = await retryPolicy.execute((attempt) async {
        return await Socket.connect(peer.address!, peer.port!, timeout: const Duration(seconds: 10));
      });
    } catch (e) {
      await AndroidForegroundService.stopService();
      onError('Transfer connection failed: $e');
      return;
    }

    try {
      final transferId = manifest.transferId;
      final startTime = DateTime.now();

      final firstFileName = manifest.files.isNotEmpty ? manifest.files.first.name : 'Files';
      await AndroidForegroundService.startService(fileName: firstFileName, isSending: true);

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

      // Compute SHA-256 hashes for all manifest files if not present
      final verifiedItems = <ManifestItem>[];
      for (final item in manifest.files) {
        String sha = item.sha256Hash ?? '';
        if (sha.isEmpty && item.localPath != null) {
          final f = File(item.localPath!);
          if (await f.exists()) {
            Digest? d;
            await for (final digest in sha256.bind(f.openRead())) {
              d = digest;
            }
            sha = (d ?? sha256.convert(const [])).toString();
          }
        }
        verifiedItems.add(ManifestItem(
          fileId: item.fileId,
          name: item.name,
          relativePath: item.relativePath,
          sizeBytes: item.sizeBytes,
          sha256Hash: sha,
          localPath: item.localPath,
        ));
      }

      final verifiedManifest = TransferManifest(
        transferId: transferId,
        files: verifiedItems,
        totalFiles: manifest.totalFiles,
        totalBytes: manifest.totalBytes,
      );

      // Log in SQLite
      try {
        await DatabaseService.instance.logTransfer(NexoraTransfer(
          transferId: transferId,
          direction: TransferDirection.send,
          remoteDeviceId: peer.deviceId,
          remoteDeviceName: peer.displayName,
          totalFiles: manifest.totalFiles,
          totalBytes: manifest.totalBytes,
          currentFile: manifest.files.isNotEmpty ? manifest.files.first.name : '',
          state: TransferState.inProgress,
          createdAt: startTime,
        ));
      } catch (_) {}

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
          'manifest': verifiedManifest.toJson(),
        }
      }));

      // Wait for Accept or Reject
      final responseMsg = await frameStream
          .firstWhere((m) => m['type'] == 'TransferAccept' || m['type'] == 'TransferReject')
          .timeout(const Duration(seconds: 30));

      if (responseMsg['type'] == 'TransferReject') {
        final reason = (responseMsg['payload'] as Map<String, dynamic>)['reason'] as String? ?? 'Declined';
        onError('Transfer declined by ${peer.displayName}: $reason');
        await subscription.cancel();
        socket.destroy();
        await AndroidForegroundService.stopService();
        return;
      }

      // If resuming, send TransferResume query and negotiate starting offset
      int currentFileResumeOffset = resumeOffset;
      if (resumeOffset > 0 && verifiedItems.isNotEmpty) {
        socket.add(encodeFrame({
          'type': 'TransferResume',
          'payload': {
            'transfer_id': transferId,
            'file_id': verifiedItems.first.fileId,
            'resume_offset': resumeOffset,
          }
        }));

        final resumeAck = await frameStream
            .firstWhere((m) => m['type'] == 'TransferResumeAck')
            .timeout(const Duration(seconds: 5));
        currentFileResumeOffset = (resumeAck['payload']['verified_offset'] as int? ?? resumeOffset);
      }

      // 3. Stream all manifest files sequentially in 1 MB chunks with backpressure
      int cumulativeBytesSent = 0;
      DateTime lastUpdate = DateTime.now();

      for (int fileIndex = 0; fileIndex < verifiedItems.length; fileIndex++) {
        final item = verifiedItems[fileIndex];
        if (item.localPath == null) continue;

        final localFile = File(item.localPath!);
        if (!await localFile.exists()) continue;

        final fileLength = item.sizeBytes;
        final startOffset = (fileIndex == 0) ? currentFileResumeOffset : 0;
        cumulativeBytesSent += startOffset;

        final totalChunks = fileLength == 0 ? 1 : ((fileLength + defaultChunkSize - 1) ~/ defaultChunkSize);
        final startChunk = startOffset ~/ defaultChunkSize;

        final raf = await localFile.open(mode: FileMode.read);

        for (int i = startChunk; i < totalChunks; i++) {
          final offset = i * defaultChunkSize;
          final chunkSize = (fileLength - offset).clamp(0, defaultChunkSize);
          raf.setPositionSync(offset);
          final chunkBytes = raf.readSync(chunkSize);
          final chunkHash = sha256.convert(chunkBytes).toString();

          socket.add(encodeFrame({
            'type': 'ChunkData',
            'payload': {
              'transfer_id': transferId,
              'file_id': item.fileId,
              'chunk_index': i,
              'total_chunks': totalChunks,
              'offset': offset,
              'data': chunkBytes,
              'chunk_sha256': chunkHash,
            }
          }));

          // Await ChunkAck from receiver for flow control
          await frameStream
              .firstWhere((m) => m['type'] == 'ChunkAck' && (m['payload']['chunk_index'] as int) == i)
              .timeout(const Duration(seconds: 15));

          cumulativeBytesSent += chunkBytes.length;

          // Record verified checkpoint
          try {
            await DatabaseService.instance.recordVerifiedChunk(
              transferId: transferId,
              fileId: item.fileId,
              chunkIndex: i,
              chunkOffset: offset,
              chunkSize: chunkBytes.length,
              chunkSha256: chunkHash,
            );
          } catch (_) {}

          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds >= 250 || cumulativeBytesSent >= manifest.totalBytes) {
            lastUpdate = now;
            final elapsedSeconds = now.difference(startTime).inMilliseconds / 1000.0;
            final speedBps = elapsedSeconds > 0 ? (cumulativeBytesSent / elapsedSeconds) : 0.0;
            final remainingBytes = (manifest.totalBytes - cumulativeBytesSent).clamp(0, manifest.totalBytes);
            final eta = speedBps > 0 ? (remainingBytes / speedBps).round() : 0;

            final pct = manifest.totalBytes > 0
                ? ((cumulativeBytesSent / manifest.totalBytes) * 100).round()
                : 0;
            final speedStr = speedBps >= 1024 * 1024
                ? '${(speedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s'
                : '${(speedBps / 1024).toStringAsFixed(1)} KB/s';

            await AndroidForegroundService.updateProgress(
              fileName: item.name,
              progressPercent: pct,
              speed: speedStr,
            );

            final progressTransfer = NexoraTransfer(
              transferId: transferId,
              direction: TransferDirection.send,
              remoteDeviceId: peer.deviceId,
              remoteDeviceName: peer.displayName,
              totalFiles: manifest.totalFiles,
              totalBytes: manifest.totalBytes,
              bytesTransferred: cumulativeBytesSent,
              speedBytesPerSec: speedBps,
              etaSeconds: eta,
              currentFile: item.name,
              state: TransferState.inProgress,
              createdAt: startTime,
            );

            onProgress(progressTransfer);
          }
        }

        await raf.close();
      }

      // 4. Send TransferComplete
      socket.add(encodeFrame({
        'type': 'TransferComplete',
        'payload': {
          'transfer_id': transferId,
          'verified_files': manifest.totalFiles,
        }
      }));

      await AndroidForegroundService.stopService();

      // Update SQLite state
      try {
        await DatabaseService.instance.updateTransferProgress(
          transferId,
          manifest.totalBytes,
          TransferState.completed,
        );
        await DatabaseService.instance.clearResumeCheckpoints(transferId);
      } catch (_) {}

      final completedTransfer = NexoraTransfer(
        transferId: transferId,
        direction: TransferDirection.send,
        remoteDeviceId: peer.deviceId,
        remoteDeviceName: peer.displayName,
        totalFiles: manifest.totalFiles,
        totalBytes: manifest.totalBytes,
        bytesTransferred: manifest.totalBytes,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: manifest.files.isNotEmpty ? manifest.files.first.name : 'Done',
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
      socket.destroy();
    }
  }
}
