import 'dart:io';
import 'package:crypto/crypto.dart';

/// Minimal, zero-allocation Sink implementation to collect streaming Digest from sha256
class DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

/// Comprehensive performance instrumentation tracking transfer latency,
/// memory overhead, throughput, and verification duration.
class TransferPerformanceMetrics {
  final String transferId;
  final int totalBytes;
  final int totalFiles;
  final double requestCreationTimeMs;
  final double connectionEstablishmentTimeMs;
  final double receiverNotificationLatencyMs;
  final double userAcceptanceLatencyMs;
  final double firstByteLatencyMs;
  final double transferDurationMs;
  final double transferThroughputMBs;
  final int peakMemoryBytes;
  final double finalVerificationTimeMs;

  const TransferPerformanceMetrics({
    required this.transferId,
    required this.totalBytes,
    required this.totalFiles,
    required this.requestCreationTimeMs,
    required this.connectionEstablishmentTimeMs,
    required this.receiverNotificationLatencyMs,
    required this.userAcceptanceLatencyMs,
    required this.firstByteLatencyMs,
    required this.transferDurationMs,
    required this.transferThroughputMBs,
    required this.peakMemoryBytes,
    required this.finalVerificationTimeMs,
  });

  Map<String, dynamic> toJson() => {
    'transfer_id': transferId,
    'total_bytes': totalBytes,
    'total_files': totalFiles,
    'request_creation_ms': requestCreationTimeMs,
    'connection_establishment_ms': connectionEstablishmentTimeMs,
    'receiver_notification_latency_ms': receiverNotificationLatencyMs,
    'user_acceptance_latency_ms': userAcceptanceLatencyMs,
    'first_byte_latency_ms': firstByteLatencyMs,
    'transfer_duration_ms': transferDurationMs,
    'throughput_mb_s': transferThroughputMBs,
    'peak_memory_bytes': peakMemoryBytes,
    'final_verification_ms': finalVerificationTimeMs,
  };

  @override
  String toString() {
    return 'TransferPerformanceMetrics('
        'files: $totalFiles, bytes: $totalBytes, '
        'reqCreation: ${requestCreationTimeMs.toStringAsFixed(2)}ms, '
        'connEst: ${connectionEstablishmentTimeMs.toStringAsFixed(2)}ms, '
        'recvNotify: ${receiverNotificationLatencyMs.toStringAsFixed(2)}ms, '
        'userAccept: ${userAcceptanceLatencyMs.toStringAsFixed(2)}ms, '
        'firstByte: ${firstByteLatencyMs.toStringAsFixed(2)}ms, '
        'throughput: ${transferThroughputMBs.toStringAsFixed(2)} MB/s, '
        'verification: ${finalVerificationTimeMs.toStringAsFixed(2)}ms'
        ')';
  }
}

/// Stateful tracker managing instrumentation timestamps across the lifecycle.
class TransferPerformanceTracker {
  final String transferId;
  final int totalBytes;
  final int totalFiles;

  late final DateTime creationStart;
  DateTime? creationEnd;

  DateTime? connectStart;
  DateTime? connectEnd;

  DateTime? offerSentTime;
  DateTime? offerReceivedTime;

  DateTime? acceptSentTime;
  DateTime? acceptReceivedTime;

  DateTime? firstByteStreamedTime;
  DateTime? transferCompleteTime;

  DateTime? verificationStart;
  DateTime? verificationEnd;

  int _peakMemoryBytes = 0;

  TransferPerformanceTracker({
    required this.transferId,
    required this.totalBytes,
    required this.totalFiles,
  }) {
    creationStart = DateTime.now();
    _sampleMemory();
  }

  void markCreationEnd() {
    creationEnd = DateTime.now();
    _sampleMemory();
  }

  void markConnectStart() {
    connectStart = DateTime.now();
  }

  void markConnectEnd() {
    connectEnd = DateTime.now();
    _sampleMemory();
  }

  void markOfferSent() {
    offerSentTime = DateTime.now();
  }

  void markOfferReceived() {
    offerReceivedTime = DateTime.now();
    _sampleMemory();
  }

  void markAcceptSent() {
    acceptSentTime = DateTime.now();
  }

  void markAcceptReceived() {
    acceptReceivedTime = DateTime.now();
  }

  void markFirstByteStreamed() {
    firstByteStreamedTime ??= DateTime.now();
    _sampleMemory();
  }

  void markTransferComplete() {
    transferCompleteTime = DateTime.now();
    _sampleMemory();
  }

  void markVerificationStart() {
    verificationStart = DateTime.now();
  }

  void markVerificationEnd() {
    verificationEnd = DateTime.now();
    _sampleMemory();
  }

  void _sampleMemory() {
    try {
      final currentRss = ProcessInfo.currentRss;
      if (currentRss > _peakMemoryBytes) {
        _peakMemoryBytes = currentRss;
      }
    } catch (_) {}
  }

  TransferPerformanceMetrics buildMetrics() {
    final now = DateTime.now();

    final reqCreation =
        (creationEnd ?? now).difference(creationStart).inMicroseconds / 1000.0;
    final connEst = (connectStart != null && connectEnd != null)
        ? connectEnd!.difference(connectStart!).inMicroseconds / 1000.0
        : 0.0;

    // Receiver notification latency: measured from offer creation to offer arrival
    final notifyLatency = (offerSentTime != null && offerReceivedTime != null)
        ? offerReceivedTime!.difference(offerSentTime!).inMicroseconds / 1000.0
        : (offerSentTime != null
              ? (creationEnd ?? now).difference(offerSentTime!).inMicroseconds /
                    1000.0
              : 0.0);

    final userAccept = (offerSentTime != null && acceptReceivedTime != null)
        ? acceptReceivedTime!.difference(offerSentTime!).inMicroseconds / 1000.0
        : 0.0;

    final firstByte =
        (acceptReceivedTime != null && firstByteStreamedTime != null)
        ? firstByteStreamedTime!
                  .difference(acceptReceivedTime!)
                  .inMicroseconds /
              1000.0
        : 0.0;

    final durationMs =
        (firstByteStreamedTime != null && transferCompleteTime != null)
        ? transferCompleteTime!
              .difference(firstByteStreamedTime!)
              .inMilliseconds
              .toDouble()
        : 0.0;

    final throughput = (durationMs > 0 && totalBytes > 0)
        ? ((totalBytes / (1024 * 1024)) / (durationMs / 1000.0))
        : 0.0;

    final verificationMs =
        (verificationStart != null && verificationEnd != null)
        ? verificationEnd!.difference(verificationStart!).inMicroseconds /
              1000.0
        : 0.0;

    return TransferPerformanceMetrics(
      transferId: transferId,
      totalBytes: totalBytes,
      totalFiles: totalFiles,
      requestCreationTimeMs: reqCreation,
      connectionEstablishmentTimeMs: connEst,
      receiverNotificationLatencyMs: notifyLatency,
      userAcceptanceLatencyMs: userAccept,
      firstByteLatencyMs: firstByte,
      transferDurationMs: durationMs,
      transferThroughputMBs: throughput,
      peakMemoryBytes: _peakMemoryBytes,
      finalVerificationTimeMs: verificationMs,
    );
  }
}
