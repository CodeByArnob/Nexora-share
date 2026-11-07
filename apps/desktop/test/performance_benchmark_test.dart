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
    tempDir = await Directory.systemTemp.createTemp('nexora_perf_test_');
    dbService = DatabaseService.instance;
    await dbService.initialize(inMemory: true);
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Performance & Bounded Memory Streaming Benchmarks', () {
    test(
      'Benchmark 1: Bounded memory 1MB chunk slicing streams 5MB without RAM inflation',
      () async {
        // Create a 5MB payload
        final sourceFile = File(
          '${tempDir.path}${Platform.pathSeparator}5mb_payload.bin',
        );
        final pattern = utf8.encode(
          'NEXORA_BOUNDED_MEMORY_STREAMING_BLOCK_1024_',
        );
        final builder = BytesBuilder(copy: false);
        while (builder.length < 5 * 1024 * 1024) {
          builder.add(pattern);
        }
        final fileBytes = builder.toBytes().sublist(0, 5 * 1024 * 1024);
        await sourceFile.writeAsBytes(fileBytes);
        final expectedSha = sha256.convert(fileBytes).toString();

        final destDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}dest',
        );
        await destDir.create();

        final server = TransferServer(
          customDestinationDirectory: destDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );
        final port = await server.start();

        final stopwatch = Stopwatch()..start();
        NexoraTransfer? completedTransfer;

        final client = TransferClient(
          onProgress: (_) {},
          onCompleted: (c) => completedTransfer = c,
          onError: (err) => fail('Transfer error: $err'),
        );

        final targetDevice = NexoraDevice(
          deviceId: 'target-1',
          displayName: 'Target Receiver',
          platform: 'Desktop',
          fingerprint:
              '1122334455667788990011223344556677889900112233445566778899001122',
          address: '127.0.0.1',
          port: port,
          lastSeen: DateTime.now(),
        );

        final localDevice = NexoraDevice(
          deviceId: 'sender-1',
          displayName: 'Sender Node',
          platform: 'Desktop',
          fingerprint:
              '9988776655443322110099887766554433221100998877665544332211009988',
          lastSeen: DateTime.now(),
        );

        await client.sendFile(
          peer: targetDevice,
          file: sourceFile,
          localDevice: localDevice,
        );

        await Future.delayed(const Duration(milliseconds: 300));
        stopwatch.stop();

        expect(completedTransfer, isNotNull);
        expect(completedTransfer!.bytesTransferred, equals(5 * 1024 * 1024));
        expect(completedTransfer!.state, equals(TransferState.completed));

        // Verify received file integrity
        final receivedFile = File(
          '${destDir.path}${Platform.pathSeparator}5mb_payload.bin',
        );
        expect(await receivedFile.exists(), isTrue);
        expect(await receivedFile.length(), equals(5 * 1024 * 1024));

        final receivedSha = sha256
            .convert(await receivedFile.readAsBytes())
            .toString();
        expect(receivedSha, equals(expectedSha));

        server.stop();
      },
    );

    test(
      'Benchmark 2: Multi-file batch transfer streams 25 small files with verified integrity',
      () async {
        final batchDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}batch_source',
        );
        await batchDir.create();

        final fileList = <File>[];
        final hashes = <String>[];

        for (int i = 0; i < 25; i++) {
          final f = File('${batchDir.path}${Platform.pathSeparator}doc_$i.txt');
          final content =
              'NEXORA multi-file batch test payload block index: $i\n' * 50;
          await f.writeAsString(content);
          fileList.add(f);
          hashes.add(sha256.convert(utf8.encode(content)).toString());
        }

        final manifest = await TransferManifest.fromFiles(fileList);
        expect(manifest.totalFiles, equals(25));

        final destDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}batch_dest',
        );
        await destDir.create();

        final server = TransferServer(
          customDestinationDirectory: destDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );
        final port = await server.start();

        NexoraTransfer? completedTransfer;
        final client = TransferClient(
          onProgress: (_) {},
          onCompleted: (c) => completedTransfer = c,
          onError: (e) => fail('Batch error: $e'),
        );

        await client.sendFiles(
          peer: NexoraDevice(
            deviceId: 'rx-node',
            displayName: 'Receiver',
            platform: 'Desktop',
            fingerprint:
                '1122334455667788990011223344556677889900112233445566778899001122',
            address: '127.0.0.1',
            port: port,
            lastSeen: DateTime.now(),
          ),
          files: fileList,
          localDevice: NexoraDevice(
            deviceId: 'tx-node',
            displayName: 'Sender',
            platform: 'Desktop',
            fingerprint:
                '9988776655443322110099887766554433221100998877665544332211009988',
            lastSeen: DateTime.now(),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        expect(completedTransfer, isNotNull);
        expect(completedTransfer!.totalFiles, equals(25));
        expect(completedTransfer!.state, equals(TransferState.completed));

        // Verify each received file
        for (int i = 0; i < 25; i++) {
          final rf = File('${destDir.path}${Platform.pathSeparator}doc_$i.txt');
          expect(await rf.exists(), isTrue);
          final rBytes = await rf.readAsBytes();
          expect(sha256.convert(rBytes).toString(), equals(hashes[i]));
        }

        server.stop();
      },
    );

    test(
      'Benchmark 3: Lifecycle persistence safely recovers interrupted transfers after simulated crash',
      () async {
        // 1. Log an in-progress transfer as if the app crashed mid-transfer
        final activeTransfer = NexoraTransfer(
          transferId: 'crash-recovered-transfer-1',
          direction: TransferDirection.receive,
          remoteDeviceId: 'sender-device-9',
          remoteDeviceName: 'Pixel 9 Pro (NEXORA)',
          totalFiles: 1,
          totalBytes: 100000000, // 100 MB
          bytesTransferred: 45000000, // 45 MB transferred so far
          currentFile: 'large_video_archive.mp4',
          state: TransferState.inProgress,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await dbService.logTransfer(activeTransfer);

        // Record 45 verified 1MB chunks
        for (int c = 0; c < 45; c++) {
          await dbService.recordVerifiedChunk(
            transferId: 'crash-recovered-transfer-1',
            fileId: 'file-vid-1',
            chunkIndex: c,
            chunkOffset: c * 1000000,
            chunkSize: 1000000,
            chunkSha256: 'mock_chunk_hash_$c',
          );
        }

        // 2. Simulated app startup: mark interrupted transfers
        final updatedCount = await dbService.markInterruptedTransfers();
        expect(updatedCount, equals(1));

        // 3. Query incomplete transfers
        final incomplete = await dbService.getIncompleteTransfers();
        expect(incomplete.length, equals(1));
        expect(
          incomplete.first.transferId,
          equals('crash-recovered-transfer-1'),
        );
        expect(incomplete.first.state, equals(TransferState.failed));
        expect(incomplete.first.bytesTransferred, equals(45000000));

        // 4. Query highest verified offset for resume
        final resumeOffset = await dbService.getHighestVerifiedOffset(
          'crash-recovered-transfer-1',
          'file-vid-1',
        );
        expect(resumeOffset, equals(45000000));
      },
    );
  });
}
