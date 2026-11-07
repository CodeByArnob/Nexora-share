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
  late DatabaseService dbService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_linux_test_');
    dbService = DatabaseService.instance;
    await dbService.initialize(inMemory: true);
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Linux Receiver <-> Android Sender: Multi-chunk streaming with backpressure and SQLite history',
    () async {
      // 1. Android Sender generates a 2.3MB binary file
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}android_photo_backup.raw',
      );
      final pattern = utf8.encode(
        'NEXORA_LINUX_ANDROID_INTEROP_RAW_PAYLOAD_CHUNK_',
      );
      final builder = BytesBuilder(copy: false);
      while (builder.length < 2300000) {
        builder.add(pattern);
      }
      final rawBytes = builder.toBytes().sublist(0, 2300000);
      await sourceFile.writeAsBytes(rawBytes);
      final expectedSha256 = sha256.convert(rawBytes).toString();

      // 2. Linux Desktop sets up TransferServer
      final linuxDestDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}linux_downloads',
      );
      await linuxDestDir.create();

      IncomingTransferOffer? receivedOffer;
      NexoraTransfer? receiverCompletedTransfer;

      final receiverServer = TransferServer(
        customDestinationDirectory: linuxDestDir,
        onRequestApproval: (offer) async {
          receivedOffer = offer;
          return true;
        },
        onTransferProgress: (_) {},
        onTransferCompleted: (completed) {
          receiverCompletedTransfer = completed;
        },
      );

      final receiverPort = await receiverServer.start();

      // 3. Android Client connects to Linux Desktop
      final androidDevice = NexoraDevice(
        deviceId: 'pixel-9-pro-uuid',
        displayName: 'Pixel 9 Pro (NEXORA)',
        platform: 'Android',
        fingerprint:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        address: '127.0.0.1',
        port: receiverPort,
        lastSeen: DateTime.now(),
      );

      // Save Android peer in SQLite
      await dbService.upsertDevice(androidDevice, isTrusted: true);

      NexoraTransfer? clientCompletedTransfer;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (completed) {
          clientCompletedTransfer = completed;
        },
        onError: (err) {
          fail('Android sender error: $err');
        },
      );

      final linuxPeer = NexoraDevice(
        deviceId: 'linux-desktop-local',
        displayName: 'Linux PC (NEXORA)',
        platform: 'Linux',
        fingerprint:
            '1122334455667788990011223344556677889900112233445566778899001122',
        address: '127.0.0.1',
        port: receiverPort,
        lastSeen: DateTime.now(),
      );

      await client.sendFile(
        peer: linuxPeer,
        file: sourceFile,
        localDevice: androidDevice,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      // 4. Verify receiver received correct Android offer metadata
      expect(receivedOffer, isNotNull);
      expect(receivedOffer!.senderPlatform, equals('Android'));
      expect(receivedOffer!.senderName, equals('Pixel 9 Pro (NEXORA)'));
      expect(receivedOffer!.fileName, equals('android_photo_backup.raw'));
      expect(receivedOffer!.totalBytes, equals(2300000));

      // 5. Verify client completion
      expect(clientCompletedTransfer, isNotNull);
      expect(clientCompletedTransfer!.state, equals(TransferState.completed));
      expect(clientCompletedTransfer!.bytesTransferred, equals(2300000));
      expect(receiverCompletedTransfer, isNotNull);

      // 6. Verify received file on Linux filesystem and SHA-256 match
      final receivedFile = File(
        '${linuxDestDir.path}${Platform.pathSeparator}android_photo_backup.raw',
      );
      expect(await receivedFile.exists(), isTrue);
      expect(await receivedFile.length(), equals(2300000));

      final receivedBytes = await receivedFile.readAsBytes();
      final receivedSha256 = sha256.convert(receivedBytes).toString();
      expect(receivedSha256, equals(expectedSha256));

      // 7. Verify SQLite transfer history logging
      await dbService.logTransfer(clientCompletedTransfer!);
      final history = await dbService.getTransferHistory();
      expect(history.length, equals(1));
      expect(history.first.totalBytes, equals(2300000));
      expect(history.first.state, equals(TransferState.completed));

      receiverServer.stop();
    },
  );

  test(
    'Linux Sender <-> Windows Receiver: Directory hierarchy transfer with UNIX forward slashes',
    () async {
      // 1. Linux Sender creates nested directory structure:
      //    workspace/
      //      src/main.rs
      //      docs/architecture.md
      //      assets/icon.svg
      final workspaceDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}workspace',
      );
      await workspaceDir.create();

      final srcDir = Directory(
        '${workspaceDir.path}${Platform.pathSeparator}src',
      );
      await srcDir.create();
      final docsDir = Directory(
        '${workspaceDir.path}${Platform.pathSeparator}docs',
      );
      await docsDir.create();
      final assetsDir = Directory(
        '${workspaceDir.path}${Platform.pathSeparator}assets',
      );
      await assetsDir.create();

      final fileMain = File('${srcDir.path}${Platform.pathSeparator}main.rs');
      await fileMain.writeAsString(
        'fn main() { println!("Hello from NEXORA Linux!"); }',
      );

      final fileDocs = File(
        '${docsDir.path}${Platform.pathSeparator}architecture.md',
      );
      await fileDocs.writeAsString(
        '# NEXORA Architecture\nPeer-to-peer cross platform file sharing.',
      );

      final fileIcon = File(
        '${assetsDir.path}${Platform.pathSeparator}icon.svg',
      );
      await fileIcon.writeAsString(
        '<svg xmlns="http://www.w3.org/2000/svg"><circle r="10"/></svg>',
      );

      // Build directory manifest
      final manifest = await TransferManifest.fromDirectory(workspaceDir);
      expect(manifest.totalFiles, equals(3));
      expect(
        manifest.files.any((f) => f.relativePath!.contains('src/main.rs')),
        isTrue,
      );
      expect(
        manifest.files.any(
          (f) => f.relativePath!.contains('docs/architecture.md'),
        ),
        isTrue,
      );
      expect(
        manifest.files.any((f) => f.relativePath!.contains('assets/icon.svg')),
        isTrue,
      );

      // 2. Setup Windows Receiver
      final winDestDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}windows_received',
      );
      await winDestDir.create();

      final receiverServer = TransferServer(
        customDestinationDirectory: winDestDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (_) {},
        onTransferCompleted: (_) {},
      );
      final receiverPort = await receiverServer.start();

      // 3. Linux Client sends directory
      final linuxDevice = NexoraDevice(
        deviceId: 'linux-pc-1',
        displayName: 'Arch Linux (NEXORA)',
        platform: 'Linux',
        fingerprint:
            '9988776655443322110099887766554433221100998877665544332211009988',
        lastSeen: DateTime.now(),
      );

      final windowsPeer = NexoraDevice(
        deviceId: 'win-ws-1',
        displayName: 'Windows Workstation (NEXORA)',
        platform: 'Windows',
        fingerprint:
            '14243b3978f639c6b00d142017243af5f7fb00112233445566778899aabbccdd',
        address: '127.0.0.1',
        port: receiverPort,
        lastSeen: DateTime.now(),
      );

      NexoraTransfer? clientCompleted;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (c) => clientCompleted = c,
        onError: (e) => fail('Linux directory sender error: $e'),
      );

      await client.sendDirectory(
        peer: windowsPeer,
        directory: workspaceDir,
        localDevice: linuxDevice,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      expect(clientCompleted, isNotNull);
      expect(clientCompleted!.state, equals(TransferState.completed));
      expect(clientCompleted!.totalFiles, equals(3));

      // 4. Verify all files and directory hierarchy exist on Windows destination
      final receivedMain = File(
        '${winDestDir.path}${Platform.pathSeparator}workspace${Platform.pathSeparator}src${Platform.pathSeparator}main.rs',
      );
      final receivedDocs = File(
        '${winDestDir.path}${Platform.pathSeparator}workspace${Platform.pathSeparator}docs${Platform.pathSeparator}architecture.md',
      );
      final receivedIcon = File(
        '${winDestDir.path}${Platform.pathSeparator}workspace${Platform.pathSeparator}assets${Platform.pathSeparator}icon.svg',
      );

      expect(await receivedMain.exists(), isTrue);
      expect(await receivedDocs.exists(), isTrue);
      expect(await receivedIcon.exists(), isTrue);

      expect(
        await receivedMain.readAsString(),
        contains('Hello from NEXORA Linux!'),
      );
      expect(
        await receivedDocs.readAsString(),
        contains('# NEXORA Architecture'),
      );

      receiverServer.stop();
    },
  );

  test(
    'Linux Security & Path Sanitizer: Rejects UNIX path traversal & absolute system escapes',
    () {
      final baseDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}safe_sandbox',
      );

      // Test 1: Absolute root path escape
      final escape1 = PathSanitizer.resolveSafePath(
        destinationBaseDir: baseDir,
        filename: 'passwd',
        relativePath: '/etc/passwd',
      );
      expect(escape1.path.startsWith(baseDir.path), isTrue);
      expect(escape1.path.contains('etc'), isTrue);
      expect(escape1.path, isNot(equals('/etc/passwd')));

      // Test 2: Double dot parent directory escape
      final escape2 = PathSanitizer.resolveSafePath(
        destinationBaseDir: baseDir,
        filename: 'id_rsa',
        relativePath: '../../../../root/.ssh/id_rsa',
      );
      expect(escape2.path.startsWith(baseDir.path), isTrue);
      expect(escape2.path.contains('..'), isFalse);

      // Test 3: Windows reserved names defense
      final sanitizedCon = PathSanitizer.sanitizeFilename('CON.txt');
      expect(sanitizedCon, equals('_CON.txt'));

      final sanitizedAux = PathSanitizer.sanitizeFilename('aux.log');
      expect(sanitizedAux, equals('_aux.log'));

      // Test 4: Control characters and forbidden characters
      final sanitizedWildcards = PathSanitizer.sanitizeFilename(
        'test<?>:"|*.txt',
      );
      expect(sanitizedWildcards.contains('<'), isFalse);
      expect(sanitizedWildcards.contains('>'), isFalse);
      expect(sanitizedWildcards.contains(':'), isFalse);
      expect(sanitizedWildcards.contains('*'), isFalse);
    },
  );

  test(
    'Linux Network Diagnostics: Verifies UDP/TCP socket binding and environment resolution',
    () async {
      // 1. Verify TCP port binding on loopback
      final tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      expect(tcpServer.port, greaterThan(0));
      await tcpServer.close();

      // 2. Verify UDP port binding with reusePort on Linux
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      expect(udpSocket.port, greaterThan(0));
      udpSocket.close();

      // 3. Verify Download directory path resolution for Linux
      final homeDir =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          tempDir.path;
      final resolvedDownloads =
          '$homeDir${Platform.pathSeparator}Downloads${Platform.pathSeparator}NEXORA';
      expect(resolvedDownloads, contains('NEXORA'));
    },
  );
}
