import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/device_model.dart';

enum PairingVerificationStatus { valid, expired, replayDetected, invalidFormat }

class PairingVerificationResult {
  final PairingVerificationStatus status;
  final QrPairingData? data;
  final String? errorMessage;

  const PairingVerificationResult({
    required this.status,
    this.data,
    this.errorMessage,
  });

  bool get isValid => status == PairingVerificationStatus.valid && data != null;
}

class QrPairingData {
  final int version;
  final String sessionId;
  final String deviceId;
  final String displayName;
  final String platform;
  final String fingerprint;
  final String address;
  final int port;
  final String challengeNonce;
  final String sasCode;
  final DateTime expiresAt;

  const QrPairingData({
    required this.version,
    required this.sessionId,
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.fingerprint,
    required this.address,
    required this.port,
    required this.challengeNonce,
    required this.sasCode,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'v': version,
    'sid': sessionId,
    'did': deviceId,
    'name': displayName,
    'plt': platform,
    'fp': fingerprint,
    'addr': address,
    'p': port,
    'nonce': challengeNonce,
    'sas': sasCode,
    'exp': expiresAt.toUtc().toIso8601String(),
  };

  factory QrPairingData.fromJson(Map<String, dynamic> json) {
    return QrPairingData(
      version: json['v'] as int? ?? json['version'] as int? ?? 1,
      sessionId: json['sid'] as String? ?? json['session_id'] as String? ?? '',
      deviceId: json['did'] as String? ?? json['device_id'] as String? ?? '',
      displayName:
          json['name'] as String? ?? json['display_name'] as String? ?? 'Peer',
      platform:
          json['plt'] as String? ?? json['platform'] as String? ?? 'Unknown',
      fingerprint:
          json['fp'] as String? ?? json['fingerprint'] as String? ?? '',
      address:
          json['addr'] as String? ?? json['address'] as String? ?? '127.0.0.1',
      port: json['p'] as int? ?? json['port'] as int? ?? 48842,
      challengeNonce:
          json['nonce'] as String? ?? json['challenge_nonce'] as String? ?? '',
      sasCode:
          json['sas'] as String? ?? json['sas_code'] as String? ?? '000000',
      expiresAt:
          DateTime.tryParse(
            json['exp'] as String? ?? json['expires_at'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  NexoraDevice toDevice() {
    return NexoraDevice(
      deviceId: deviceId,
      displayName: displayName,
      platform: platform,
      fingerprint: fingerprint,
      address: address,
      lastSeen: DateTime.now(),
    );
  }
}

class PairingSecurityService {
  static final Set<String> _seenNonces = {};
  static final Map<String, DateTime> _nonceTimestamps = {};

  /// Generates a randomized 6-digit Short Authentication String (SAS).
  static String generateSasCode() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString();
  }

  /// Generates a cryptographic nonce string.
  static String generateNonce([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return sha256.convert(bytes).toString().substring(0, length * 2);
  }

  /// Formats a cryptographic SHA-256 fingerprint into readable byte pairs.
  static String formatFingerprint(String rawFp) {
    if (rawFp.isEmpty) return 'Unknown Fingerprint';
    final clean = rawFp.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toUpperCase();
    final parts = <String>[];
    for (int i = 0; i < clean.length && i < 32; i += 2) {
      parts.add(clean.substring(i, min(i + 2, clean.length)));
    }
    return parts.join(':');
  }

  /// Creates a secure optical QR pairing payload with expiring session token.
  static QrPairingData createPayload({
    required NexoraDevice localDevice,
    required int port,
    Duration ttl = const Duration(minutes: 10),
  }) {
    final rand = Random.secure();
    final sessionId =
        'ses-${DateTime.now().millisecondsSinceEpoch}-${rand.nextInt(100000)}';
    final nonce = generateNonce(12);
    final sas = generateSasCode();
    final expiresAt = DateTime.now().add(ttl);

    return QrPairingData(
      version: 1,
      sessionId: sessionId,
      deviceId: localDevice.deviceId,
      displayName: localDevice.displayName,
      platform: localDevice.platform,
      fingerprint: localDevice.fingerprint,
      address: localDevice.address ?? '127.0.0.1',
      port: port,
      challengeNonce: nonce,
      sasCode: sas,
      expiresAt: expiresAt,
    );
  }

  /// Validates an incoming scanned QR code string against expiration and replay attacks.
  static PairingVerificationResult verifyPayload(String rawPayload) {
    _pruneExpiredNonces();

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) {
        return const PairingVerificationResult(
          status: PairingVerificationStatus.invalidFormat,
          errorMessage: 'Invalid payload structure.',
        );
      }

      final pairingData = QrPairingData.fromJson(decoded);

      // 1. Expiration check
      if (DateTime.now().isAfter(pairingData.expiresAt)) {
        return PairingVerificationResult(
          status: PairingVerificationStatus.expired,
          data: pairingData,
          errorMessage: 'Pairing session expired. Please scan a fresh QR code.',
        );
      }

      // 2. Replay protection check
      if (pairingData.challengeNonce.isNotEmpty) {
        if (_seenNonces.contains(pairingData.challengeNonce)) {
          return PairingVerificationResult(
            status: PairingVerificationStatus.replayDetected,
            data: pairingData,
            errorMessage:
                'Replay attack detected: This pairing token was already used.',
          );
        }
        _seenNonces.add(pairingData.challengeNonce);
        _nonceTimestamps[pairingData.challengeNonce] = DateTime.now();
      }

      return PairingVerificationResult(
        status: PairingVerificationStatus.valid,
        data: pairingData,
      );
    } catch (e) {
      return PairingVerificationResult(
        status: PairingVerificationStatus.invalidFormat,
        errorMessage: 'Unable to parse QR payload: $e',
      );
    }
  }

  static void _pruneExpiredNonces() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    final expired = _nonceTimestamps.entries
        .where((e) => e.value.isBefore(cutoff))
        .map((e) => e.key)
        .toList();

    for (final k in expired) {
      _seenNonces.remove(k);
      _nonceTimestamps.remove(k);
    }
  }
}
