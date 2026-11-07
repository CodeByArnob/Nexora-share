import 'device_model.dart';

enum TransferDirection { send, receive }

enum TransferState { pending, inProgress, paused, completed, failed, cancelled }

class NexoraTransfer {
  final String transferId;
  final TransferDirection direction;
  final String remoteDeviceId;
  final String remoteDeviceName;
  final int totalFiles;
  final int totalBytes;
  final int bytesTransferred;
  final double speedBytesPerSec;
  final int etaSeconds;
  final String currentFile;
  final TransferState state;
  final DateTime createdAt;
  final DateTime? completedAt;

  const NexoraTransfer({
    required this.transferId,
    required this.direction,
    required this.remoteDeviceId,
    required this.remoteDeviceName,
    required this.totalFiles,
    required this.totalBytes,
    this.bytesTransferred = 0,
    this.speedBytesPerSec = 0.0,
    this.etaSeconds = 0,
    this.currentFile = '',
    this.state = TransferState.pending,
    required this.createdAt,
    this.completedAt,
  });

  double get progressPercentage {
    if (totalBytes <= 0) return 1.0;
    return (bytesTransferred / totalBytes).clamp(0.0, 1.0);
  }

  String get fileName => currentFile;
  int get transferredBytes => bytesTransferred;
  double get bytesPerSecond => speedBytesPerSec;
  Duration? get estimatedTimeRemaining => Duration(seconds: etaSeconds);
  DateTime get startTime => createdAt;
  NexoraDevice get remoteDevice => NexoraDevice(
    deviceId: remoteDeviceId,
    displayName: remoteDeviceName,
    platform: 'Peer',
    fingerprint: 'unknown',
    lastSeen: createdAt,
  );

  String get formattedSpeed {
    if (speedBytesPerSec >= 1024 * 1024) {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (speedBytesPerSec >= 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
  }

  NexoraTransfer copyWith({
    String? transferId,
    TransferDirection? direction,
    String? remoteDeviceId,
    String? remoteDeviceName,
    int? totalFiles,
    int? totalBytes,
    int? bytesTransferred,
    double? speedBytesPerSec,
    int? etaSeconds,
    String? currentFile,
    TransferState? state,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return NexoraTransfer(
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
      remoteDeviceName: remoteDeviceName ?? this.remoteDeviceName,
      totalFiles: totalFiles ?? this.totalFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      currentFile: currentFile ?? this.currentFile,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
