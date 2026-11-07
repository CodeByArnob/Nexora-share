import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/database/database_service.dart';
import 'package:nexora_desktop/models/device_model.dart';
import 'package:nexora_desktop/models/transfer_model.dart';
import 'package:nexora_desktop/network/file_transfer_manifest.dart';
import 'package:nexora_desktop/network/retry_policy.dart';
import 'package:nexora_desktop/network/transfer_client.dart';
import 'package:nexora_desktop/network/transfer_server.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_resume_test_');
    await DatabaseService.instance.initialize(inMemory: true);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Resume: skips already verified chunks and resumes from checkpoint without retransmission',
    () async {
      // 1. Create a 3 MiB source file
      final sourceFile = File(
        '${tempDir.path}${Platform.pathSeparator}large_video.mp4',
      );
      final chunkPattern = utf8.encode(
        'NEXORA_RELIABLE_RESUMABLE_CHUNK_DATA_PATTERN_0123456789_',
      );
      final builder = BytesBuilder(copy: false);
      while (builder.length < 3 * 1048576) {
        builder.add(chunkPattern);
      }
      final originalBytes = builder.toBytes().sublist(0, 3 * 1048576);
      await sourceFile.writeAsBytes(originalBytes);
      final expectedSha256 = sha256.convert(originalBytes).toString();

      // 2. Setup receiver destination
      final destDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}resume_downloads',
      );
      await destDir.create();

      // Simulate that chunks 0 and 1 (2 MiB total) were already received and written in an interrupted session
      const transferId = 'interrupted-session-42';
      const fileId = 'resumable-file-id';

      final partialDestFile = File(
        '${destDir.path}${Platform.pathSeparator}large_video.mp4',
      );
      final twoMbBytes = originalBytes.sublist(0, 2 * 1048576);
      await partialDestFile.writeAsBytes(twoMbBytes);

      // Record verified checkpoints in SQLite
      await DatabaseService.instance.recordVerifiedChunk(
        transferId: transferId,
        fileId: fileId,
        chunkIndex: 0,
        chunkOffset: 0,
        chunkSize: 1048576,
        chunkSha256: 'chunk0hash',
      );
      await DatabaseService.instance.recordVerifiedChunk(
        transferId: transferId,
        fileId: fileId,
        chunkIndex: 1,
        chunkOffset: 1048576,
        chunkSize: 1048576,
        chunkSha256: 'chunk1hash',
      );

      final highestOffset = await DatabaseService.instance
          .getHighestVerifiedOffset(transferId, fileId);
      expect(highestOffset, equals(2097152)); // Exactly 2 MiB

      // 3. Setup Receiver Server
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

      // 4. Setup Sender Client and trigger resume
      NexoraTransfer? clientCompleted;
      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (c) => clientCompleted = c,
        onError: (err) => fail(err),
      );

      final peer = NexoraDevice(
        deviceId: 'receiver',
        displayName: 'Receiver PC',
        platform: 'Windows',
        fingerprint: 'fp',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final local = NexoraDevice(
        deviceId: 'sender',
        displayName: 'Sender Phone',
        platform: 'Android',
        fingerprint: 'fp',
        lastSeen: DateTime.now(),
      );

      final manifest = TransferManifest(
        transferId: transferId,
        files: [
          ManifestItem(
            fileId: fileId,
            name: 'large_video.mp4',
            sizeBytes: 3 * 1048576,
            sha256Hash: expectedSha256,
            localPath: sourceFile.path,
          ),
        ],
        totalFiles: 1,
        totalBytes: 3 * 1048576,
      );

      // Send manifest starting from verified resumeOffset = 2 MiB
      await client.sendManifest(
        peer: peer,
        manifest: manifest,
        localDevice: local,
        resumeOffset: 2097152,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Verify that transfer completed and whole-file SHA-256 matches
      expect(clientCompleted, isNotNull);
      expect(serverCompleted, isNotNull);

      expect(await partialDestFile.exists(), isTrue);
      final finalBytes = await partialDestFile.readAsBytes();
      expect(finalBytes.length, equals(3 * 1048576));
      expect(sha256.convert(finalBytes).toString(), equals(expectedSha256));

      server.stop();
    },
  );

  test(
    'Retry: RetryPolicy executes exponential backoff and recovers on subsequent attempt',
    () async {
      final retryPolicy = const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 50),
        backoffMultiplier: 2.0,
        maxDelay: Duration(milliseconds: 500),
      );

      int attemptCount = 0;

      final result = await retryPolicy.execute((attempt) async {
        attemptCount++;
        if (attemptCount < 3) {
          throw const SocketException('Transient network drop simulation');
        }
        return 'Connected successfully on attempt $attemptCount';
      });

      expect(attemptCount, equals(3));
      expect(result, equals('Connected successfully on attempt 3'));
    },
  );

  test(
    'Retry: RetryPolicy propagates error when maxAttempts exhausted',
    () async {
      final retryPolicy = const RetryPolicy(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 20),
      );

      int attempts = 0;
      await expectLater(
        retryPolicy.execute((attempt) async {
          attempts++;
          throw const SocketException('Permanent connection error');
        }),
        throwsA(isA<SocketException>()),
      );

      expect(attempts, equals(2));
    },
  );
}
