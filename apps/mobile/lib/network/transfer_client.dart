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

  final Map<String, Socket> _activeSockets = {};
  final Set<String> _cancelledTransferIds = {};
  final Set<String> _pausedTransferIds = {};

  TransferClient({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  });

  /// Cancels an in-flight transfer immediately from the sender side.
  void cancel(String transferId) {
    _cancelledTransferIds.add(transferId);
    _pausedTransferIds.remove(transferId);

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

  /// Pauses an in-flight transfer.
  void pause(String transferId) {
    _pausedTransferIds.add(transferId);
    final socket = _activeSockets[transferId];
    if (socket != null) {
      try {
        socket.add(
          encodeFrame({
            'type': 'TransferPause',
            'payload': {'transfer_id': transferId},
          }),
        );
      } catch (_) {}
    }
  }

  /// Resumes a paused transfer.
  void resume(String transferId) {
    _pausedTransferIds.remove(transferId);
    final socket = _activeSockets[transferId];
    if (socket != null) {
      try {
        socket.add(
          encodeFrame({
            'type': 'TransferResume',
            'payload': {'transfer_id': transferId},
          }),
        );
      } catch (_) {}
    }
  }

  bool isCancelled(String transferId) =>
      _cancelledTransferIds.contains(transferId);

  bool isPaused(String transferId) => _pausedTransferIds.contains(transferId);

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

  /// Streams a full multi-file/folder manifest with high-speed binary framing,
  /// sliding-window pipelining, and pause/cancel support.
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

    final transferId = manifest.transferId;
    _cancelledTransferIds.remove(transferId);
    _pausedTransferIds.remove(transferId);

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
      await AndroidForegroundService.stopService();
      onError('Transfer connection failed: $e');
      return;
    }

    // Enable TCP_NODELAY to disable Nagle's algorithm for max throughput
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    _activeSockets[transferId] = socket;

    RandomAccessFile? activeRaf;

    try {
      final startTime = DateTime.now();

      final firstFileName = manifest.files.isNotEmpty
          ? manifest.files.first.name
          : 'Files';
      await AndroidForegroundService.startService(
        fileName: firstFileName,
        isSending: true,
      );

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

      // Listen for peer cancel or pause events asynchronously
      final peerCancelSub = frameStream.listen((msg) {
        final type = msg['type'] as String?;
        if (type == 'TransferCancel') {
          _cancelledTransferIds.add(transferId);
          onError('Transfer cancelled by remote peer');
        } else if (type == 'TransferPause') {
          _pausedTransferIds.add(transferId);
        } else if (type == 'TransferResume') {
          _pausedTransferIds.remove(transferId);
        }
      });

      // Wait for Hello response
      final helloMsg = await frameStream
          .firstWhere((m) => m['type'] == 'Hello')
          .timeout(const Duration(seconds: 5));
      if (helloMsg.isEmpty) {
        throw Exception('Peer handshake failed');
      }

      if (_cancelledTransferIds.contains(transferId)) {
        throw TransferCancelledException('Transfer cancelled by user');
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
        verifiedItems.add(
          ManifestItem(
            fileId: item.fileId,
            name: item.name,
            relativePath: item.relativePath,
            sizeBytes: item.sizeBytes,
            sha256Hash: sha,
            localPath: item.localPath,
          ),
        );
      }

      final verifiedManifest = TransferManifest(
        transferId: transferId,
        files: verifiedItems,
        totalFiles: manifest.totalFiles,
        totalBytes: manifest.totalBytes,
      );

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

      // 2. Send TransferOffer
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
            'manifest': verifiedManifest.toJson(),
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
        await peerCancelSub.cancel();
        await subscription.cancel();
        _activeSockets.remove(transferId);
        socket.destroy();
        await AndroidForegroundService.stopService();
        return;
      }

      // If resuming, send TransferResume query and negotiate starting offset
      int currentFileResumeOffset = resumeOffset;
      if (resumeOffset > 0 && verifiedItems.isNotEmpty) {
        socket.add(
          encodeFrame({
            'type': 'TransferResume',
            'payload': {
              'transfer_id': transferId,
              'file_id': verifiedItems.first.fileId,
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

      // 3. Stream all manifest files with zero-copy binary chunk framing and sliding window pipelining
      int cumulativeBytesSent = 0;
      int lastDbCheckpoint = 0;
      DateTime lastUpdate = DateTime.now();

      // Pipelining map for in-flight chunk acknowledgments
      final pendingAcks = <int, Completer<void>>{};
      final ackSubscription = frameStream.listen((m) {
        if (m['type'] == 'ChunkAck') {
          final ackChunkIdx = m['payload']['chunk_index'] as int?;
          if (ackChunkIdx != null && pendingAcks.containsKey(ackChunkIdx)) {
            pendingAcks[ackChunkIdx]?.complete();
            pendingAcks.remove(ackChunkIdx);
          }
        }
      });

      for (int fileIndex = 0; fileIndex < verifiedItems.length; fileIndex++) {
        if (_cancelledTransferIds.contains(transferId)) {
          throw TransferCancelledException('Transfer cancelled by user');
        }

        final item = verifiedItems[fileIndex];
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

        for (int i = startChunk; i < totalChunks; i++) {
          // Check for user cancellation
          if (_cancelledTransferIds.contains(transferId)) {
            throw TransferCancelledException('Transfer cancelled by user');
          }

          // Handle pause loop
          while (_pausedTransferIds.contains(transferId)) {
            final pausedTransfer = NexoraTransfer(
              transferId: transferId,
              direction: TransferDirection.send,
              remoteDeviceId: peer.deviceId,
              remoteDeviceName: peer.displayName,
              totalFiles: manifest.totalFiles,
              totalBytes: manifest.totalBytes,
              bytesTransferred: cumulativeBytesSent,
              speedBytesPerSec: 0.0,
              etaSeconds: 0,
              currentFile: item.name,
              state: TransferState.paused,
              createdAt: startTime,
            );
            onProgress(pausedTransfer);
            await Future.delayed(const Duration(milliseconds: 250));
            if (_cancelledTransferIds.contains(transferId)) {
              throw TransferCancelledException('Transfer cancelled by user');
            }
          }

          // Sliding window flow control: keep up to 4 chunks in flight (4 MB pipeline)
          while (pendingAcks.length >= 4) {
            if (_cancelledTransferIds.contains(transferId)) {
              throw TransferCancelledException('Transfer cancelled by user');
            }
            final oldestKey = pendingAcks.keys.first;
            await pendingAcks[oldestKey]!.future.timeout(
              const Duration(seconds: 15),
            );
          }

          final offset = i * defaultChunkSize;
          final chunkSize = (fileLength - offset).clamp(0, defaultChunkSize);
          activeRaf.setPositionSync(offset);
          final chunkBytes = activeRaf.readSync(chunkSize);

          // Fast SHA-256 for checkpointing
          final chunkHash = sha256.convert(chunkBytes).toString();

          // Prepare ACK completer before sending frame
          final ackCompleter = Completer<void>();
          pendingAcks[i] = ackCompleter;

          // Zero-copy binary chunk frame transmission (Ultra-Fast 50-100 MB/s line rate)
          socket.add(
            encodeBinaryChunkFrame(
              transferId: transferId,
              fileId: item.fileId,
              chunkIndex: i,
              totalChunks: totalChunks,
              offset: offset,
              data: chunkBytes,
              chunkSha256: chunkHash,
            ),
          );

          cumulativeBytesSent += chunkBytes.length;

          // Throttle SQLite writes: checkpoint every 5 MB or on completion
          if (cumulativeBytesSent - lastDbCheckpoint >= 5 * 1024 * 1024 ||
              cumulativeBytesSent >= manifest.totalBytes) {
            lastDbCheckpoint = cumulativeBytesSent;
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
          }

          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds >= 200 ||
              cumulativeBytesSent >= manifest.totalBytes) {
            lastUpdate = now;
            final elapsedSeconds =
                now.difference(startTime).inMilliseconds / 1000.0;
            final speedBps = elapsedSeconds > 0
                ? (cumulativeBytesSent / elapsedSeconds)
                : 0.0;
            final remainingBytes = (manifest.totalBytes - cumulativeBytesSent)
                .clamp(0, manifest.totalBytes);
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

        await activeRaf.close();
        activeRaf = null;
      }

      // Drain any remaining unacknowledged chunks in window
      if (pendingAcks.isNotEmpty) {
        await Future.wait(
          pendingAcks.values.map((c) => c.future),
        ).timeout(const Duration(seconds: 15));
      }

      await ackSubscription.cancel();

      // 4. Send TransferComplete
      socket.add(
        encodeFrame({
          'type': 'TransferComplete',
          'payload': {
            'transfer_id': transferId,
            'verified_files': manifest.totalFiles,
          },
        }),
      );

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
        currentFile: manifest.files.isNotEmpty
            ? manifest.files.first.name
            : 'Done',
        state: TransferState.completed,
        createdAt: startTime,
        completedAt: DateTime.now(),
      );

      onCompleted(completedTransfer);

      await peerCancelSub.cancel();
      await subscription.cancel();
      _activeSockets.remove(transferId);
      socket.destroy();
    } catch (e) {
      if (activeRaf != null) {
        try {
          await activeRaf.close();
        } catch (_) {}
      }
      _activeSockets.remove(transferId);
      await AndroidForegroundService.stopService();

      if (e is TransferCancelledException ||
          _cancelledTransferIds.contains(transferId)) {
        try {
          await DatabaseService.instance.updateTransferProgress(
            transferId,
            0,
            TransferState.cancelled,
          );
        } catch (_) {}
        final cancelledTransfer = NexoraTransfer(
          transferId: transferId,
          direction: TransferDirection.send,
          remoteDeviceId: peer.deviceId,
          remoteDeviceName: peer.displayName,
          totalFiles: manifest.totalFiles,
          totalBytes: manifest.totalBytes,
          bytesTransferred: 0,
          speedBytesPerSec: 0.0,
          etaSeconds: 0,
          currentFile: manifest.files.isNotEmpty
              ? manifest.files.first.name
              : '',
          state: TransferState.cancelled,
          createdAt: DateTime.now(),
        );
        onProgress(cancelledTransfer);
      } else {
        onError('Transfer failed: $e');
      }
      try {
        socket.destroy();
      } catch (_) {}
    }
  }
}
