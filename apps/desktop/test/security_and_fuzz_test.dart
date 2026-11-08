import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/network/file_transfer_manifest.dart';
import 'package:nexora_desktop/network/protocol_messages.dart';
import 'package:nexora_desktop/network/transfer_server.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_fuzz_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Fuzzing & Security Defense Suite', () {
    test(
      'Fuzz 1: Length-prefix frame parser rejects oversized length headers without allocating',
      () async {
        final server = TransferServer(
          customDestinationDirectory: tempDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );
        final port = await server.start();

        // Connect raw TCP socket as attacker
        final socket = await Socket.connect('127.0.0.1', port);

        // Attempt 1: 50MB frame claim
        final maliciousHeader = Uint8List(4);
        ByteData.view(
          maliciousHeader.buffer,
        ).setUint32(0, 50 * 1024 * 1024, Endian.big);
        socket.add(maliciousHeader);
        await socket.flush();

        // Read from socket; server must immediately drop/destroy connection
        final done = Completer<bool>();
        socket.listen(
          (_) {},
          onDone: () => done.complete(true),
          onError: (_) => done.complete(true),
        );

        final wasClosed = await done.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => false,
        );
        expect(wasClosed, isTrue);

        server.stop();
      },
    );

    test(
      'Fuzz 2: Stream decoder rejects arbitrary randomized byte fuzzing without crashing',
      () async {
        final server = TransferServer(
          customDestinationDirectory: tempDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );
        final port = await server.start();

        final rng = Random(42);

        // Send 50 randomized corrupted packet sequences
        for (int i = 0; i < 50; i++) {
          final socket = await Socket.connect('127.0.0.1', port);

          // Generate random garbage payload between 10 and 1000 bytes
          final payloadLen = 10 + rng.nextInt(990);
          final randomBytes = Uint8List(payloadLen);
          for (int b = 0; b < payloadLen; b++) {
            randomBytes[b] = rng.nextInt(256);
          }

          // Send 4-byte length prefix pointing to the random bytes
          final header = Uint8List(4);
          ByteData.view(header.buffer).setUint32(0, payloadLen, Endian.big);

          socket.add(header);
          socket.add(randomBytes);
          await socket.flush();

          final done = Completer<bool>();
          socket.listen(
            (_) {},
            onDone: () => done.complete(true),
            onError: (_) => done.complete(true),
          );

          await done.future.timeout(
            const Duration(seconds: 1),
            onTimeout: () => false,
          );

          socket.destroy();
        }

        // Ensure server is still alive and responsive after fuzz storm
        expect(server.port, equals(port));
        server.stop();
      },
    );

    test(
      'Fuzz 3: JSON payload fuzzing rejects malformed schemas and corrupted types',
      () {
        // 1. Truncated JSON
        expect(
          () => decodeFramePayload(
            Uint8List.fromList(
              utf8.encode('{"type": "TransferOffer", "payload": {'),
            ),
          ),
          throwsA(isA<FormatException>()),
        );

        // 2. Corrupted UTF-8
        final badUtf8 = Uint8List.fromList([0xC0, 0xAF, 0xFE, 0xFF]);
        expect(
          () => decodeFramePayload(badUtf8),
          throwsA(isA<FormatException>()),
        );

        // 3. Negative length prefix encoding defense
        final hugePayload = <String, dynamic>{
          'huge_field': 'A' * (maxFrameSize + 100),
        };
        expect(() => encodeFrame(hugePayload), throwsA(isA<Exception>()));
      },
    );

    test(
      'Fuzz 4: Path traversal fuzzing defends against multiple injection patterns',
      () {
        final safeBaseDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}sandbox',
        );

        final attackVectors = [
          '../../../../../../etc/passwd',
          '..\\..\\..\\..\\Windows\\System32\\cmd.exe',
          '/root/.ssh/authorized_keys',
          'C:\\Windows\\explorer.exe',
          'sub/../../../../escaped.txt',
          'folder/../../../secret.key',
          'con.txt',
          'prn.pdf',
          'aux.bin',
          'nul.dat',
          'com1.log',
          'lpt1.iso',
          'file\x00with_null.txt',
          'test<illegal>chars:name.txt',
          '....//....//....//traversal.txt',
        ];

        for (final attack in attackVectors) {
          final resolved = PathSanitizer.resolveSafePath(
            destinationBaseDir: safeBaseDir,
            filename: attack.split(RegExp(r'[\\/]')).last,
            relativePath: attack,
          );

          // Assert 1: Resolved path MUST be strictly inside safeBaseDir
          expect(
            resolved.path.startsWith(safeBaseDir.path),
            isTrue,
            reason: 'Failed to sandbox: $attack -> ${resolved.path}',
          );

          // Assert 2: Path must not contain '..' components
          final segments = resolved.path.split(Platform.pathSeparator);
          expect(segments.contains('..'), isFalse);

          // Assert 3: Filename must not match Windows reserved devices unescaped
          final resolvedName = segments.last.toUpperCase().split('.').first;
          expect(
            {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'LPT1'}.contains(resolvedName),
            isFalse,
            reason: 'Reserved device name not escaped: $resolvedName',
          );
        }
      },
    );

    test(
      'Fuzz 5: Checksum corruption rejects tampered chunk data with error',
      () async {
        final serverDestDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}verified_downloads',
        );
        await serverDestDir.create();

        String? reportedError;
        final server = TransferServer(
          customDestinationDirectory: serverDestDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
          onError: (err) {
            reportedError = err;
          },
        );
        final port = await server.start();

        final socket = await Socket.connect('127.0.0.1', port);

        // 1. Send Hello
        socket.add(
          encodeFrame({
            'type': 'Hello',
            'payload': {
              'protocol_version': 1,
              'device': {'display_name': 'Attacker', 'platform': 'Linux'},
            },
          }),
        );

        // 2. Send TransferOffer with declared file
        final offerMessage = {
          'type': 'TransferOffer',
          'payload': {
            'transfer_id': 'fuzz-transfer-1',
            'manifest': {
              'transfer_id': 'fuzz-transfer-1',
              'total_files': 1,
              'total_bytes': 100,
              'files': [
                {
                  'file_id': 'file-1',
                  'name': 'tampered_file.bin',
                  'size_bytes': 100,
                  'sha256_hash':
                      '0000000000000000000000000000000000000000000000000000000000000000',
                },
              ],
            },
          },
        };
        socket.add(encodeFrame(offerMessage));
        await socket.flush();

        // Wait for TransferAccept
        await Future.delayed(const Duration(milliseconds: 200));

        // 3. Send ChunkData with corrupted SHA-256
        final originalData = utf8.encode(
          'Legitimate uncorrupted data block payload for testing...',
        );
        final tamperedSha256 =
            'badbeef1234567890badbeef1234567890badbeef1234567890badbeef123456';

        final chunkMessage = {
          'type': 'ChunkData',
          'payload': {
            'transfer_id': 'fuzz-transfer-1',
            'file_id': 'file-1',
            'chunk_index': 0,
            'offset': 0,
            'size': originalData.length,
            'data': base64Encode(originalData),
            'chunk_sha256': tamperedSha256,
          },
        };
        socket.add(encodeFrame(chunkMessage));
        await socket.flush();

        await Future.delayed(const Duration(milliseconds: 300));

        // Error callback should be triggered for checksum mismatch
        expect(reportedError, isNotNull);
        expect(reportedError!.contains('CHECKSUM_MISMATCH'), isTrue);

        socket.destroy();
        server.stop();
      },
    );

    test(
      'Fuzz 6: Unauthorized transfer rejection: chunks received before offer are discarded',
      () async {
        final server = TransferServer(
          port: 0,
          customDestinationDirectory: tempDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );
        final port = await server.start();

        final socket = await Socket.connect('127.0.0.1', port);

        // Prematurely send ChunkData without preceding Hello or TransferOffer
        final prematureChunk = {
          'type': 'ChunkData',
          'payload': {
            'transfer_id': 'unauthorized-transfer',
            'file_id': 'file-unauth',
            'chunk_index': 0,
            'offset': 0,
            'size': 16,
            'data': base64Encode(utf8.encode('unauthorizedData')),
            'chunk_sha256': sha256
                .convert(utf8.encode('unauthorizedData'))
                .toString(),
          },
        };

        // Server should not throw uncaught error or write untracked file to disk
        socket.add(encodeFrame(prematureChunk));
        await socket.flush();

        await Future.delayed(const Duration(milliseconds: 200));

        // Check no unapproved file was created in destination
        final files = await tempDir.list().toList();
        expect(files, isEmpty);

        socket.destroy();
        server.stop();
      },
    );
  });
}
