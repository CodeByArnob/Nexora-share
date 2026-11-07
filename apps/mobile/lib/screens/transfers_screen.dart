import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTransfers = ref.watch(activeTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: activeTransfers.isEmpty
          ? const _EmptyTransfersView()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: activeTransfers.length,
              itemBuilder: (context, index) {
                final t = activeTransfers[index];
                return _NexoraActiveTransferCard(
                  key: ValueKey(t.transferId),
                  transfer: t,
                  onPause: () {
                    ref
                        .read(networkControllerProvider)
                        .pauseTransfer(t.transferId);
                  },
                  onResume: () {
                    ref
                        .read(networkControllerProvider)
                        .resumeTransfer(t.transferId);
                  },
                  onCancel: () {
                    ref
                        .read(networkControllerProvider)
                        .cancelTransfer(t.transferId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Transfer with ${t.remoteDeviceName} cancelled',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// High-Performance Animated Active Transfer Card with Motion Graphics
class _NexoraActiveTransferCard extends StatefulWidget {
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

  @override
  State<_NexoraActiveTransferCard> createState() =>
      _NexoraActiveTransferCardState();
}

class _NexoraActiveTransferCardState extends State<_NexoraActiveTransferCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.transfer.state == TransferState.inProgress) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NexoraActiveTransferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transfer.state == TransferState.inProgress &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.transfer.state != TransferState.inProgress &&
        _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'mov', '3gp', 'avi', 'webm'].contains(ext)) {
      return Icons.movie_outlined;
    } else if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
      return Icons.image_outlined;
    } else if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) {
      return Icons.audiotrack_outlined;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return Icons.folder_zip_outlined;
    } else if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transfer;
    final isSending = t.direction == TransferDirection.send;
    final isPaused = t.state == TransferState.paused;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final primaryAccent =
        isSending ? NexoraColors.electricBlue : NexoraColors.signalTeal;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha =
            (disableAnimations || isPaused) ? 0.2 : _glowAnimation.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPaused
                  ? Colors.amber.withValues(alpha: 0.3)
                  : primaryAccent.withValues(alpha: glowAlpha),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPaused ? Colors.amber : primaryAccent).withValues(
                  alpha: isPaused ? 0.05 : glowAlpha * 0.25,
                ),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Peer Info, and Speed Badge
            Row(
              children: [
                // Direction Wave Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryAccent.withValues(alpha: 0.2),
                        primaryAccent.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: primaryAccent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isSending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: primaryAccent,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Peer Name and File Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.remoteDeviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSending ? 'Sending' : 'Receiving',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(t.currentFile),
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t.currentFile.isEmpty
                                  ? 'Preparing file stream...'
                                  : t.currentFile,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Live Speed Pill
                isPaused
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Paused',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NexoraColors.signalTeal.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: NexoraColors.signalTeal.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: NexoraColors.signalTeal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.formattedSpeed,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: NexoraColors.signalTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 16),

            // Fluid Animated Gradient Progress Bar with Shimmer Dot
            _NexoraShimmerProgressBar(
              progress: t.progressPercentage,
              isSending: isSending,
              isPaused: isPaused,
            ),
            const SizedBox(height: 12),

            // Bottom Metrics and Tactile Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metrics
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(t.progressPercentage * 100).toStringAsFixed(1)}% • ${_formatBytes(t.bytesTransferred)} / ${_formatBytes(t.totalBytes)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaused
                          ? 'Transfer paused • Tap play to resume'
                          : 'ETA: ${t.etaSeconds}s • High-Speed Local Link',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPaused ? Colors.amber : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                // Action Buttons: Pause/Resume and Cancel
                Row(
                  children: [
                    // Pause / Resume Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isPaused ? widget.onResume : widget.onPause,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPaused
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: isPaused
                                  ? Colors.amber.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Icon(
                            isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            size: 20,
                            color: isPaused
                                ? Colors.amber
                                : NexoraColors.electricBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cancel / Stop Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onCancel,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Receive Location & MediaStore Gallery Badge
            if (!isSending) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 15,
                      color: NexoraColors.signalTeal,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Saved to Downloads/Nexora • Appears in Gallery automatically',
                        style: TextStyle(
                          fontSize: 11,
                          color: NexoraColors.signalTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering Gradient Progress Bar with Glow Tip
class _NexoraShimmerProgressBar extends StatefulWidget {
  final double progress;
  final bool isSending;
  final bool isPaused;

  const _NexoraShimmerProgressBar({
    required this.progress,
    required this.isSending,
    required this.isPaused,
  });

  @override
  State<_NexoraShimmerProgressBar> createState() =>
      _NexoraShimmerProgressBarState();
}

class _NexoraShimmerProgressBarState extends State<_NexoraShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0.0, 1.0);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 10,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.08),
        child: Stack(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clamped),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isPaused
                            ? [Colors.amber.shade700, Colors.amber.shade400]
                            : [
                                NexoraColors.electricBlue,
                                NexoraColors.signalTeal,
                              ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!disableAnimations && !widget.isPaused && clamped > 0.02)
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: clamped,
                    child: Transform.translate(
                      offset: Offset(
                        (MediaQuery.of(context).size.width * clamped) *
                            (_shimmerController.value * 2 - 1),
                        0,
                      ),
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
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

/// Motion Empty State with Concentric Radar Wave
class _EmptyTransfersView extends StatefulWidget {
  const _EmptyTransfersView();

  @override
  State<_EmptyTransfersView> createState() => _EmptyTransfersViewState();
}

class _EmptyTransfersViewState extends State<_EmptyTransfersView>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      final wave =
                          (_radarController.value + (index / 3.0)) % 1.0;
                      return Transform.scale(
                        scale: 1.0 + wave * 0.8,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NexoraColors.electricBlue.withValues(
                                alpha: math.max(0.0, (1.0 - wave) * 0.35),
                              ),
                              width: 1.8,
                            ),
                          ),
                        ),
                      );
                    }),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            NexoraColors.electricBlue.withValues(alpha: 0.25),
                            NexoraColors.signalTeal.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 32,
                        color: NexoraColors.electricBlue,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'No active transfers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Incoming and outgoing high-speed file streams will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
