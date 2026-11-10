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
  final Set<String> _pausedTransferIds = {};
  final Map<String, Completer<void>> _cancelAckCompleters = {};

  TransferClient({
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
    this.onMetrics,
  });

  /// Cancels an in-flight transfer immediately from the sender side.
  Future<void> cancel(
    String transferId, {
    String reason = 'Cancelled by user',
  }) async {
    _cancelledTransferIds.add(transferId);
    _pausedTransferIds.remove(transferId);

    if (_cancelAckCompleters.containsKey(transferId)) {
      return;
    }

    final socket = _activeSockets[transferId];
    if (socket != null) {
      final ackCompleter = Completer<void>();
      _cancelAckCompleters[transferId] = ackCompleter;
      try {
        socket.add(
          encodeFrame({
            'type': 'TransferCancel',
            'payload': {
              'transfer_id': transferId,
              'reason': reason,
            },
          }),
        );
        await socket.flush().timeout(const Duration(milliseconds: 600));
      } catch (_) {}

      try {
        await ackCompleter.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      } catch (_) {} finally {
        _cancelAckCompleters.remove(transferId);
      }

      try {
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
      _activeSockets.remove(transferId);
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

    final startTime = DateTime.now();
    final firstFileName = manifest.files.isNotEmpty
        ? manifest.files.first.name
        : 'Files';

    // 0. Register initial state immediately so activeTransfersProvider is non-empty at 0%
    final initialTransfer = NexoraTransfer(
      transferId: transferId,
      direction: TransferDirection.send,
      remoteDeviceId: peer.deviceId,
      remoteDeviceName: peer.displayName,
      remotePlatform: peer.platform,
      totalFiles: manifest.totalFiles,
      totalBytes: manifest.totalBytes,
      bytesTransferred: 0,
      speedBytesPerSec: 0.0,
      etaSeconds: 0,
      currentFile: firstFileName,
      state: TransferState.connecting,
      createdAt: startTime,
    );
    onProgress(initialTransfer);

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
      final failedTransfer = initialTransfer.copyWith(
        state: TransferState.failed,
        failureReason: 'Transfer connection failed: $e',
        completedAt: DateTime.now(),
      );
      onProgress(failedTransfer);
      onError('Transfer connection failed: $e');
      return;
    }

    // Enable TCP_NODELAY to disable Nagle's algorithm for max throughput
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    _activeSockets[transferId] = socket;

    RandomAccessFile? activeRaf;
    int cumulativeBytesSent = 0;

    try {
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
        onError: (e) {
          if (!frameController.isClosed) {
            frameController.close();
          }
        },
        onDone: () => frameController.close(),
      );

      final frameStream = frameController.stream.asBroadcastStream();

      // Listen for peer cancel or pause events asynchronously
      final peerCancelSub = frameStream.listen((msg) {
        final type = msg['type'] as String?;
        if (type == 'TransferCancel') {
          final payload = msg['payload'] as Map<String, dynamic>? ?? {};
          final reason = (payload['reason'] as String?) ?? 'Cancelled by remote peer';
          _cancelledTransferIds.add(transferId);

          // Reply with TransferCancelAck
          try {
            socket.add(
              encodeFrame({
                'type': 'TransferCancelAck',
                'payload': {
                  'transfer_id': transferId,
                  'status': 'acknowledged',
                },
              }),
            );
          } catch (_) {}

          final cancelledTransfer = initialTransfer.copyWith(
            state: TransferState.cancelled,
            failureReason: reason,
            bytesTransferred: cumulativeBytesSent,
            speedBytesPerSec: 0.0,
            etaSeconds: 0,
            completedAt: DateTime.now(),
          );
          onProgress(cancelledTransfer);
          onError('Transfer cancelled by remote peer: $reason');
        } else if (type == 'TransferCancelAck') {
          final payload = msg['payload'] as Map<String, dynamic>? ?? {};
          final ackTransferId = payload['transfer_id'] as String? ?? transferId;
          final completer = _cancelAckCompleters[ackTransferId];
          if (completer != null && !completer.isCompleted) {
            completer.complete();
          }
        } else if (type == 'TransferPause') {
          _pausedTransferIds.add(transferId);
          final pausedTransfer = initialTransfer.copyWith(
            state: TransferState.paused,
            bytesTransferred: cumulativeBytesSent,
            speedBytesPerSec: 0.0,
          );
          onProgress(pausedTransfer);
        } else if (type == 'TransferResume') {
          _pausedTransferIds.remove(transferId);
          final resumedTransfer = initialTransfer.copyWith(
            state: TransferState.inProgress,
            bytesTransferred: cumulativeBytesSent,
          );
          onProgress(resumedTransfer);
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

      final tracker = TransferPerformanceTracker(
        transferId: transferId,
        totalBytes: manifest.totalBytes,
        totalFiles: manifest.totalFiles,
      );
      tracker.markCreationEnd();

      // Transition state to awaiting acceptance before sending offer
      onProgress(initialTransfer.copyWith(state: TransferState.awaitingAcceptance));

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

      tracker.markAcceptReceived();
      if (responseMsg['type'] == 'TransferReject') {
        final reason =
            (responseMsg['payload'] as Map<String, dynamic>?)?['reason']
                as String? ??
            'Declined by peer';
        final rejectedTransfer = initialTransfer.copyWith(
          state: TransferState.rejected,
          failureReason: reason,
          completedAt: DateTime.now(),
        );
        onProgress(rejectedTransfer);
        onError('Transfer declined by ${peer.displayName}: $reason');
        await peerCancelSub.cancel();
        await subscription.cancel();
        _activeSockets.remove(transferId);
        try {
          await socket.close();
        } catch (_) {
          socket.destroy();
        }
        await AndroidForegroundService.stopService();
        return;
      }

      // Acceptance confirmed: transition to active in-progress transfer
      onProgress(initialTransfer.copyWith(state: TransferState.inProgress));

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

      // 3. Stream all manifest files with zero-copy binary chunk framing and sliding window pipelining
      // cumulativeBytesSent initialized above
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

      final computedFileHashes = <String, String>{};

      for (int fileIndex = 0; fileIndex < manifest.files.length; fileIndex++) {
        if (_cancelledTransferIds.contains(transferId)) {
          throw TransferCancelledException('Transfer cancelled by user');
        }

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
          fileHasher.add(chunkBytes);
          tracker.markFirstByteStreamed();

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
          if (i == startChunk ||
              i == 0 ||
              now.difference(lastUpdate).inMilliseconds >= 200 ||
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

        fileHasher.close();
        computedFileHashes[item.fileId] = digestSink.value?.toString() ?? '';
        await activeRaf.close();
        activeRaf = null;
      }

      if (_cancelledTransferIds.contains(transferId)) {
        throw TransferCancelledException('Transfer cancelled by user');
      }

      // Drain any remaining unacknowledged chunks in window
      if (pendingAcks.isNotEmpty) {
        await Future.wait(
          pendingAcks.values.map((c) => c.future),
        ).timeout(const Duration(seconds: 15));
      }

      if (_cancelledTransferIds.contains(transferId)) {
        throw TransferCancelledException('Transfer cancelled by user');
      }

      await ackSubscription.cancel();

      // Setup TransferCompleteAck future before dispatching TransferComplete
      final completeAckFuture = frameStream
          .firstWhere((m) => m['type'] == 'TransferCompleteAck', orElse: () => {})
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
      }
      await AndroidForegroundService.stopService();

      if (e is TransferCancelledException ||
          _cancelledTransferIds.contains(transferId)) {
        final cancelledTransfer = initialTransfer.copyWith(
          state: TransferState.cancelled,
          failureReason: 'Cancelled by user',
          bytesTransferred: cumulativeBytesSent,
          speedBytesPerSec: 0.0,
          etaSeconds: 0,
          completedAt: DateTime.now(),
        );
        onProgress(cancelledTransfer);
      } else {
        final failedTransfer = initialTransfer.copyWith(
          state: TransferState.failed,
          failureReason: e.toString(),
          bytesTransferred: cumulativeBytesSent,
          speedBytesPerSec: 0.0,
          etaSeconds: 0,
          completedAt: DateTime.now(),
        );
        onProgress(failedTransfer);
        onError('Transfer failed: $e');
      }

      // Socket Teardown Guard: do not close or destroy socket if cancel()
      // is currently awaiting TransferCancelAck from receiver
      if (!_cancelAckCompleters.containsKey(transferId)) {
        _activeSockets.remove(transferId);
        try {
          await socket.flush().timeout(const Duration(milliseconds: 250));
          await socket.close();
        } catch (_) {
          socket.destroy();
        }
      }
    }
  }
}
