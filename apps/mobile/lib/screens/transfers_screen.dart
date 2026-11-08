import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import 'qr_scanner_screen.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTransfers = ref.watch(activeTransfersProvider);
    final history = ref.watch(transferHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Transfers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: activeTransfers.isEmpty
          ? _EmptyTransfersView(hasHistory: history.isNotEmpty)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: activeTransfers.length,
              itemBuilder: (context, index) {
                final t = activeTransfers[index];
                return _NexoraActiveTransferCard(
                  key: ValueKey(t.transferId),
                  transfer: t,
                  onPause: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(networkControllerProvider)
                        .pauseTransfer(t.transferId);
                  },
                  onResume: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(networkControllerProvider)
                        .resumeTransfer(t.transferId);
                  },
                  onCancel: () {
                    HapticFeedback.mediumImpact();
                    _showCancelDialog(context, ref, t);
                  },
                );
              },
            ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    NexoraTransfer t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: Text(
          'Stop transfer with ${t.remoteDeviceName}? Active stream will terminate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NexoraColors.errorRed,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(networkControllerProvider).cancelTransfer(t.transferId);
            },
            child: const Text(
              'Cancel Transfer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransfersView extends StatelessWidget {
  final bool hasHistory;

  const _EmptyTransfersView({required this.hasHistory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: NexoraColors.electricBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 52,
                color: NexoraColors.electricBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No active transfers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'All peer streams are idle. Start a new transfer by tapping "Scan & Send" or choosing a nearby device from Home.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan & Send'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NexoraActiveTransferCard extends StatelessWidget {
  final NexoraTransfer transfer;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _NexoraActiveTransferCard({
    super.key,
    required this.transfer,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaused = transfer.state == TransferState.paused;
    final isSend = transfer.direction == TransferDirection.send;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaused
              ? NexoraColors.warningAmber.withValues(alpha: 0.5)
              : NexoraColors.electricBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: NexoraColors.electricBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NexoraColors.electricBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSend
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: NexoraColors.electricBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.remoteDeviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isSend ? 'Sending Payload' : 'Receiving Stream',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaused
                      ? NexoraColors.warningAmber.withValues(alpha: 0.15)
                      : NexoraColors.signalTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPaused ? 'PAUSED' : transfer.formattedSpeed,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPaused
                        ? NexoraColors.warningAmber
                        : NexoraColors.signalTeal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Glowing Circular Progress
          NexoraGlowingCircularProgress(
            progress: transfer.progressPercentage,
            size: 160,
            centerLabel: '${(transfer.progressPercentage * 100).toInt()}%',
            subLabel: transfer.formattedSpeed,
          ),

          const SizedBox(height: 18),

          // File Info & Linear Progress
          Text(
            transfer.currentFile,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatBytes(transfer.bytesTransferred)} / ${_formatBytes(transfer.totalBytes)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                'File ${transfer.completedFiles + 1} of ${transfer.totalFiles}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          NexoraAnimatedProgressBar(progress: transfer.progressPercentage),

          const SizedBox(height: 20),

          // Action Controls
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
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    size: 18,
                  ),
                  label: Text(isPaused ? 'Resume' : 'Pause'),
                  onPressed: isPaused ? onResume : onPause,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexoraColors.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  onPressed: onCancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
