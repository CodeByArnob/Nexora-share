import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/network/protocol_messages.dart';

void main() {
  group('NEXORA Network Protocol Framing Tests', () {
    test('encodeFrame and decodeFramePayload round-trip', () {
      final sampleMessage = {
        'type': 'Hello',
        'payload': {
          'protocol_version': 1,
          'device': {
            'device_id': 'nexora-test-01',
            'display_name': 'Pixel 9 Pro',
            'platform': 'Android',
          },
        },
      };

      final frame = encodeFrame(sampleMessage);
      expect(frame.length, greaterThan(lengthPrefixSize));

      final byteData = ByteData.view(frame.buffer);
      final payloadLen = byteData.getUint32(0, Endian.big);
      expect(payloadLen, frame.length - lengthPrefixSize);

      final decoded = decodeFramePayload(frame.sublist(lengthPrefixSize));
      expect(decoded['type'], 'Hello');
      expect(decoded['payload']['device']['device_id'], 'nexora-test-01');
    });

    test(
      'encodeBinaryChunkFrame and decodeFramePayload zero-copy round-trip',
      () {
        final rawData = Uint8List(128 * 1024);
        for (int i = 0; i < rawData.length; i++) {
          rawData[i] = (i * 29) % 256;
        }

        final frame = encodeBinaryChunkFrame(
          transferId: 't-1234-abcd',
          fileId: 'f-file-01',
          chunkIndex: 3,
          totalChunks: 10,
          offset: 3 * 128 * 1024,
          data: rawData,
          chunkSha256: 'mock-sha256-hash',
        );

        expect(frame.length, greaterThan(rawData.length + lengthPrefixSize));

        final payloadBytes = frame.sublist(lengthPrefixSize);
        expect(payloadBytes[0], binaryChunkMagic);

        final decoded = decodeFramePayload(payloadBytes);
        expect(decoded['type'], 'ChunkData');

        final payload = decoded['payload'] as Map<String, dynamic>;
        expect(payload['transfer_id'], 't-1234-abcd');
        expect(payload['file_id'], 'f-file-01');
        expect(payload['chunk_index'], 3);
        expect(payload['total_chunks'], 10);
        expect(payload['offset'], 3 * 128 * 1024);
        expect(payload['chunk_sha256'], 'mock-sha256-hash');

        final chunkData = payload['data'] as Uint8List;
        expect(chunkData.length, rawData.length);
        expect(chunkData, equals(rawData));
      },
    );

    test('encodeFrame rejects payloads exceeding maxFrameSize', () {
      final hugeMessage = {
        'type': 'ChunkData',
        'payload': {'data': List.filled(maxFrameSize + 10, 0x41)},
      };

      expect(() => encodeFrame(hugeMessage), throwsException);
    });

    test('encodeBinaryChunkFrame rejects payloads exceeding maxFrameSize', () {
      final hugeData = Uint8List(maxFrameSize + 10);
      expect(
        () => encodeBinaryChunkFrame(
          transferId: 't',
          fileId: 'f',
          chunkIndex: 0,
          totalChunks: 1,
          offset: 0,
          data: hugeData,
        ),
        throwsException,
      );
    });
  });
}
