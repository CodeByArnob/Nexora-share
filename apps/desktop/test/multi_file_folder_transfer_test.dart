import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/database/database_service.dart';
import 'package:nexora_desktop/models/device_model.dart';
import 'package:nexora_desktop/models/transfer_model.dart';
import 'package:nexora_desktop/network/file_transfer_manifest.dart';
import 'package:nexora_desktop/network/transfer_client.dart';
import 'package:nexora_desktop/network/transfer_server.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_multifile_test_');
    await DatabaseService.instance.initialize(inMemory: true);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Multi-file batch transfer: streams 3 files in single manifest with verified SHA-256',
    () async {
      // 1. Prepare 3 source files
      final srcDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}source_files',
      );
      await srcDir.create();

      final file1 = File('${srcDir.path}${Platform.pathSeparator}document.txt');
      await file1.writeAsString(
        'Hello NEXORA Multi-file Batch Streaming Protocol!',
      );
      final file1Hash = sha256.convert(await file1.readAsBytes()).toString();

      final file2 = File(
        '${srcDir.path}${Platform.pathSeparator}binary_asset.bin',
      );
      final binData = Uint8List.fromList(List.generate(150000, (i) => i % 256));
      await file2.writeAsBytes(binData);
      final file2Hash = sha256.convert(binData).toString();

      final file3 = File('${srcDir.path}${Platform.pathSeparator}config.json');
      await file3.writeAsString(
        jsonEncode({'app': 'NEXORA', 'version': '1.0.0', 'multi_file': true}),
      );
      final file3Hash = sha256.convert(await file3.readAsBytes()).toString();

      // 2. Setup Receiver Server
      final destDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}receiver_downloads',
      );
      await destDir.create();

      NexoraTransfer? serverCompleted;
      final server = TransferServer(
        customDestinationDirectory: destDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (_) {},
        onTransferCompleted: (completed) {
          serverCompleted = completed;
        },
      );
      final port = await server.start();

      // 3. Setup Sender Client
      NexoraTransfer? clientCompleted;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (c) {
          clientCompleted = c;
        },
        onError: (err) => fail('Client error: $err'),
      );

      final peer = NexoraDevice(
        deviceId: 'receiver-device-id',
        displayName: 'Pixel 9 Pro (Receiver)',
        platform: 'Android',
        fingerprint: 'fp-receiver',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final local = NexoraDevice(
        deviceId: 'sender-device-id',
        displayName: 'Windows PC (Sender)',
        platform: 'Windows',
        fingerprint: 'fp-sender',
        lastSeen: DateTime.now(),
      );

      // 4. Send the 3 files
      await client.sendFiles(
        peer: peer,
        files: [file1, file2, file3],
        localDevice: local,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Verify batch completion
      expect(clientCompleted, isNotNull);
      expect(clientCompleted!.totalFiles, equals(3));
      expect(serverCompleted, isNotNull);
      expect(serverCompleted!.totalFiles, equals(3));

      // Verify all 3 files exist on destination and match original SHA-256
      final recv1 = File(
        '${destDir.path}${Platform.pathSeparator}document.txt',
      );
      expect(await recv1.exists(), isTrue);
      expect(
        sha256.convert(await recv1.readAsBytes()).toString(),
        equals(file1Hash),
      );

      final recv2 = File(
        '${destDir.path}${Platform.pathSeparator}binary_asset.bin',
      );
      expect(await recv2.exists(), isTrue);
      expect(
        sha256.convert(await recv2.readAsBytes()).toString(),
        equals(file2Hash),
      );

      final recv3 = File('${destDir.path}${Platform.pathSeparator}config.json');
      expect(await recv3.exists(), isTrue);
      expect(
        sha256.convert(await recv3.readAsBytes()).toString(),
        equals(file3Hash),
      );

      server.stop();
    },
  );

  test(
    'Folder transfer: recursively streams folder preserving nested directory hierarchy',
    () async {
      // 1. Create source folder structure:
      // folder/
      //   readme.md
      //   sub1/
      //     nested.txt
      //   sub2/
      //     deeper/
      //       data.bin
      final rootFolder = Directory(
        '${tempDir.path}${Platform.pathSeparator}project_folder',
      );
      final sub1 = Directory('${rootFolder.path}${Platform.pathSeparator}sub1');
      final sub2Deeper = Directory(
        '${rootFolder.path}${Platform.pathSeparator}sub2${Platform.pathSeparator}deeper',
      );
      await sub1.create(recursive: true);
      await sub2Deeper.create(recursive: true);

      final f1 = File('${rootFolder.path}${Platform.pathSeparator}readme.md');
      await f1.writeAsString('# Project Readme');
      final f1Hash = sha256.convert(await f1.readAsBytes()).toString();

      final f2 = File('${sub1.path}${Platform.pathSeparator}nested.txt');
      await f2.writeAsString('Nested content in sub1');
      final f2Hash = sha256.convert(await f2.readAsBytes()).toString();

      final f3 = File('${sub2Deeper.path}${Platform.pathSeparator}data.bin');
      final dataBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      await f3.writeAsBytes(dataBytes);
      final f3Hash = sha256.convert(dataBytes).toString();

      // 2. Setup Receiver
      final destDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}receiver_folder_downloads',
      );
      await destDir.create();

      NexoraTransfer? serverCompleted;
      final server = TransferServer(
        customDestinationDirectory: destDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (_) {},
        onTransferCompleted: (completed) {
          serverCompleted = completed;
        },
      );
      final port = await server.start();

      // 3. Setup Sender Client
      NexoraTransfer? clientCompleted;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (c) => clientCompleted = c,
        onError: (err) => fail(err),
      );

      final peer = NexoraDevice(
        deviceId: 'receiver',
        displayName: 'Receiver',
        platform: 'Linux',
        fingerprint: 'fp',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final local = NexoraDevice(
        deviceId: 'sender',
        displayName: 'Sender',
        platform: 'Windows',
        fingerprint: 'fp',
        lastSeen: DateTime.now(),
      );

      // 4. Send folder
      await client.sendDirectory(
        peer: peer,
        directory: rootFolder,
        localDevice: local,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Verify assertions
      expect(clientCompleted, isNotNull);
      expect(clientCompleted!.totalFiles, equals(3));
      expect(serverCompleted, isNotNull);

      // Verify folder hierarchy on receiver disk:
      // destDir/project_folder/readme.md
      // destDir/project_folder/sub1/nested.txt
      // destDir/project_folder/sub2/deeper/data.bin
      final base = '${destDir.path}${Platform.pathSeparator}project_folder';
      final recvF1 = File('$base${Platform.pathSeparator}readme.md');
      final recvF2 = File(
        '$base${Platform.pathSeparator}sub1${Platform.pathSeparator}nested.txt',
      );
      final recvF3 = File(
        '$base${Platform.pathSeparator}sub2${Platform.pathSeparator}deeper${Platform.pathSeparator}data.bin',
      );

      expect(await recvF1.exists(), isTrue);
      expect(
        sha256.convert(await recvF1.readAsBytes()).toString(),
        equals(f1Hash),
      );

      expect(await recvF2.exists(), isTrue);
      expect(
        sha256.convert(await recvF2.readAsBytes()).toString(),
        equals(f2Hash),
      );

      expect(await recvF3.exists(), isTrue);
      expect(
        sha256.convert(await recvF3.readAsBytes()).toString(),
        equals(f3Hash),
      );

      server.stop();
    },
  );

  test(
    'Security: PathSanitizer neutralizes path traversal attacks and Windows reserved words',
    () {
      final baseDir = Directory('C:\\Users\\User\\Downloads\\NEXORA');

      // 1. Path traversal attacks
      final evil1 = PathSanitizer.resolveSafePath(
        destinationBaseDir: baseDir,
        filename: 'exploit.bat',
        relativePath: '../../../../Windows/System32/exploit.bat',
      );
      expect(evil1.path.contains('..'), isFalse);
      expect(evil1.path.startsWith(baseDir.path), isTrue);

      // 2. Drive letter attempt
      final evil2 = PathSanitizer.resolveSafePath(
        destinationBaseDir: baseDir,
        filename: 'root.exe',
        relativePath: 'D:/System/root.exe',
      );
      expect(evil2.path.startsWith(baseDir.path), isTrue);

      // 3. Windows reserved names (CON, PRN, AUX, NUL, COM1-9, LPT1-9)
      final conSanitized = PathSanitizer.sanitizeFilename('CON.txt');
      expect(conSanitized, equals('_CON.txt'));

      final auxSanitized = PathSanitizer.sanitizeFilename('aux.log');
      expect(auxSanitized, equals('_aux.log'));

      final nulSanitized = PathSanitizer.sanitizeFilename('NUL');
      expect(nulSanitized, equals('_NUL'));
    },
  );
}
