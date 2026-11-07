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
          }
        }
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

    test('encodeFrame rejects payloads exceeding maxFrameSize', () {
      final hugeMessage = {
        'type': 'ChunkData',
        'payload': {
          'data': List.filled(maxFrameSize + 10, 0x41),
        }
      };

      expect(() => encodeFrame(hugeMessage), throwsException);
    });
  });
}
