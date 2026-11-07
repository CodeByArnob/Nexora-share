import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transfer_model.dart';
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

          final allBytes = buffer.takeBytes();
          final payloadBytes = allBytes.sublist(lengthPrefixSize, totalFrameRequired);

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
              final reply = encodeFrame({
                'type': 'Hello',
                'payload': {
                  'protocol_version': currentProtocolVersion,
                  'device': {'display_name': 'NEXORA Windows', 'platform': 'Windows'}
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

              final approved = await onRequestApproval(offer);

              if (approved) {
                Directory downloadDir;
                if (customDestinationDirectory != null) {
                  downloadDir = customDestinationDirectory!;
                } else {
                  final userProfile = Platform.environment['USERPROFILE'];
                  if (userProfile != null) {
                    downloadDir = Directory('$userProfile\\Downloads\\NEXORA');
                  } else {
                    try {
                      downloadDir = await getApplicationDocumentsDirectory();
                    } catch (_) {
                      downloadDir = Directory.systemTemp;
                    }
                  }
                }

                if (!await downloadDir.exists()) {
                  try {
                    await downloadDir.create(recursive: true);
                  } catch (_) {
                    downloadDir = Directory.systemTemp;
                  }
                }

                final sanitizedName = currentFileName!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                final targetPath = '${downloadDir.path}${Platform.pathSeparator}$sanitizedName';
                final file = File(targetPath);
                destinationFile = await file.open(mode: FileMode.write);

                startTime = DateTime.now();
                lastProgressUpdate = DateTime.now();
                receivedBytes = 0;

                socket.add(encodeFrame({
                  'type': 'TransferAccept',
                  'payload': {
                    'transfer_id': activeTransferId,
                    'accepted_file_ids': files.map((f) => f['file_id']).toList(),
                  }
                }));
              } else {
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

              if (chunkSha256 != null && chunkSha256.isNotEmpty) {
                final computedHash = sha256.convert(chunkBytes).toString();
                if (computedHash.toLowerCase() != chunkSha256.toLowerCase()) {
                  socket.destroy();
                  return;
                }
              }

              if (destinationFile != null) {
                destinationFile!.setPositionSync(offset);
                destinationFile!.writeFromSync(chunkBytes);
              }

              receivedBytes += chunkBytes.length;

              socket.add(encodeFrame({
                'type': 'ChunkAck',
                'payload': {
                  'transfer_id': activeTransferId,
                  'file_id': payload['file_id'],
                  'chunk_index': payload['chunk_index'],
                  'verified': true,
                }
              }));

              final now = DateTime.now();
              if (now.difference(lastProgressUpdate).inMilliseconds >= 250 || receivedBytes >= totalBytes) {
                lastProgressUpdate = now;
                final elapsedSeconds = now.difference(startTime).inMilliseconds / 1000.0;
                final speedBps = elapsedSeconds > 0 ? (receivedBytes / elapsedSeconds) : 0.0;
                final remainingBytes = (totalBytes - receivedBytes).clamp(0, totalBytes);
                final eta = speedBps > 0 ? (remainingBytes / speedBps).round() : 0;

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
              }
            } else if (type == 'TransferComplete') {
              await safeCloseFile();

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
          } catch (_) {
            socket.destroy();
          }
        }
      },
      onDone: () async {
        await safeCloseFile();
      },
      onError: (_) async {
        await safeCloseFile();
      },
    );
  }

  void stop() {
    _serverSocket?.close();
    _serverSocket = null;
  }
}
