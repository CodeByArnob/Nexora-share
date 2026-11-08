import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_service.dart';
import '../models/transfer_model.dart';
import 'file_transfer_manifest.dart';
import 'protocol_messages.dart';

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

  TransferServer({
    this.port = 48842,
    this.customDestinationDirectory,
    required this.onRequestApproval,
    required this.onTransferProgress,
    required this.onTransferCompleted,
    this.onError,
  });

  /// Starts the TCP transfer server listening for peer transfers.
  Future<int> start() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    port = _serverSocket!.port;
    _serverSocket!.listen(
      _handleClientConnection,
      onError: (Object error, StackTrace stackTrace) {
        // Listener-level socket errors must not escape as uncaught async failures.
        onError?.call('Transfer listener error: $error');
      },
      cancelOnError: false,
    );
    return port;
  }

  void _handleClientConnection(Socket socket) {
    final buffer = BytesBuilder(copy: false);
    int expectedLength = -1;

    String? activeTransferId;
    String? currentFileName;
    int totalBytes = 0;
    int totalFiles = 1;
    int receivedBytes = 0;
    RandomAccessFile? destinationFile;
    String? activeFileId;
    Directory? activeDownloadDir;
    final Map<String, ManifestItem> manifestFiles = {};

    DateTime startTime = DateTime.now();
    DateTime lastProgressUpdate = DateTime.now();
    String remoteDeviceName = 'Remote Peer';
    String remoteDevicePlatform = 'Remote';

    Future<void> safeCloseFile() async {
      final f = destinationFile;
      destinationFile = null;
      if (f != null) {
        try {
          f.flushSync();
          await f.close();
        } catch (_) {}
      }
    }

    bool isCompleted = false;

    Future<void> completeTransferSession() async {
      if (isCompleted) return;
      isCompleted = true;

      await safeCloseFile();

      // Full-file SHA-256 verification
      bool allVerified = true;
      for (final entry in manifestFiles.entries) {
        final item = entry.value;
        final targetFile = PathSanitizer.resolveSafePath(
          destinationBaseDir: activeDownloadDir ?? Directory.systemTemp,
          filename: item.name,
          relativePath: item.relativePath,
        );
        if (await targetFile.exists() &&
            item.sha256Hash != null &&
            item.sha256Hash!.isNotEmpty) {
          try {
            final fileBytes = await targetFile.readAsBytes();
            final actualSha = sha256.convert(fileBytes).toString();
            if (actualSha.toLowerCase() != item.sha256Hash!.toLowerCase()) {
              allVerified = false;
            }
          } catch (_) {}
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
        remoteDeviceId: 'peer',
        remoteDeviceName: remoteDeviceName,
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

      try {
        await socket.flush();
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
    }

    socket.listen(
      (data) async {
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
            final type = message['type'] as String;
            final payload = message['payload'] as Map<String, dynamic>;

            if (type == 'Hello') {
              final device = payload['device'] as Map<String, dynamic>;
              remoteDeviceName =
                  device['display_name'] as String? ?? 'Remote Device';
              remoteDevicePlatform = device['platform'] as String? ?? 'Remote';
              final currentPlatform = Platform.isLinux
                  ? 'Linux'
                  : Platform.isWindows
                  ? 'Windows'
                  : Platform.isMacOS
                  ? 'macOS'
                  : 'Desktop';
              final reply = encodeFrame({
                'type': 'Hello',
                'payload': {
                  'protocol_version': currentProtocolVersion,
                  'device': {
                    'display_name': 'NEXORA $currentPlatform',
                    'platform': currentPlatform,
                  },
                },
              });
              socket.add(reply);
            } else if (type == 'TransferOffer') {
              final manifestMap = payload['manifest'] as Map<String, dynamic>;
              final manifest = TransferManifest.fromJson(manifestMap);

              activeTransferId = payload['transfer_id'] as String;
              totalBytes = manifest.totalBytes;
              totalFiles = manifest.totalFiles;

              manifestFiles.clear();
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

              final approved = await onRequestApproval(offer);

              if (approved) {
                if (customDestinationDirectory != null) {
                  activeDownloadDir = customDestinationDirectory!;
                } else {
                  final userProfile = Platform.environment['USERPROFILE'];
                  final homeDir = Platform.environment['HOME'];
                  if (Platform.isWindows && userProfile != null) {
                    activeDownloadDir = Directory(
                      '$userProfile\\Downloads\\NEXORA',
                    );
                  } else if (homeDir != null) {
                    activeDownloadDir = Directory('$homeDir/Downloads/NEXORA');
                  } else {
                    try {
                      activeDownloadDir =
                          await getApplicationDocumentsDirectory();
                    } catch (_) {
                      activeDownloadDir = Directory.systemTemp;
                    }
                  }
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

                // Log in SQLite database
                try {
                  await DatabaseService.instance.logTransfer(
                    NexoraTransfer(
                      transferId: activeTransferId!,
                      direction: TransferDirection.receive,
                      remoteDeviceId: 'peer',
                      remoteDeviceName: remoteDeviceName,
                      totalFiles: totalFiles,
                      totalBytes: totalBytes,
                      currentFile: currentFileName!,
                      state: TransferState.inProgress,
                      createdAt: startTime,
                    ),
                  );
                } catch (_) {}

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
                socket.add(
                  encodeFrame({
                    'type': 'TransferReject',
                    'payload': {
                      'transfer_id': activeTransferId,
                      'reason': 'Transfer declined by receiver',
                    },
                  }),
                );
                socket.destroy();
                return;
              }
            } else if (type == 'TransferResume') {
              // Sender requests resume verification offset
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
              // No payload is accepted until a transfer offer has been approved
              // and a destination directory has been established.
              if (activeTransferId == null || activeDownloadDir == null) {
                socket.destroy();
                return;
              }

              final fileId = payload['file_id'] as String? ?? 'f-0';
              final dynamic rawData = payload['data'];
              final Uint8List chunkBytes = rawData is String
                  ? base64Decode(rawData)
                  : (rawData is List
                        ? Uint8List.fromList(rawData.cast<int>())
                        : Uint8List(0));
              final offset = payload['offset'] as int? ?? 0;
              final chunkIndex = payload['chunk_index'] as int? ?? 0;
              final chunkSha256 = payload['chunk_sha256'] as String?;

              // Validate chunk integrity
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

                if (!await targetFile.parent.exists()) {
                  await targetFile.parent.create(recursive: true);
                }

                destinationFile = await targetFile.open(
                  mode: offset > 0 ? FileMode.append : FileMode.write,
                );
              }

              if (destinationFile != null) {
                destinationFile!.setPositionSync(offset);
                destinationFile!.writeFromSync(chunkBytes);
              }

              receivedBytes += chunkBytes.length;

              // Record verified checkpoint in SQLite
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
              if (now.difference(lastProgressUpdate).inMilliseconds >= 250 ||
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

                final currentTransfer = NexoraTransfer(
                  transferId: activeTransferId ?? 'incoming',
                  direction: TransferDirection.receive,
                  remoteDeviceId: 'peer',
                  remoteDeviceName: remoteDeviceName,
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

                onTransferProgress(currentTransfer);
              }
            } else if (type == 'TransferComplete') {
              await completeTransferSession();
            }
          } catch (_) {
            socket.destroy();
          }
        }
      },
      onDone: () async {
        if (!isCompleted && receivedBytes >= totalBytes && totalBytes > 0) {
          await completeTransferSession();
        } else {
          await safeCloseFile();
        }
      },
      onError: (_) async {
        if (!isCompleted && receivedBytes >= totalBytes && totalBytes > 0) {
          await completeTransferSession();
        } else {
          await safeCloseFile();
        }
      },
    );
  }

  void stop() {
    _serverSocket?.close();
    _serverSocket = null;
  }
}
