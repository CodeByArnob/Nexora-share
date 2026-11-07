import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/models/transfer_model.dart';
import 'package:nexora_app/network/transfer_client.dart';
import 'package:nexora_app/network/transfer_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Real TCP single-file transfer with streaming chunks and SHA-256 verification', () async {
    final tempDir = await Directory.systemTemp.createTemp('nexora_transfer_test_');

    // Create a 64 KB test file with non-trivial byte patterns
    final sourceFile = File('${tempDir.path}/test_image.png');
    final fileBytes = Uint8List(64 * 1024);
    for (int i = 0; i < fileBytes.length; i++) {
      fileBytes[i] = (i * 37) % 256;
    }
    await sourceFile.writeAsBytes(fileBytes);

    final expectedHash = sha256.convert(fileBytes).toString();

    final serverCompleter = Completer<NexoraTransfer>();
    final clientCompleter = Completer<NexoraTransfer>();

    // 1. Start real TransferServer on loopback
    final server = TransferServer(
      customDestinationDirectory: tempDir,
      onRequestApproval: (offer) async {
        expect(offer.fileName, 'test_image.png');
        expect(offer.totalBytes, fileBytes.length);
        expect(offer.declaredSha256, expectedHash);
        return true; // Explicitly approved by receiver
      },
      onTransferProgress: (progress) {
        // Real-time progress updates
        expect(progress.bytesTransferred, greaterThan(0));
      },
      onTransferCompleted: (completed) {
        serverCompleter.complete(completed);
      },
    );

    final port = await server.start();
    expect(port, greaterThan(0));

    final targetPeer = NexoraDevice(
      deviceId: 'server-device',
      displayName: 'Receiver Device',
      platform: 'Android',
      fingerprint: 'dummyfingerprint',
      address: '127.0.0.1',
      port: port,
      lastSeen: DateTime.now(),
    );

    final localSender = NexoraDevice(
      deviceId: 'sender-device',
      displayName: 'Sender Device',
      platform: 'Android',
      fingerprint: 'dummyfingerprint2',
      lastSeen: DateTime.now(),
    );

    // 2. Start TransferClient and stream file
    final client = TransferClient(
      onProgress: (progress) {
        expect(progress.state, TransferState.inProgress);
      },
      onCompleted: (completed) {
        clientCompleter.complete(completed);
      },
      onError: (err) {
        fail('Client encountered unexpected error: $err');
      },
    );

    await client.sendFile(
      peer: targetPeer,
      file: sourceFile,
      localDevice: localSender,
    );

    // Await completion from both sides
    final serverResult = await serverCompleter.future.timeout(const Duration(seconds: 10));
    final clientResult = await clientCompleter.future.timeout(const Duration(seconds: 10));

    expect(serverResult.state, TransferState.completed);
    expect(clientResult.state, TransferState.completed);
    expect(serverResult.bytesTransferred, fileBytes.length);
    expect(clientResult.bytesTransferred, fileBytes.length);

    server.stop();
    await tempDir.delete(recursive: true);
  });
}
