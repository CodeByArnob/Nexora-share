import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import 'transfer_completion_screen.dart';

class LiveTransferScreen extends ConsumerStatefulWidget {
  final NexoraDevice targetPeer;
  final int totalFiles;
  final int totalBytes;
  final String primaryFileName;

  const LiveTransferScreen({
    super.key,
    required this.targetPeer,
    required this.totalFiles,
    required this.totalBytes,
    required this.primaryFileName,
  });

  @override
  ConsumerState<LiveTransferScreen> createState() => _LiveTransferScreenState();
}

class _LiveTransferScreenState extends ConsumerState<LiveTransferScreen> {
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    // Periodically check if transfer completed and route to completion screen
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _checkCompletion();
    });
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    super.dispose();
  }

  void _checkCompletion() {
    final history = ref.read(transferHistoryProvider);
    final active = ref.read(activeTransfersProvider);

    // Look for matching completed transfer in history
    final completed = history
        .where(
          (t) =>
              t.remoteDeviceId == widget.targetPeer.deviceId &&
              t.state == TransferState.completed,
        )
        .firstOrNull;

    if (completed != null && active.isEmpty) {
      _watchdogTimer?.cancel();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TransferCompletionScreen(transfer: completed),
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _formatEta(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final activeTransfers = ref.watch(activeTransfersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find active transfer matching this session or use top active
    final transfer =
        activeTransfers
            .where((t) => t.remoteDeviceId == widget.targetPeer.deviceId)
            .firstOrNull ??
        (activeTransfers.isNotEmpty ? activeTransfers.first : null);

    final progress = transfer?.progressPercentage ?? 0.05;
    final isPaused = transfer?.state == TransferState.paused;
    final speed = transfer?.formattedSpeed ?? '0.0 MB/s';
    final bytesTransferred = transfer?.bytesTransferred ?? 0;
    final totalBytes = (transfer != null && transfer.totalBytes > 0)
        ? transfer.totalBytes
        : widget.totalBytes;
    final remainingBytes = (totalBytes - bytesTransferred).clamp(0, totalBytes);
    final eta = _formatEta(transfer?.etaSeconds ?? 0);
    final currentFileName = transfer?.currentFile ?? widget.primaryFileName;
    final totalFiles = transfer?.totalFiles ?? widget.totalFiles;
    final completedFiles = transfer?.completedFiles ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmCancel(context, transfer?.transferId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaused
                      ? NexoraColors.warningAmber
                      : NexoraColors.signalTeal,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPaused ? 'Transfer Paused' : 'Live Data Stream',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Transfer',
              onPressed: () => _confirmCancel(context, transfer?.transferId),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Target Device Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? NexoraColors.darkSurfaceVariant
                      : NexoraColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? NexoraColors.darkBorder
                        : NexoraColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_vert_circle,
                      color: NexoraColors.electricBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sending to ${widget.targetPeer.displayName} (${widget.targetPeer.address ?? 'LAN'})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Glowing Circular Progress Indicator
              NexoraGlowingCircularProgress(
                progress: progress,
                size: 210,
                centerLabel: '${(progress * 100).toInt()}%',
                subLabel: speed,
              ),

              const SizedBox(height: 28),

              // Current File Progress Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? NexoraColors.darkBorder
                        : NexoraColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          color: NexoraColors.electricBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentFileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'File ${completedFiles + 1} of $totalFiles',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NexoraAnimatedProgressBar(
                      progress: progress,
                      speedText: speed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Real-Time Metrics Grid (4 Stats)
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: speed,
                      color: NexoraColors.electricBlue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Transferred',
                      value: _formatBytes(bytesTransferred),
                      color: NexoraColors.signalTeal,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.data_usage,
                      label: 'Remaining',
                      value: _formatBytes(remainingBytes),
                      color: Colors.amber.shade700,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.timer_outlined,
                      label: 'Est. Time',
                      value: eta,
                      color: Colors.purple.shade400,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Controls: Pause/Resume and Cancel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPaused
                            ? NexoraColors.signalTeal
                            : NexoraColors.warningAmber,
                        side: BorderSide(
                          color: isPaused
                              ? NexoraColors.signalTeal
                              : NexoraColors.warningAmber,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(
                        isPaused ? 'Resume' : 'Pause',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: transfer != null
                          ? () {
                              HapticFeedback.lightImpact();
                              if (isPaused) {
                                ref
                                    .read(networkControllerProvider)
                                    .resumeTransfer(transfer.transferId);
                              } else {
                                ref
                                    .read(networkControllerProvider)
                                    .pauseTransfer(transfer.transferId);
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () =>
                          _confirmCancel(context, transfer?.transferId),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String? transferId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel File Transfer?'),
        content: const Text(
          'Are you sure you want to stop this transfer? In-progress chunks will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Transfer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NexoraColors.errorRed,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (transferId != null) {
                ref.read(networkControllerProvider).cancelTransfer(transferId);
              }
              Navigator.of(context).pop();
            },
            child: const Text(
              'Stop & Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
