import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../network/network_controller.dart';
import '../theme/nexora_theme.dart';
import 'live_transfer_screen.dart';

class TransferConfirmationScreen extends ConsumerStatefulWidget {
  final NexoraDevice targetPeer;
  final List<File> files;
  final int totalBytes;

  const TransferConfirmationScreen({
    super.key,
    required this.targetPeer,
    required this.files,
    required this.totalBytes,
  });

  @override
  ConsumerState<TransferConfirmationScreen> createState() =>
      _TransferConfirmationScreenState();
}

class _TransferConfirmationScreenState
    extends ConsumerState<TransferConfirmationScreen> {
  bool _isSending = false;

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

  Future<void> _startTransmission() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSending = true;
    });

    final controller = ref.read(networkControllerProvider);

    // Trigger sending via network controller
    controller.sendFiles(peer: widget.targetPeer, files: widget.files);

    // Allow slight frame delay for active transfer to register in app_state
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    // Navigate to Live Transfer Screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LiveTransferScreen(
          targetPeer: widget.targetPeer,
          totalFiles: widget.files.length,
          totalBytes: widget.totalBytes,
          primaryFileName: widget.files.first.path
              .split(Platform.pathSeparator)
              .last,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfer Confirmation',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Receiver Profile Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? NexoraColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.electricBlue.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: NexoraColors.electricBlue.withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.targetPeer.platform.toLowerCase().contains(
                                'android',
                              )
                              ? Icons.phone_android
                              : widget.targetPeer.platform
                                    .toLowerCase()
                                    .contains('windows')
                              ? Icons.laptop_windows
                              : widget.targetPeer.platform
                                    .toLowerCase()
                                    .contains('linux')
                              ? Icons.terminal
                              : Icons.devices,
                          color: NexoraColors.electricBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recipient Device',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.targetPeer.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NexoraColors.signalTeal.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.targetPeer.platform,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: NexoraColors.signalTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.targetPeer.address ?? 'Direct LAN',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Summary Stats Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? NexoraColors.darkSurfaceVariant
                        : NexoraColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? NexoraColors.darkBorder
                          : NexoraColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Total Files',
                        value: '${widget.files.length}',
                        color: NexoraColors.electricBlue,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      _StatColumn(
                        label: 'Total Payload',
                        value: _formatBytes(widget.totalBytes),
                        color: NexoraColors.signalTeal,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const _StatColumn(
                        label: 'Security',
                        value: 'SHA-256',
                        color: NexoraColors.successGreen,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Selected Files Preview List
                Text(
                  'Payload Manifest (${widget.files.length} items)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),

                ...widget.files.map((file) {
                  final name = file.path.split(Platform.pathSeparator).last;
                  int size = 0;
                  try {
                    size = file.lengthSync();
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? NexoraColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? NexoraColors.darkBorder
                            : NexoraColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          color: NexoraColors.electricBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatBytes(size),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Prominent Send Now Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? NexoraColors.darkBorder
                      : NexoraColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexoraColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text(
                    'Send Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSending ? null : _startTransmission,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
