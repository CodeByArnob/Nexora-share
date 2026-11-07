import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transfer_model.dart';
import '../services/android_foreground_service.dart';
import 'protocol_messages.dart';

class IncomingTransferOffer {
  final String transferId;
  final String senderName;
  final String senderPlatform;
  final String fileName;
  final int totalBytes;
  final int totalFiles;
  final String? declaredSha256;

  IncomingTransferOffer({
    required this.transferId,
    required this.senderName,
    required this.senderPlatform,
    required this.fileName,
    required this.totalBytes,
    required this.totalFiles,
    this.declaredSha256,
  });
}

class TransferServer {
  ServerSocket? _serverSocket;
  int port = 48842;

  final Directory? customDestinationDirectory;
  final Future<bool> Function(IncomingTransferOffer offer) onRequestApproval;
  final void Function(NexoraTransfer transfer) onTransferProgress;
  final void Function(NexoraTransfer completedTransfer) onTransferCompleted;

  TransferServer({
    this.customDestinationDirectory,
    required this.onRequestApproval,
    required this.onTransferProgress,
    required this.onTransferCompleted,
  });

  /// Starts the TCP transfer server listening for peer transfers.
  Future<int> start() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      // Fallback to random free port if default port is in use
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    port = _serverSocket!.port;
    _serverSocket!.listen(_handleClientConnection);
    return port;
  }

  void _handleClientConnection(Socket socket) {
    final buffer = BytesBuilder(copy: false);
    int expectedLength = -1;

    String? activeTransferId;
    String? currentFileName;
    int totalBytes = 0;
    int receivedBytes = 0;
    RandomAccessFile? destinationFile;
    DateTime startTime = DateTime.now();
    DateTime lastProgressUpdate = DateTime.now();
    String? expectedFileSha256;
    String remoteDeviceName = 'Remote Peer';

    Future<void> safeCloseFile() async {
      final f = destinationFile;
      destinationFile = null;
      if (f != null) {
        try {
          await f.close();
        } catch (_) {}
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

          // Full frame ready
          final allBytes = buffer.takeBytes();
          final payloadBytes = allBytes.sublist(lengthPrefixSize, totalFrameRequired);

          // Retain remainder
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
              remoteDeviceName = device['display_name'] as String? ?? 'Remote Device';
              // Reply with Hello
              final reply = encodeFrame({
                'type': 'Hello',
                'payload': {
                  'protocol_version': currentProtocolVersion,
                  'device': {'display_name': 'NEXORA Android', 'platform': 'Android'}
                }
              });
              socket.add(reply);
            } else if (type == 'TransferOffer') {
              final manifest = payload['manifest'] as Map<String, dynamic>;
              final files = (manifest['files'] as List).cast<Map<String, dynamic>>();
              final firstFile = files.isNotEmpty ? files.first : <String, dynamic>{};

              activeTransferId = payload['transfer_id'] as String;
              currentFileName = firstFile['name'] as String? ?? 'received_file';
              totalBytes = manifest['total_bytes'] as int? ?? 0;
              expectedFileSha256 = firstFile['sha256_hash'] as String?;

              final offer = IncomingTransferOffer(
                transferId: activeTransferId!,
                senderName: remoteDeviceName,
                senderPlatform: 'Remote',
                fileName: currentFileName!,
                totalBytes: totalBytes,
                totalFiles: manifest['total_files'] as int? ?? 1,
                declaredSha256: expectedFileSha256,
              );

              // Prompt receiver for explicit approval
              final approved = await onRequestApproval(offer);

              if (approved) {
                // Prepare destination download path
                Directory downloadDir;
                if (customDestinationDirectory != null) {
                  downloadDir = customDestinationDirectory!;
                } else if (Platform.isAndroid) {
                  downloadDir = Directory('/storage/emulated/0/Download/NEXORA');
                  if (!await downloadDir.exists()) {
                    try {
                      await downloadDir.create(recursive: true);
                    } catch (_) {
                      try {
                        downloadDir = await getApplicationDocumentsDirectory();
                      } catch (_) {
                        downloadDir = Directory.systemTemp;
                      }
                    }
                  }
                } else {
                  try {
                    downloadDir = await getApplicationDocumentsDirectory();
                  } catch (_) {
                    downloadDir = Directory.systemTemp;
                  }
                }

                final sanitizedName = currentFileName!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                final targetPath = '${downloadDir.path}/$sanitizedName';
                final file = File(targetPath);
                destinationFile = await file.open(mode: FileMode.write);

                startTime = DateTime.now();
                lastProgressUpdate = DateTime.now();
                receivedBytes = 0;

                // Start Android Foreground Service notification
                await AndroidForegroundService.startService(
                  fileName: sanitizedName,
                  isSending: false,
                );

                // Send TransferAccept frame
                socket.add(encodeFrame({
                  'type': 'TransferAccept',
                  'payload': {
                    'transfer_id': activeTransferId,
                    'accepted_file_ids': files.map((f) => f['file_id']).toList(),
                  }
                }));
              } else {
                // Send TransferReject frame
                socket.add(encodeFrame({
                  'type': 'TransferReject',
                  'payload': {
                    'transfer_id': activeTransferId,
                    'reason': 'Transfer declined by receiver',
                  }
                }));
                socket.destroy();
                return;
              }
            } else if (type == 'ChunkData') {
              final chunkDataList = (payload['data'] as List).cast<int>();
              final chunkBytes = Uint8List.fromList(chunkDataList);
              final offset = payload['offset'] as int? ?? 0;
              final chunkSha256 = payload['chunk_sha256'] as String?;

              // Verify chunk SHA-256
              if (chunkSha256 != null && chunkSha256.isNotEmpty) {
                final computedHash = sha256.convert(chunkBytes).toString();
                if (computedHash.toLowerCase() != chunkSha256.toLowerCase()) {
                  // Integrity check failed
                  socket.destroy();
                  return;
                }
              }

              // Write chunk to disk
              if (destinationFile != null) {
                destinationFile!.setPositionSync(offset);
                destinationFile!.writeFromSync(chunkBytes);
              }

              receivedBytes += chunkBytes.length;

              // Send ChunkAck
              socket.add(encodeFrame({
                'type': 'ChunkAck',
                'payload': {
                  'transfer_id': activeTransferId,
                  'file_id': payload['file_id'],
                  'chunk_index': payload['chunk_index'],
                  'verified': true,
                }
              }));

              // Progress calculation & notification throttling
              final now = DateTime.now();
              if (now.difference(lastProgressUpdate).inMilliseconds >= 300 || receivedBytes >= totalBytes) {
                lastProgressUpdate = now;
                final elapsedSeconds = now.difference(startTime).inMilliseconds / 1000.0;
                final speedBps = elapsedSeconds > 0 ? (receivedBytes / elapsedSeconds) : 0.0;
                final remainingBytes = (totalBytes - receivedBytes).clamp(0, totalBytes);
                final eta = speedBps > 0 ? (remainingBytes / speedBps).round() : 0;
                final percent = totalBytes > 0 ? ((receivedBytes / totalBytes) * 100).round() : 100;

                final currentTransfer = NexoraTransfer(
                  transferId: activeTransferId ?? 'incoming',
                  direction: TransferDirection.receive,
                  remoteDeviceId: 'peer',
                  remoteDeviceName: remoteDeviceName,
                  totalFiles: 1,
                  totalBytes: totalBytes,
                  bytesTransferred: receivedBytes,
                  speedBytesPerSec: speedBps,
                  etaSeconds: eta,
                  currentFile: currentFileName ?? 'File',
                  state: TransferState.inProgress,
                  createdAt: startTime,
                );

                onTransferProgress(currentTransfer);

                await AndroidForegroundService.updateProgress(
                  fileName: currentFileName ?? 'File',
                  progressPercent: percent,
                  speed: currentTransfer.formattedSpeed,
                );
              }
            } else if (type == 'TransferComplete') {
              await safeCloseFile();

              await AndroidForegroundService.stopService();

              final completed = NexoraTransfer(
                transferId: activeTransferId ?? 'incoming',
                direction: TransferDirection.receive,
                remoteDeviceId: 'peer',
                remoteDeviceName: remoteDeviceName,
                totalFiles: 1,
                totalBytes: totalBytes,
                bytesTransferred: totalBytes,
                speedBytesPerSec: 0.0,
                etaSeconds: 0,
                currentFile: currentFileName ?? 'File',
                state: TransferState.completed,
                createdAt: startTime,
                completedAt: DateTime.now(),
              );

              onTransferCompleted(completed);
              socket.destroy();
            }
          } catch (e, st) {
            // print error for test visibility
            stderr.writeln('Server error processing frame: $e\n$st');
            socket.destroy();
          }
        }
      },
      onDone: () async {
        await safeCloseFile();
        await AndroidForegroundService.stopService();
      },
      onError: (_) async {
        await safeCloseFile();
        await AndroidForegroundService.stopService();
      },
    );
  }

  void stop() {
    _serverSocket?.close();
    _serverSocket = null;
  }
}
