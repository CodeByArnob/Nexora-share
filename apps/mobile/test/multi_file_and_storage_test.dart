import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/database/database_service.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/models/transfer_model.dart';
import 'package:nexora_app/network/transfer_client.dart';
import 'package:nexora_app/network/transfer_server.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_mobile_phase4_');
    await DatabaseService.instance.initialize(inMemory: true);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Mobile SQLite: Persists device trust and transfer history', () async {
    final db = DatabaseService.instance;
    final device = NexoraDevice(
      deviceId: 'mobile-peer-1',
      displayName: 'Windows Workstation',
      platform: 'Windows',
      fingerprint:
          '14243b3978f639c6b00d142017243af5f7fb00112233445566778899aabbccdd',
      lastSeen: DateTime.now(),
    );

    await db.upsertDevice(device, isTrusted: true);
    final trusted = await db.getTrustedDevices();
    expect(trusted.length, equals(1));
    expect(trusted.first.displayName, equals('Windows Workstation'));

    final transfer = NexoraTransfer(
      transferId: 't-mobile-1',
      direction: TransferDirection.receive,
      remoteDeviceId: 'mobile-peer-1',
      remoteDeviceName: 'Windows Workstation',
      totalFiles: 2,
      totalBytes: 2048,
      bytesTransferred: 2048,
      state: TransferState.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await db.logTransfer(transfer);
    final history = await db.getTransferHistory();
    expect(history.length, equals(1));
    expect(history.first.transferId, equals('t-mobile-1'));
  });

  test(
    'Mobile Multi-file batch transfer: streams 2 files with verified integrity',
    () async {
      final srcDir = Directory('${tempDir.path}${Platform.pathSeparator}src');
      await srcDir.create();

      final f1 = File('${srcDir.path}${Platform.pathSeparator}photo1.jpg');
      final p1Data = utf8.encode('PHOTO_1_BYTES_DATA_STREAM_TEST');
      await f1.writeAsBytes(p1Data);
      final f1Hash = sha256.convert(p1Data).toString();

      final f2 = File('${srcDir.path}${Platform.pathSeparator}photo2.jpg');
      final p2Data = utf8.encode('PHOTO_2_BYTES_DATA_STREAM_TEST');
      await f2.writeAsBytes(p2Data);
      final f2Hash = sha256.convert(p2Data).toString();

      final destDir = Directory('${tempDir.path}${Platform.pathSeparator}dest');
      await destDir.create();

      NexoraTransfer? serverCompleted;
      final server = TransferServer(
        customDestinationDirectory: destDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (_) {},
        onTransferCompleted: (c) => serverCompleted = c,
      );
      final port = await server.start();

      NexoraTransfer? clientCompleted;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (c) => clientCompleted = c,
        onError: (err) => fail(err),
      );

      final peer = NexoraDevice(
        deviceId: 'server',
        displayName: 'Receiver',
        platform: 'Android',
        fingerprint: 'fp',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final local = NexoraDevice(
        deviceId: 'sender',
        displayName: 'Sender',
        platform: 'Android',
        fingerprint: 'fp',
        lastSeen: DateTime.now(),
      );

      await client.sendFiles(peer: peer, files: [f1, f2], localDevice: local);

      await Future.delayed(const Duration(milliseconds: 300));

      expect(clientCompleted, isNotNull);
      expect(serverCompleted, isNotNull);
      expect(serverCompleted!.totalFiles, equals(2));

      final rf1 = File('${destDir.path}${Platform.pathSeparator}photo1.jpg');
      final rf2 = File('${destDir.path}${Platform.pathSeparator}photo2.jpg');

      expect(await rf1.exists(), isTrue);
      expect(
        sha256.convert(await rf1.readAsBytes()).toString(),
        equals(f1Hash),
      );

      expect(await rf2.exists(), isTrue);
      expect(
        sha256.convert(await rf2.readAsBytes()).toString(),
        equals(f2Hash),
      );

      server.stop();
    },
  );
}
