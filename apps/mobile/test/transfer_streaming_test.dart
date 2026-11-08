import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/models/transfer_model.dart';
import 'package:nexora_app/network/file_transfer_manifest.dart';
import 'package:nexora_app/network/transfer_client.dart';
import 'package:nexora_app/network/transfer_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Real TCP single-file transfer with streaming chunks and SHA-256 verification',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nexora_transfer_test_',
      );

      // Create a 64 KB test file with non-trivial byte patterns
      final sourceFile = File('${tempDir.path}/test_image.png');
      final fileBytes = Uint8List(64 * 1024);
      for (int i = 0; i < fileBytes.length; i++) {
        fileBytes[i] = (i * 37) % 256;
      }
      await sourceFile.writeAsBytes(fileBytes);


      final serverCompleter = Completer<NexoraTransfer>();
      final clientCompleter = Completer<NexoraTransfer>();

      // 1. Start real TransferServer on loopback
      final server = TransferServer(
        customDestinationDirectory: tempDir,
        onRequestApproval: (offer) async {
          expect(offer.fileName, 'test_image.png');
          expect(offer.totalBytes, fileBytes.length);
          return true; // Explicitly approved by receiver
        },
        onTransferProgress: (progress) {
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
      final serverResult = await serverCompleter.future.timeout(
        const Duration(seconds: 10),
      );
      final clientResult = await clientCompleter.future.timeout(
        const Duration(seconds: 10),
      );

      expect(serverResult.state, TransferState.completed);
      expect(clientResult.state, TransferState.completed);
      expect(serverResult.bytesTransferred, fileBytes.length);
      expect(clientResult.bytesTransferred, fileBytes.length);

      server.stop();
      await tempDir.delete(recursive: true);
    },
  );

  test(
    'TransferClient and TransferServer cancellation cleans up active state',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nexora_cancel_test_',
      );

      final sourceFile = File('${tempDir.path}/large_test_file.bin');
      final fileBytes = Uint8List(512 * 1024);
      await sourceFile.writeAsBytes(fileBytes);

      final cancelCompleter = Completer<void>();

      final server = TransferServer(
        customDestinationDirectory: tempDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (progress) {
          if (progress.state == TransferState.cancelled) {
            if (!cancelCompleter.isCompleted) cancelCompleter.complete();
          }
        },
        onTransferCompleted: (_) {},
      );

      final port = await server.start();

      final targetPeer = NexoraDevice(
        deviceId: 'server-device-cancel',
        displayName: 'Receiver Device',
        platform: 'Android',
        fingerprint: 'dummyfingerprint',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final localSender = NexoraDevice(
        deviceId: 'sender-device-cancel',
        displayName: 'Sender Device',
        platform: 'Android',
        fingerprint: 'dummyfingerprint2',
        lastSeen: DateTime.now(),
      );

      late final TransferClient client;
      client = TransferClient(
        onProgress: (progress) {
          if (progress.bytesTransferred > 0) {
            // Cancel while in flight
            client.cancel(progress.transferId);
            if (!cancelCompleter.isCompleted) cancelCompleter.complete();
          }
        },
        onCompleted: (_) {},
        onError: (_) {
          if (!cancelCompleter.isCompleted) cancelCompleter.complete();
        },
      );

      final manifest = await TransferManifest.fromFiles([sourceFile]);

      // Fire in background and cancel
      unawaited(
        client.sendManifest(
          peer: targetPeer,
          manifest: manifest,
          localDevice: localSender,
        ),
      );

      await cancelCompleter.future.timeout(const Duration(seconds: 10));

      expect(client.isCancelled(manifest.transferId), isTrue);

      server.stop();
      await tempDir.delete(recursive: true);
    },
  );

  test(
    'ISSUE 2 Regression: 18.3 KB transfer transitions to Completed with TransferCompleteAck & zero speed/eta',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nexora_18kb_test_',
      );

      // Create exact 18.3 KB (18,739 bytes) file
      final sourceFile = File('${tempDir.path}/screenshot_doc.pdf');
      final fileBytes = Uint8List(18739);
      for (int i = 0; i < fileBytes.length; i++) {
        fileBytes[i] = (i * 73) % 256;
      }
      await sourceFile.writeAsBytes(fileBytes);
      final expectedSha = sha256.convert(fileBytes).toString();

      final serverCompleter = Completer<NexoraTransfer>();
      final clientCompleter = Completer<NexoraTransfer>();

      final server = TransferServer(
        customDestinationDirectory: tempDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (progress) {},
        onTransferCompleted: (completed) {
          serverCompleter.complete(completed);
        },
      );

      final port = await server.start();

      final targetPeer = NexoraDevice(
        deviceId: 'server-18kb',
        displayName: 'Android Receiver',
        platform: 'Android',
        fingerprint: 'fp-18kb',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final localSender = NexoraDevice(
        deviceId: 'sender-18kb',
        displayName: 'Windows Sender',
        platform: 'Windows',
        fingerprint: 'fp-sender-18kb',
        lastSeen: DateTime.now(),
      );

      final client = TransferClient(
        onProgress: (p) {},
        onCompleted: (c) {
          clientCompleter.complete(c);
        },
        onError: (err) => fail('Unexpected error: $err'),
      );

      await client.sendFile(
        peer: targetPeer,
        file: sourceFile,
        localDevice: localSender,
      );

      final serverResult = await serverCompleter.future.timeout(
        const Duration(seconds: 10),
      );
      final clientResult = await clientCompleter.future.timeout(
        const Duration(seconds: 10),
      );

      // Verify server completion attributes
      expect(serverResult.state, TransferState.completed);
      expect(serverResult.bytesTransferred, 18739);
      expect(serverResult.totalBytes, 18739);
      expect(serverResult.speedBytesPerSec, 0.0);
      expect(serverResult.etaSeconds, 0);

      // Verify client completion attributes
      expect(clientResult.state, TransferState.completed);
      expect(clientResult.bytesTransferred, 18739);
      expect(clientResult.totalBytes, 18739);
      expect(clientResult.speedBytesPerSec, 0.0);
      expect(clientResult.etaSeconds, 0);

      // Verify received file on disk
      final receivedFile = File('${tempDir.path}/screenshot_doc.pdf');
      expect(await receivedFile.exists(), isTrue);
      final receivedBytes = await receivedFile.readAsBytes();
      expect(receivedBytes.length, 18739);
      expect(sha256.convert(receivedBytes).toString(), expectedSha);

      server.stop();
      await tempDir.delete(recursive: true);
    },
  );
}
