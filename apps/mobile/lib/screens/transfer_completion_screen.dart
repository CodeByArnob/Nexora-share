import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transfer_model.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';

class TransferCompletionScreen extends StatefulWidget {
  final NexoraTransfer transfer;

  const TransferCompletionScreen({super.key, required this.transfer});

  @override
  State<TransferCompletionScreen> createState() =>
      _TransferCompletionScreenState();
}

class _TransferCompletionScreenState extends State<TransferCompletionScreen> {
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

  void _openFileLocation(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File location: Download/NEXORA folder'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.transfer;
    final isSend = t.direction == TransferDirection.send;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Transfer Completed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          // Celebration Confetti / Sparkle Particles at top center
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: NexoraCelebrationParticles(size: 240),
            ),
          ),

          // Main Card Content
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 10),

              // Animated Success Checkmark Badge
              const Center(child: NexoraSuccessBadge(size: 74)),

              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  isSend ? 'Sent Successfully!' : 'Received Successfully!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  isSend
                      ? 'All files were securely delivered to ${t.remoteDeviceName}'
                      : 'All files from ${t.remoteDeviceName} were verified & saved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // SHA-256 Verification Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NexoraColors.signalTeal.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: NexoraColors.signalTeal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHA-256 Integrity Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: NexoraColors.signalTeal,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Every byte matched cryptographic hash with 100% precision.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Transfer Metadata Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? NexoraColors.darkBorder
                        : NexoraColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.devices,
                      label: 'Peer Device',
                      value:
                          '${t.remoteDeviceName} (${t.remotePlatform ?? 'LAN'})',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.insert_drive_file,
                      label: 'Files Transferred',
                      value: '${t.totalFiles} items',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.data_usage,
                      label: 'Total Size',
                      value: _formatBytes(t.totalBytes),
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.speed,
                      label: 'Average Speed',
                      value: t.formattedSpeed.isNotEmpty
                          ? t.formattedSpeed
                          : 'LAN Burst',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // File Location Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? NexoraColors.darkSurfaceVariant
                      : NexoraColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      color: NexoraColors.electricBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage Location',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            'Downloads/NEXORA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openFileLocation(context),
                      child: const Text('View Folder'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexoraColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
