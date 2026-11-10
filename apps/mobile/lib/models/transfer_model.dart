enum TransferDirection { send, receive }

enum TransferState {
  pending,
  connecting,
  offered,
  awaitingAcceptance,
  accepted,
  inProgress,
  verifying,
  paused,
  resuming,
  completed,
  cancelled,
  cancelRequested,
  rejected,
  interrupted,
  failed;

  bool get isActive =>
      this == TransferState.pending ||
      this == TransferState.connecting ||
      this == TransferState.offered ||
      this == TransferState.awaitingAcceptance ||
      this == TransferState.accepted ||
      this == TransferState.inProgress ||
      this == TransferState.verifying ||
      this == TransferState.paused ||
      this == TransferState.resuming ||
      this == TransferState.cancelRequested;

  bool get isTerminal => !isActive;

  String get displayName {
    switch (this) {
      case TransferState.pending:
        return 'Pending';
      case TransferState.connecting:
        return 'Connecting';
      case TransferState.offered:
      case TransferState.awaitingAcceptance:
        return 'Awaiting Acceptance';
      case TransferState.accepted:
        return 'Accepted';
      case TransferState.inProgress:
        return 'Transferring';
      case TransferState.verifying:
        return 'Verifying';
      case TransferState.paused:
        return 'Paused';
      case TransferState.resuming:
        return 'Resuming';
      case TransferState.completed:
        return 'Completed';
      case TransferState.cancelled:
        return 'Cancelled';
      case TransferState.cancelRequested:
        return 'Cancelling';
      case TransferState.rejected:
        return 'Rejected';
      case TransferState.interrupted:
        return 'Interrupted';
      case TransferState.failed:
        return 'Failed';
    }
  }
}

class NexoraTransfer {
  final String transferId;
  final TransferDirection direction;
  final String remoteDeviceId;
  final String remoteDeviceName;
  final String? remotePlatform;
  final int totalFiles;
  final int completedFiles;
  final int totalBytes;
  final int bytesTransferred;
  final double speedBytesPerSec;
  final int etaSeconds;
  final String currentFile;
  final TransferState state;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  const NexoraTransfer({
    required this.transferId,
    required this.direction,
    required this.remoteDeviceId,
    required this.remoteDeviceName,
    this.remotePlatform,
    required this.totalFiles,
    this.completedFiles = 0,
    required this.totalBytes,
    this.bytesTransferred = 0,
    this.speedBytesPerSec = 0.0,
    this.etaSeconds = 0,
    this.currentFile = '',
    this.state = TransferState.pending,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  /// Real mathematical progress calculation: 0 B transferred returns strictly 0.0
  double get progressPercentage {
    if (totalBytes <= 0 || bytesTransferred <= 0) return 0.0;
    return (bytesTransferred / totalBytes).clamp(0.0, 1.0);
  }

  bool get isCompleted => state == TransferState.completed;
  bool get isCancelled => state == TransferState.cancelled;
  bool get isFailed =>
      state == TransferState.failed ||
      state == TransferState.interrupted ||
      state == TransferState.rejected;
  bool get isActive => state.isActive;

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
    String? remotePlatform,
    int? totalFiles,
    int? completedFiles,
    int? totalBytes,
    int? bytesTransferred,
    double? speedBytesPerSec,
    int? etaSeconds,
    String? currentFile,
    TransferState? state,
    String? failureReason,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return NexoraTransfer(
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
      remoteDeviceName: remoteDeviceName ?? this.remoteDeviceName,
      remotePlatform: remotePlatform ?? this.remotePlatform,
      totalFiles: totalFiles ?? this.totalFiles,
      completedFiles: completedFiles ?? this.completedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      currentFile: currentFile ?? this.currentFile,
      state: state ?? this.state,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
