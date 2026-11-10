import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../database/database_service.dart';
import '../models/transfer_model.dart';
import '../services/android_foreground_service.dart';
import '../services/media_store_service.dart';
import 'file_transfer_manifest.dart';
import 'protocol_messages.dart';
import 'transfer_metrics.dart';

class IncomingTransferOffer {
  final String transferId;
  final String senderName;
  final String senderPlatform;
  final String fileName;
  final int totalBytes;
  final int totalFiles;
  final String? declaredSha256;
  final List<ManifestItem> files;

  IncomingTransferOffer({
    required this.transferId,
    required this.senderName,
    required this.senderPlatform,
    required this.fileName,
    required this.totalBytes,
    required this.totalFiles,
    this.declaredSha256,
    this.files = const [],
  });
}

class TransferServer {
  ServerSocket? _serverSocket;
  int port = 48842;

  final Directory? customDestinationDirectory;
  final Future<bool> Function(IncomingTransferOffer offer) onRequestApproval;
  final void Function(NexoraTransfer transfer) onTransferProgress;
  final void Function(NexoraTransfer completedTransfer) onTransferCompleted;
  final void Function(String error)? onError;
  final Future<bool> Function(int requiredBytes)? checkStorageSpace;

  final Map<String, Socket> _activeSockets = {};
  final Map<String, NexoraTransfer> _activeTransfers = {};
  final Set<String> _cancelledTransferIds = {};
  final Set<String> _pausedTransferIds = {};

  TransferServer({
    this.customDestinationDirectory,
    required this.onRequestApproval,
    required this.onTransferProgress,
    required this.onTransferCompleted,
    this.onError,
    this.checkStorageSpace,
  });

  /// Cancels an in-flight transfer from the receiver side.
  Future<void> cancel(
    String transferId, {
    String reason = 'Cancelled by receiver',
  }) async {
    _cancelledTransferIds.add(transferId);
    _pausedTransferIds.remove(transferId);

    final existing = _activeTransfers[transferId];
    final cancelledTransfer = (existing != null)
        ? existing.copyWith(
            state: TransferState.cancelled,
            failureReason: reason,
            speedBytesPerSec: 0.0,
            etaSeconds: 0,
            completedAt: DateTime.now(),
          )
        : NexoraTransfer(
            transferId: transferId,
            direction: TransferDirection.receive,
            remoteDeviceId: 'peer',
            remoteDeviceName: 'Peer',
            totalFiles: 1,
            totalBytes: 0,
            bytesTransferred: 0,
            speedBytesPerSec: 0.0,
            etaSeconds: 0,
            currentFile: 'Cancelled',
            state: TransferState.cancelled,
            failureReason: reason,
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );

    try {
      await DatabaseService.instance.updateTransferProgress(
        transferId,
        cancelledTransfer.bytesTransferred,
        TransferState.cancelled,
      );
    } catch (_) {}

    onTransferProgress(cancelledTransfer);
    _activeTransfers.remove(transferId);

    final socket = _activeSockets[transferId];
    if (socket != null) {
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
      await Future.delayed(const Duration(milliseconds: 250));
      try {
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
      _activeSockets.remove(transferId);
    }
  }

  /// Pauses an incoming transfer from the receiver side.
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

  /// Resumes an incoming transfer from the receiver side.
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

  /// Starts the TCP transfer server listening for peer transfers.
  Future<int> start() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    port = _serverSocket!.port;
    _serverSocket!.listen(_handleClientConnection);
    return port;
  }

  void _handleClientConnection(Socket socket) {
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    final buffer = BytesBuilder(copy: false);
    int expectedLength = -1;

    String? activeTransferId;
    String? currentFileName;
    int totalBytes = 0;
    int totalFiles = 1;
    int receivedBytes = 0;
    int lastDbCheckpoint = 0;
    RandomAccessFile? destinationFile;
    String? activeFileId;
    String? currentFilePath;
    final List<String> completedFilePaths = [];
    final Set<String> sessionCreatedPaths = {};
    Directory? activeDownloadDir;
    final Map<String, ManifestItem> manifestFiles = {};
    final Map<String, DigestSink> incomingFileSinks = {};
    final Map<String, ByteConversionSink> incomingFileHashers = {};
    Map<String, String> declaredFileHashes = {};

    DateTime startTime = DateTime.now();
    DateTime lastProgressUpdate = DateTime.now();
    String remoteDeviceName = 'Remote Peer';
    String remoteDevicePlatform = 'Remote';
    String remoteDeviceId = 'peer';

    Future<void> safeCloseFile({bool deleteIncomplete = false}) async {
      final f = destinationFile;
      final path = currentFilePath;
      destinationFile = null;
      if (f != null) {
        try {
          f.flushSync();
          await f.close();
        } catch (_) {}
      }
      if (deleteIncomplete) {
        currentFilePath = null;
        final pathsToDelete = {...sessionCreatedPaths};
        if (path != null) pathsToDelete.add(path);

        for (final p in pathsToDelete) {
          for (int attempt = 0; attempt < 20; attempt++) {
            try {
              final file = File(p);
              if (await file.exists()) {
                await file.delete();
              }
              break;
            } catch (_) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }
        sessionCreatedPaths.clear();
        return;
      }
      if (path != null && !completedFilePaths.contains(path)) {
        completedFilePaths.add(path);
        // Automatically scan into Android MediaStore so Gallery shows images/videos
        unawaited(MediaStoreService.scanFile(path));
      }
    }

    bool isCompleted = false;

    Future<void> completeTransferSession() async {
      if (isCompleted) return;
      isCompleted = true;

      await safeCloseFile();

      // Trigger MediaScanner for all received files to show in Gallery
      for (final path in completedFilePaths) {
        await MediaStoreService.scanFile(path);
      }

      await AndroidForegroundService.stopService();

      // Close streaming hashers and perform zero-memory verification
      for (final hasher in incomingFileHashers.values) {
        try {
          hasher.close();
        } catch (_) {}
      }

      bool allVerified = true;
      for (final entry in incomingFileSinks.entries) {
        final fileId = entry.key;
        final actualSha = entry.value.value?.toString().toLowerCase();
        final expectedSha =
            declaredFileHashes[fileId]?.toLowerCase() ??
            manifestFiles[fileId]?.sha256Hash?.toLowerCase();
        if (expectedSha != null && expectedSha.isNotEmpty) {
          if (actualSha != expectedSha) {
            allVerified = false;
          }
        }
      }

      // Send TransferCompleteAck to sender
      try {
        socket.add(
          encodeFrame({
            'type': 'TransferCompleteAck',
            'payload': {
              'transfer_id': activeTransferId,
              'verified': allVerified,
            },
          }),
        );
        await socket.flush();
      } catch (_) {}

      // Update SQLite state
      try {
        if (activeTransferId != null) {
          await DatabaseService.instance.updateTransferProgress(
            activeTransferId!,
            totalBytes,
            TransferState.completed,
          );
          await DatabaseService.instance.clearResumeCheckpoints(
            activeTransferId!,
          );
        }
      } catch (_) {}

      final completed = NexoraTransfer(
        transferId: activeTransferId ?? 'incoming',
        direction: TransferDirection.receive,
        remoteDeviceId: remoteDeviceId,
        remoteDeviceName: remoteDeviceName,
        remotePlatform: remoteDevicePlatform,
        totalFiles: totalFiles,
        totalBytes: totalBytes,
        bytesTransferred: totalBytes,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: currentFileName ?? 'Files',
        state: TransferState.completed,
        createdAt: startTime,
        completedAt: DateTime.now(),
      );

      onTransferCompleted(completed);

      if (activeTransferId != null) {
        _activeSockets.remove(activeTransferId);
        _activeTransfers.remove(activeTransferId);
      }
      try {
        await socket.flush();
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
    }

    final frameController = StreamController<Map<String, dynamic>>();

    socket.listen(
      (data) {
        buffer.add(data);

        while (true) {
          if (expectedLength == -1) {
            if (buffer.length < lengthPrefixSize) {
              break;
            }
            final prefixBytes = buffer.toBytes().sublist(0, lengthPrefixSize);
            final byteData = ByteData.view(prefixBytes.buffer);
            expectedLength = byteData.getUint32(0, Endian.big);

            if (expectedLength > maxFrameSize) {
              socket.destroy();
              if (!frameController.isClosed) frameController.close();
              return;
            }
          }

          final totalFrameRequired = lengthPrefixSize + expectedLength;
          if (buffer.length < totalFrameRequired) {
            break;
          }

          final allBytes = buffer.takeBytes();
          final payloadBytes = allBytes.sublist(
            lengthPrefixSize,
            totalFrameRequired,
          );

          if (allBytes.length > totalFrameRequired) {
            buffer.add(allBytes.sublist(totalFrameRequired));
          }
          expectedLength = -1;

          try {
            final message = decodeFramePayload(payloadBytes);
            if (!frameController.isClosed) {
              frameController.add(message);
            }
          } catch (e) {
            if (!frameController.isClosed) {
              frameController.addError(e);
            }
          }
        }
      },
      onError: (e) {
        if (!frameController.isClosed) {
          frameController.addError(e);
        }
      },
      onDone: () {
        if (!frameController.isClosed) {
          frameController.close();
        }
      },
    );

    unawaited(() async {
      try {
        await for (final message in frameController.stream) {
          final type = message['type'] as String;
          final payload = message['payload'] as Map<String, dynamic>;

            if (type == 'Hello') {
              final device = payload['device'] as Map<String, dynamic>;
              remoteDeviceName =
                  device['display_name'] as String? ?? 'Remote Device';
              remoteDevicePlatform = device['platform'] as String? ?? 'Remote';
              final reply = encodeFrame({
                'type': 'Hello',
                'payload': {
                  'protocol_version': currentProtocolVersion,
                  'device': {
                    'display_name': 'NEXORA Android',
                    'platform': 'Android',
                  },
                },
              });
              socket.add(reply);
            } else if (type == 'TransferCancel') {
              // Sender cancelled transfer
              final reason =
                  (payload['reason'] as String?) ?? 'Cancelled by sender';
              final cancelTransferId =
                  payload['transfer_id'] as String? ?? activeTransferId;
              if (cancelTransferId != null) {
                _cancelledTransferIds.add(cancelTransferId);
              }
              isCompleted = true;
              await safeCloseFile(deleteIncomplete: true);
              await AndroidForegroundService.stopService();

              // Send TransferCancelAck
              if (cancelTransferId != null) {
                try {
                  socket.add(
                    buildTransferCancelAckFrame(transferId: cancelTransferId),
                  );
                  await socket.flush().timeout(
                    const Duration(milliseconds: 500),
                  );
                } catch (_) {}

                try {
                  await DatabaseService.instance.updateTransferProgress(
                    cancelTransferId,
                    receivedBytes,
                    TransferState.cancelled,
                  );
                } catch (_) {}

                final cancelledTransfer = NexoraTransfer(
                  transferId: cancelTransferId,
                  direction: TransferDirection.receive,
                  remoteDeviceId: remoteDeviceId,
                  remoteDeviceName: remoteDeviceName,
                  remotePlatform: remoteDevicePlatform,
                  totalFiles: totalFiles,
                  totalBytes: totalBytes,
                  bytesTransferred: receivedBytes,
                  speedBytesPerSec: 0.0,
                  etaSeconds: 0,
                  currentFile: currentFileName ?? 'Cancelled',
                  state: TransferState.cancelled,
                  failureReason: reason,
                  createdAt: startTime,
                  completedAt: DateTime.now(),
                );
                onTransferProgress(cancelledTransfer);
                _activeSockets.remove(cancelTransferId);
                _activeTransfers.remove(cancelTransferId);
              }
              try {
                await socket.close();
              } catch (_) {
                socket.destroy();
              }
              return;
            } else if (type == 'TransferPause') {
              if (activeTransferId != null) {
                _pausedTransferIds.add(activeTransferId!);
                final pausedTransfer = NexoraTransfer(
                  transferId: activeTransferId!,
                  direction: TransferDirection.receive,
                  remoteDeviceId: remoteDeviceId,
                  remoteDeviceName: remoteDeviceName,
                  remotePlatform: remoteDevicePlatform,
                  totalFiles: totalFiles,
                  totalBytes: totalBytes,
                  bytesTransferred: receivedBytes,
                  speedBytesPerSec: 0.0,
                  etaSeconds: 0,
                  currentFile: currentFileName ?? 'Paused',
                  state: TransferState.paused,
                  createdAt: startTime,
                );
                _activeTransfers[activeTransferId!] = pausedTransfer;
                onTransferProgress(pausedTransfer);
              }
            } else if (type == 'TransferResume') {
              if (activeTransferId != null) {
                _pausedTransferIds.remove(activeTransferId!);
              }
} else if (type == 'TransferOffer') {
              final manifestMap = payload['manifest'] as Map<String, dynamic>;
              final manifest = TransferManifest.fromJson(manifestMap);

              activeTransferId = payload['transfer_id'] as String;
              _activeSockets[activeTransferId!] = socket;
              _cancelledTransferIds.remove(activeTransferId!);
              _pausedTransferIds.remove(activeTransferId!);

              totalBytes = manifest.totalBytes;
              totalFiles = manifest.totalFiles;

              manifestFiles.clear();
              incomingFileSinks.clear();
              incomingFileHashers.clear();
              declaredFileHashes.clear();
              for (final f in manifest.files) {
                manifestFiles[f.fileId] = f;
              }

              final firstFile = manifest.files.isNotEmpty
                  ? manifest.files.first
                  : null;
              currentFileName = firstFile != null
                  ? (manifest.totalFiles > 1
                        ? '${firstFile.name} (+${manifest.totalFiles - 1} more)'
                        : firstFile.name)
                  : 'received_files';

              final senderMap = payload['sender'] as Map<String, dynamic>?;
              final senderDeviceId = senderMap?['device_id'] as String? ?? 'peer';
              remoteDeviceId = senderDeviceId;

              // IMMEDIATELY notify receiver UI so activeTransfersProvider contains incoming transfer!
              final incomingTransfer = NexoraTransfer(
                transferId: activeTransferId!,
                direction: TransferDirection.receive,
                remoteDeviceId: remoteDeviceId,
                remoteDeviceName: remoteDeviceName,
                remotePlatform: remoteDevicePlatform,
                totalFiles: totalFiles,
                totalBytes: totalBytes,
                bytesTransferred: 0,
                speedBytesPerSec: 0.0,
                etaSeconds: 0,
                currentFile: currentFileName!,
                state: TransferState.awaitingAcceptance,
                createdAt: startTime,
              );
              _activeTransfers[activeTransferId!] = incomingTransfer;
              onTransferProgress(incomingTransfer);
              try {
                await DatabaseService.instance.logTransfer(incomingTransfer);
              } catch (_) {}

              final offer = IncomingTransferOffer(
                transferId: activeTransferId!,
                senderName: remoteDeviceName,
                senderPlatform: remoteDevicePlatform,
                fileName: currentFileName!,
                totalBytes: totalBytes,
                totalFiles: totalFiles,
                declaredSha256: firstFile?.sha256Hash,
                files: manifest.files,
              );

              // Verify target storage has sufficient free capacity
              if (checkStorageSpace != null) {
                final hasSpace = await checkStorageSpace!(totalBytes);
                if (!hasSpace) {
                  socket.add(
                    encodeFrame({
                      'type': 'TransferReject',
                      'payload': {
                        'transfer_id': activeTransferId,
                        'reason': 'Insufficient storage space on receiver device',
                      },
                    }),
                  );
                  isCompleted = true;
                  final failedTransfer = incomingTransfer.copyWith(
                    state: TransferState.failed,
                    failureReason: 'Insufficient storage space on receiver device',
                    completedAt: DateTime.now(),
                  );
                  onTransferProgress(failedTransfer);
                  _activeSockets.remove(activeTransferId);
                  _activeTransfers.remove(activeTransferId);
                  socket.destroy();
                  return;
                }
              }

              final approved = await onRequestApproval(offer);

              // Check if cancelled while dialog was displaying
              if (_cancelledTransferIds.contains(activeTransferId)) {
                return;
              }

              if (approved) {
                if (customDestinationDirectory != null) {
                  activeDownloadDir = customDestinationDirectory!;
                } else {
                  // Resolve public Downloads/Nexora so gallery & file manager immediately see files
                  activeDownloadDir =
                      await MediaStoreService.getDownloadDirectory();
                }

                if (!await activeDownloadDir!.exists()) {
                  try {
                    await activeDownloadDir!.create(recursive: true);
                  } catch (_) {
                    activeDownloadDir = Directory.systemTemp;
                  }
                }

                startTime = DateTime.now();
                lastProgressUpdate = DateTime.now();
                receivedBytes = 0;

                // Start Android foreground service
                await AndroidForegroundService.startService(
                  fileName: currentFileName!,
                  isSending: false,
                );

                // Transition state to inProgress
                final inProgressTransfer = incomingTransfer.copyWith(state: TransferState.inProgress);
                _activeTransfers[activeTransferId!] = inProgressTransfer;
                onTransferProgress(inProgressTransfer);

                socket.add(
                  encodeFrame({
                    'type': 'TransferAccept',
                    'payload': {
                      'transfer_id': activeTransferId,
                      'accepted_file_ids': manifest.files
                          .map((f) => f.fileId)
                          .toList(),
                    },
                  }),
                );
              } else {
                isCompleted = true;
                final rejectedTransfer = incomingTransfer.copyWith(
                  state: TransferState.rejected,
                  failureReason: 'Transfer declined by receiver',
                  completedAt: DateTime.now(),
                );
                onTransferProgress(rejectedTransfer);

                socket.add(
                  encodeFrame({
                    'type': 'TransferReject',
                    'payload': {
                      'transfer_id': activeTransferId,
                      'reason': 'Transfer declined by receiver',
                    },
                  }),
                );
                _activeSockets.remove(activeTransferId);
                _activeTransfers.remove(activeTransferId);
                try {
                  await socket.close();
                } catch (_) {
                  socket.destroy();
                }
                return;
              }
                        } else if (type == 'TransferResume') {
              final reqFileId = payload['file_id'] as String;
              int verifiedOffset = 0;
              try {
                verifiedOffset = await DatabaseService.instance
                    .getHighestVerifiedOffset(activeTransferId!, reqFileId);
              } catch (_) {}

              socket.add(
                encodeFrame({
                  'type': 'TransferResumeAck',
                  'payload': {
                    'transfer_id': activeTransferId,
                    'file_id': reqFileId,
                    'verified_offset': verifiedOffset,
                  },
                }),
              );
            } else if (type == 'ChunkData') {
              if (activeTransferId != null &&
                  _cancelledTransferIds.contains(activeTransferId!)) {
                await safeCloseFile(deleteIncomplete: true);
                socket.destroy();
                return;
              }

              final fileId = payload['file_id'] as String? ?? 'f-0';
              final dynamic rawData = payload['data'];
              final Uint8List chunkBytes = rawData is Uint8List
                  ? rawData
                  : (rawData is String
                        ? base64Decode(rawData)
                        : (rawData is List
                              ? Uint8List.fromList(rawData.cast<int>())
                              : Uint8List(0)));
              final offset = payload['offset'] as int? ?? 0;
              final chunkIndex = payload['chunk_index'] as int? ?? 0;
              final chunkSha256 = payload['chunk_sha256'] as String?;

              if (chunkSha256 != null && chunkSha256.isNotEmpty) {
                final computedHash = sha256.convert(chunkBytes).toString();
                if (computedHash.toLowerCase() != chunkSha256.toLowerCase()) {
                  onError?.call(
                    'CHECKSUM_MISMATCH: Computed $computedHash != Expected $chunkSha256',
                  );
                  socket.destroy();
                  return;
                }
              }

              // Switch active file if chunk belongs to a new file in batch
              if (activeFileId != fileId || destinationFile == null) {
                await safeCloseFile();
                activeFileId = fileId;

                final item = manifestFiles[fileId];
                final fileName = item?.name ?? 'file_$fileId';
                final relativePath = item?.relativePath;

                final targetFile = PathSanitizer.resolveSafePath(
                  destinationBaseDir: activeDownloadDir ?? Directory.systemTemp,
                  filename: fileName,
                  relativePath: relativePath,
                );

                currentFilePath = targetFile.path;
                sessionCreatedPaths.add(targetFile.path);

                if (!await targetFile.parent.exists()) {
                  await targetFile.parent.create(recursive: true);
                }

                destinationFile = await targetFile.open(
                  mode: offset > 0 ? FileMode.append : FileMode.write,
                );
              }

              if (!incomingFileHashers.containsKey(fileId)) {
                final sink = DigestSink();
                incomingFileSinks[fileId] = sink;
                incomingFileHashers[fileId] = sha256.startChunkedConversion(
                  sink,
                );
              }
              incomingFileHashers[fileId]!.add(chunkBytes);

              if (destinationFile != null) {
                destinationFile!.setPositionSync(offset);
                destinationFile!.writeFromSync(chunkBytes);
              }

              receivedBytes += chunkBytes.length;

              // Throttle SQLite writes: checkpoint every 5 MB or on completion
              if (receivedBytes - lastDbCheckpoint >= 5 * 1024 * 1024 ||
                  receivedBytes >= totalBytes) {
                lastDbCheckpoint = receivedBytes;
                try {
                  if (activeTransferId != null) {
                    await DatabaseService.instance.recordVerifiedChunk(
                      transferId: activeTransferId!,
                      fileId: fileId,
                      chunkIndex: chunkIndex,
                      chunkOffset: offset,
                      chunkSize: chunkBytes.length,
                      chunkSha256: chunkSha256 ?? '',
                    );
                  }
                } catch (_) {}
              }

              // Send ChunkAck immediately for sliding window flow control
              socket.add(
                encodeFrame({
                  'type': 'ChunkAck',
                  'payload': {
                    'transfer_id': activeTransferId,
                    'file_id': fileId,
                    'chunk_index': chunkIndex,
                    'received_bytes': chunkBytes.length,
                    'verified': true,
                  },
                }),
              );

              final now = DateTime.now();
              if (now.difference(lastProgressUpdate).inMilliseconds >= 200 ||
                  receivedBytes >= totalBytes) {
                lastProgressUpdate = now;
                final elapsedSeconds =
                    now.difference(startTime).inMilliseconds / 1000.0;
                final speedBps = elapsedSeconds > 0
                    ? (receivedBytes / elapsedSeconds)
                    : 0.0;
                final remainingBytes = (totalBytes - receivedBytes).clamp(
                  0,
                  totalBytes,
                );
                final eta = speedBps > 0
                    ? (remainingBytes / speedBps).round()
                    : 0;

                final pct = totalBytes > 0
                    ? ((receivedBytes / totalBytes) * 100).round()
                    : 0;
                final speedStr = speedBps >= 1024 * 1024
                    ? '${(speedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s'
                    : '${(speedBps / 1024).toStringAsFixed(1)} KB/s';

                await AndroidForegroundService.updateProgress(
                  fileName:
                      manifestFiles[fileId]?.name ?? currentFileName ?? 'File',
                  progressPercent: pct,
                  speed: speedStr,
                );

                final currentTransfer = NexoraTransfer(
                  transferId: activeTransferId ?? 'incoming',
                  direction: TransferDirection.receive,
                  remoteDeviceId: remoteDeviceId,
                  remoteDeviceName: remoteDeviceName,
                  remotePlatform: remoteDevicePlatform,
                  totalFiles: totalFiles,
                  totalBytes: totalBytes,
                  bytesTransferred: receivedBytes,
                  speedBytesPerSec: speedBps,
                  etaSeconds: eta,
                  currentFile:
                      manifestFiles[fileId]?.name ?? currentFileName ?? 'File',
                  state: TransferState.inProgress,
                  createdAt: startTime,
                );

                _activeTransfers[activeTransferId ?? 'incoming'] = currentTransfer;
                onTransferProgress(currentTransfer);
              }
            } else if (type == 'TransferComplete') {
              final incomingHashes =
                  (payload['file_hashes'] as Map<String, dynamic>?)
                      ?.cast<String, String>() ??
                  {};
              declaredFileHashes = incomingHashes;
              await completeTransferSession();
          }
        }

        if (isCompleted) return;
        if (receivedBytes >= totalBytes &&
            totalBytes > 0 &&
            (activeTransferId == null ||
                !_cancelledTransferIds.contains(activeTransferId))) {
          await completeTransferSession();
        } else {
          await safeCloseFile(deleteIncomplete: true);
          if (activeTransferId != null &&
              !_cancelledTransferIds.contains(activeTransferId)) {
            final interrupted = NexoraTransfer(
              transferId: activeTransferId!,
              direction: TransferDirection.receive,
              remoteDeviceId: remoteDeviceId,
              remoteDeviceName: remoteDeviceName,
              remotePlatform: remoteDevicePlatform,
              totalFiles: totalFiles,
              totalBytes: totalBytes,
              bytesTransferred: receivedBytes,
              speedBytesPerSec: 0.0,
              etaSeconds: 0,
              currentFile: currentFileName ?? 'Interrupted',
              state: TransferState.interrupted,
              failureReason: 'Connection closed unexpectedly',
              createdAt: startTime,
              completedAt: DateTime.now(),
            );
            onTransferProgress(interrupted);
            _activeSockets.remove(activeTransferId);
            _activeTransfers.remove(activeTransferId);
          }
          await AndroidForegroundService.stopService();
        }
      } catch (e) {
        if (isCompleted) return;
        if (receivedBytes >= totalBytes &&
            totalBytes > 0 &&
            (activeTransferId == null ||
                !_cancelledTransferIds.contains(activeTransferId))) {
          await completeTransferSession();
        } else {
          await safeCloseFile(deleteIncomplete: true);
          if (activeTransferId != null &&
              !_cancelledTransferIds.contains(activeTransferId) &&
              !isCompleted) {
            final failed = NexoraTransfer(
              transferId: activeTransferId!,
              direction: TransferDirection.receive,
              remoteDeviceId: remoteDeviceId,
              remoteDeviceName: remoteDeviceName,
              remotePlatform: remoteDevicePlatform,
              totalFiles: totalFiles,
              totalBytes: totalBytes,
              bytesTransferred: receivedBytes,
              speedBytesPerSec: 0.0,
              etaSeconds: 0,
              currentFile: currentFileName ?? 'Failed',
              state: TransferState.failed,
              failureReason: 'Stream error: $e',
              createdAt: startTime,
              completedAt: DateTime.now(),
            );
            onTransferProgress(failed);
            _activeSockets.remove(activeTransferId);
            _activeTransfers.remove(activeTransferId);
          }
          await AndroidForegroundService.stopService();
        }
        try {
          socket.destroy();
        } catch (_) {}
      }
    }());
  }

  void stop() {
    _serverSocket?.close();
    _serverSocket = null;
    for (final s in _activeSockets.values) {
      try {
        s.destroy();
      } catch (_) {}
    }
    _activeSockets.clear();
    _activeTransfers.clear();
  }
}
