import 'dart:async';
import 'dart:math';

/// Stable NEXORA error codes governed by PRD Section 17.
enum NexoraErrorCode {
  deviceNotFound,
  deviceOffline,
  pairingRejected,
  pairingExpired,
  authenticationFailed,
  certificateInvalid,
  networkUnavailable,
  connectionTimeout,
  receiverBusy,
  insufficientStorage,
  fileAccessDenied,
  fileAlreadyExists,
  invalidFilename,
  transferInterrupted,
  checksumMismatch,
  protocolVersionUnsupported,
}

extension NexoraErrorCodeExt on NexoraErrorCode {
  String get code {
    switch (this) {
      case NexoraErrorCode.deviceNotFound:
        return 'DEVICE_NOT_FOUND';
      case NexoraErrorCode.deviceOffline:
        return 'DEVICE_OFFLINE';
      case NexoraErrorCode.pairingRejected:
        return 'PAIRING_REJECTED';
      case NexoraErrorCode.pairingExpired:
        return 'PAIRING_EXPIRED';
      case NexoraErrorCode.authenticationFailed:
        return 'AUTHENTICATION_FAILED';
      case NexoraErrorCode.certificateInvalid:
        return 'CERTIFICATE_INVALID';
      case NexoraErrorCode.networkUnavailable:
        return 'NETWORK_UNAVAILABLE';
      case NexoraErrorCode.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case NexoraErrorCode.receiverBusy:
        return 'RECEIVER_BUSY';
      case NexoraErrorCode.insufficientStorage:
        return 'INSUFFICIENT_STORAGE';
      case NexoraErrorCode.fileAccessDenied:
        return 'FILE_ACCESS_DENIED';
      case NexoraErrorCode.fileAlreadyExists:
        return 'FILE_ALREADY_EXISTS';
      case NexoraErrorCode.invalidFilename:
        return 'INVALID_FILENAME';
      case NexoraErrorCode.transferInterrupted:
        return 'TRANSFER_INTERRUPTED';
      case NexoraErrorCode.checksumMismatch:
        return 'CHECKSUM_MISMATCH';
      case NexoraErrorCode.protocolVersionUnsupported:
        return 'PROTOCOL_VERSION_UNSUPPORTED';
    }
  }

  String get recoveryGuidance {
    switch (this) {
      case NexoraErrorCode.deviceNotFound:
        return 'Ensure both devices are on the same local network or Wi-Fi hotspot.';
      case NexoraErrorCode.deviceOffline:
        return 'The target device appears offline. Re-launch NEXORA on the remote peer.';
      case NexoraErrorCode.pairingRejected:
        return 'The remote peer declined the pairing or transfer request.';
      case NexoraErrorCode.pairingExpired:
        return 'Pairing authentication timed out. Request pairing again.';
      case NexoraErrorCode.authenticationFailed:
        return 'Cryptographic key exchange signature mismatch. Re-pair device keys.';
      case NexoraErrorCode.certificateInvalid:
        return 'TLS certificate or peer trust token is invalid.';
      case NexoraErrorCode.networkUnavailable:
        return 'Local Wi-Fi interface is disconnected. Check network settings.';
      case NexoraErrorCode.connectionTimeout:
        return 'Connection timed out. Check firewall and network throughput.';
      case NexoraErrorCode.receiverBusy:
        return 'Receiver is processing another active transfer session.';
      case NexoraErrorCode.insufficientStorage:
        return 'Target storage drive does not have enough free disk space.';
      case NexoraErrorCode.fileAccessDenied:
        return 'Permission denied by operating system when writing to destination.';
      case NexoraErrorCode.fileAlreadyExists:
        return 'File already exists in destination and overwrite is disabled.';
      case NexoraErrorCode.invalidFilename:
        return 'Filename contains forbidden characters or path traversal sequence.';
      case NexoraErrorCode.transferInterrupted:
        return 'Data connection dropped mid-transfer. Stream can be resumed from last checkpoint.';
      case NexoraErrorCode.checksumMismatch:
        return 'Calculated SHA-256 hash does not match original manifest hash.';
      case NexoraErrorCode.protocolVersionUnsupported:
        return 'Protocol version mismatch. Update NEXORA to the latest version on both devices.';
    }
  }
}

class NexoraException implements Exception {
  final NexoraErrorCode code;
  final String message;
  final dynamic details;

  NexoraException(this.code, this.message, [this.details]);

  @override
  String toString() => '[${code.code}] $message (Guidance: ${code.recoveryGuidance})';
}

/// Standardized retry executor with exponential backoff and jitter.
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 5),
  });

  /// Executes [action] with exponential backoff on retriable errors.
  Future<T> execute<T>(Future<T> Function(int attempt) action) async {
    int attempt = 1;
    Duration currentDelay = initialDelay;
    final random = Random();

    while (true) {
      try {
        return await action(attempt);
      } catch (error) {
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Add 10-20% jitter to prevent thundering herd
        final jitterMs = random.nextInt((currentDelay.inMilliseconds * 0.2).toInt() + 1);
        final delayWithJitter = currentDelay + Duration(milliseconds: jitterMs);

        await Future.delayed(delayWithJitter);

        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier)
              .toInt()
              .clamp(initialDelay.inMilliseconds, maxDelay.inMilliseconds),
        );
        attempt++;
      }
    }
  }
}
