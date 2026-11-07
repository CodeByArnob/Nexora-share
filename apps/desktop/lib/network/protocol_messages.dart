import 'dart:convert';
import 'dart:typed_data';

/// Official NEXORA Protocol Version
const int currentProtocolVersion = 1;
const int maxFrameSize = 5 * 1024 * 1024; // 5 MB
const int defaultChunkSize = 1024 * 1024; // 1 MB
const int lengthPrefixSize = 4;

/// Encodes a JSON map into a 4-byte big-endian length-prefixed frame.
Uint8List encodeFrame(Map<String, dynamic> message) {
  final jsonBytes = utf8.encode(jsonEncode(message));
  final length = jsonBytes.length;
  if (length > maxFrameSize) {
    throw Exception(
      'Message size $length exceeds maximum allowed frame size $maxFrameSize',
    );
  }

  final frame = Uint8List(lengthPrefixSize + length);
  final byteData = ByteData.view(frame.buffer);
  byteData.setUint32(0, length, Endian.big);
  frame.setRange(lengthPrefixSize, lengthPrefixSize + length, jsonBytes);
  return frame;
}

/// Decodes a 4-byte big-endian length-prefixed payload from raw bytes.
Map<String, dynamic> decodeFramePayload(Uint8List payloadBytes) {
  final jsonString = utf8.decode(payloadBytes);
  return jsonDecode(jsonString) as Map<String, dynamic>;
}
