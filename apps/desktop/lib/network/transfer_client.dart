import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import 'file_transfer_manifest.dart';
import 'protocol_messages.dart';
import 'retry_policy.dart';
import 'transfer_metrics.dart';

class TransferCancelledException implements Exception {
  final String message;
  TransferCancelledException(this.message);
  @override
  String toString() => message;
}

class TransferClient {
  final void Function(NexoraTransfer progress) onProgress;
  final void Function(NexoraTransfer completed) onCompleted;
  final void Function(String error) onError;
  final void Function(TransferPerformanceMetrics metrics)? onMetrics;

  final Map<String, Socket> _activeSockets = {};
  final Set<String> _cancelledTransferIds = {};

  TransferClient({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
    this.onMetrics,
  });

  /// Cancels an in-flight transfer immediately from the sender side.
  void cancel(String transferId) {
    _cancelledTransferIds.add(transferId);
    final socket = _activeSockets[transferId];
    if (socket != null) {
      try {
        socket.add(
          encodeFrame({
            'type': 'TransferCancel',
            'payload': {
              'transfer_id': transferId,
              'reason': 'Cancelled by user',
            },
          }),
        );
      } catch (_) {}
      try {
        socket.destroy();
      } catch (_) {}
    }
  }

  bool isCancelled(String transferId) =>
      _cancelledTransferIds.contains(transferId);

  /// Sends a single file to a target peer device.
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromFiles([file]);
    await sendManifest(
      peer: peer,
      manifest: manifest,
      localDevice: localDevice,
    );
  }

  /// Sends multiple files in a single batch to a target peer device.
  Future<void> sendFiles({
    required NexoraDevice peer,
    required List<File> files,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromFiles(files);
    await sendManifest(
      peer: peer,
      manifest: manifest,
      localDevice: localDevice,
    );
  }

  /// Recursively scans and streams an entire directory to a target peer device.
  Future<void> sendDirectory({
    required NexoraDevice peer,
    required Directory directory,
    required NexoraDevice localDevice,
  }) async {
    final manifest = await TransferManifest.fromDirectory(directory);
    await sendManifest(
      peer: peer,
      manifest: manifest,
      localDevice: localDevice,
    );
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
        return await Socket.connect(
          peer.address!,
          peer.port!,
          timeout: const Duration(seconds: 10),
        );
      });
    } catch (e) {
      onError('Transfer connection failed: $e');
      return;
    }

    final transferId = manifest.transferId;
    _cancelledTransferIds.remove(transferId);
    _activeSockets[transferId] = socket;

    RandomAccessFile? activeRaf;
    try {
      final startTime = DateTime.now();

      // 1. Send Hello
      socket.add(
        encodeFrame({
          'type': 'Hello',
          'payload': {
            'protocol_version': currentProtocolVersion,
            'device': {
              'device_id': localDevice.deviceId,
              'display_name': localDevice.displayName,
              'platform': localDevice.platform,
              'fingerprint': localDevice.fingerprint,
            },
          },
        }),
      );

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
      final helloMsg = await frameStream
          .firstWhere((m) => m['type'] == 'Hello')
          .timeout(const Duration(seconds: 5));
      if (helloMsg.isEmpty) {
        throw Exception('Peer handshake failed');
      }

      final tracker = TransferPerformanceTracker(
        transferId: transferId,
        totalBytes: manifest.totalBytes,
        totalFiles: manifest.totalFiles,
      );
      tracker.markCreationEnd();

      // Log in SQLite
      try {
        await DatabaseService.instance.logTransfer(
          NexoraTransfer(
            transferId: transferId,
            direction: TransferDirection.send,
            remoteDeviceId: peer.deviceId,
            remoteDeviceName: peer.displayName,
            totalFiles: manifest.totalFiles,
            totalBytes: manifest.totalBytes,
            currentFile: manifest.files.isNotEmpty
                ? manifest.files.first.name
                : '',
            state: TransferState.inProgress,
            createdAt: startTime,
          ),
        );
      } catch (_) {}

      // 2. Send Lightweight TransferOffer IMMEDIATELY without waiting for whole-file hashing
      tracker.markOfferSent();
      socket.add(
        encodeFrame({
          'type': 'TransferOffer',
          'payload': {
            'transfer_id': transferId,
            'sender': {
              'device_id': localDevice.deviceId,
              'display_name': localDevice.displayName,
              'platform': localDevice.platform,
            },
            'manifest': manifest.toJson(),
          },
        }),
      );

      // Wait for Accept or Reject
      final responseMsg = await frameStream
          .firstWhere(
            (m) =>
                m['type'] == 'TransferAccept' || m['type'] == 'TransferReject',
          )
          .timeout(const Duration(seconds: 30));

      if (responseMsg['type'] == 'TransferReject') {
        final reason =
            (responseMsg['payload'] as Map<String, dynamic>)['reason']
                as String? ??
            'Declined';
        onError('Transfer declined by ${peer.displayName}: $reason');
        await subscription.cancel();
        socket.destroy();
        return;
      }

      // If resuming, send TransferResume query and negotiate starting offset
      int currentFileResumeOffset = resumeOffset;
      if (resumeOffset > 0 && manifest.files.isNotEmpty) {
        socket.add(
          encodeFrame({
            'type': 'TransferResume',
            'payload': {
              'transfer_id': transferId,
              'file_id': manifest.files.first.fileId,
              'resume_offset': resumeOffset,
            },
          }),
        );

        final resumeAck = await frameStream
            .firstWhere((m) => m['type'] == 'TransferResumeAck')
            .timeout(const Duration(seconds: 5));
        currentFileResumeOffset =
            (resumeAck['payload']['verified_offset'] as int? ?? resumeOffset);
      }

      // 3. Stream all manifest files sequentially in 1 MB chunks with backpressure
      int cumulativeBytesSent = 0;
      DateTime lastUpdate = DateTime.now();

      tracker.markAcceptReceived();
      final computedFileHashes = <String, String>{};

      for (int fileIndex = 0; fileIndex < manifest.files.length; fileIndex++) {
        final item = manifest.files[fileIndex];
        if (item.localPath == null) continue;

        final localFile = File(item.localPath!);
        if (!await localFile.exists()) continue;

        final fileLength = item.sizeBytes;
        final startOffset = (fileIndex == 0) ? currentFileResumeOffset : 0;
        cumulativeBytesSent += startOffset;

        final totalChunks = fileLength == 0
            ? 1
            : ((fileLength + defaultChunkSize - 1) ~/ defaultChunkSize);
        final startChunk = startOffset ~/ defaultChunkSize;

        activeRaf = await localFile.open(mode: FileMode.read);
        final digestSink = DigestSink();
        final fileHasher = sha256.startChunkedConversion(digestSink);

        try {
          for (int i = startChunk; i < totalChunks; i++) {
            if (_cancelledTransferIds.contains(transferId)) {
              throw TransferCancelledException('Transfer cancelled by user');
            }
            final offset = i * defaultChunkSize;
            final chunkSize = (fileLength - offset).clamp(0, defaultChunkSize);
            activeRaf.setPositionSync(offset);
            final chunkBytes = activeRaf.readSync(chunkSize);
            fileHasher.add(chunkBytes);
            tracker.markFirstByteStreamed();
            final chunkHash = sha256.convert(chunkBytes).toString();

            socket.add(
              encodeFrame({
                'type': 'ChunkData',
                'payload': {
                  'transfer_id': transferId,
                  'file_id': item.fileId,
                  'chunk_index': i,
                  'total_chunks': totalChunks,
                  'offset': offset,
                  'data': chunkBytes,
                  'chunk_sha256': chunkHash,
                },
              }),
            );

            // Await ChunkAck from receiver for flow control
            await frameStream
                .firstWhere(
                  (m) =>
                      m['type'] == 'ChunkAck' &&
                      (m['payload']['chunk_index'] as int) == i,
                )
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
            if (now.difference(lastUpdate).inMilliseconds >= 250 ||
                cumulativeBytesSent >= manifest.totalBytes) {
              lastUpdate = now;
              final elapsedSeconds =
                  now.difference(startTime).inMilliseconds / 1000.0;
              final speedBps = elapsedSeconds > 0
                  ? (cumulativeBytesSent / elapsedSeconds)
                  : 0.0;
              final remainingBytes = (manifest.totalBytes - cumulativeBytesSent)
                  .clamp(0, manifest.totalBytes);
              final eta = speedBps > 0
                  ? (remainingBytes / speedBps).round()
                  : 0;

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

          fileHasher.close();
          computedFileHashes[item.fileId] = digestSink.value?.toString() ?? '';
        } finally {
          try {
            await activeRaf.close();
          } catch (_) {}
          activeRaf = null;
        }
      }

      // Setup TransferCompleteAck future before dispatching TransferComplete
      final completeAckFuture = frameStream
          .firstWhere((m) => m['type'] == 'TransferCompleteAck')
          .timeout(const Duration(seconds: 10), onTimeout: () => {});

      // 4. Send TransferComplete with on-the-fly computed full-file SHA-256 hashes
      socket.add(
        encodeFrame({
          'type': 'TransferComplete',
          'payload': {
            'transfer_id': transferId,
            'verified_files': manifest.totalFiles,
            'file_hashes': computedFileHashes,
          },
        }),
      );
      try {
        await socket.flush();
      } catch (_) {}

      // Await confirmation that receiver has flushed and verified files
      await completeAckFuture;
      tracker.markTransferComplete();

      final metrics = tracker.buildMetrics();
      onMetrics?.call(metrics);

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
        currentFile: manifest.files.isNotEmpty
            ? manifest.files.first.name
            : 'Done',
        state: TransferState.completed,
        createdAt: startTime,
        completedAt: DateTime.now(),
      );

      onCompleted(completedTransfer);

      _activeSockets.remove(transferId);
      await subscription.cancel();
      try {
        await socket.flush();
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
    } catch (e) {
      if (activeRaf != null) {
        try {
          await activeRaf.close();
        } catch (_) {}
        activeRaf = null;
      }
      _activeSockets.remove(transferId);
      if (e is! TransferCancelledException &&
          !_cancelledTransferIds.contains(transferId)) {
        onError('Transfer failed: $e');
      }
      socket.destroy();
    }
  }
}
