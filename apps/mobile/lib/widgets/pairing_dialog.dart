import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/device_model.dart';
import '../theme/nexora_theme.dart';
import '../transport/direct_connection_manager.dart';
import '../transport/transport_type.dart';

class PairingDialog extends StatelessWidget {
  final NexoraDevice localDevice;
  final String sasCode;
  final String qrData;
  final VoidCallback? onManualConnect;
  final ReceiveDirectSession? directSession;

  const PairingDialog({
    super.key,
    required this.localDevice,
    required this.sasCode,
    required this.qrData,
    this.onManualConnect,
    this.directSession,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? NexoraColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: NexoraColors.electricBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pair Device',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Text(
                          'Scan this QR code from the sender device',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Direct Transport Badge
              if (directSession != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: directSession!.transport.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: directSession!.transport.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        directSession!.transport.icon,
                        size: 14,
                        color: directSession!.transport.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        directSession!.transport.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: directSession!.transport.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (directSession!.ssid != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'P2P Group: ${directSession!.ssid}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 10),
              ],

              // Device IP pill
              if (localDevice.address != null || directSession != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NexoraColors.electricBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi,
                        size: 14,
                        color: NexoraColors.electricBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Device IP: ${directSession?.ipAddress ?? localDevice.address}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: NexoraColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0F172A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SAS Code Comparison Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? NexoraColors.darkSurfaceVariant
                      : NexoraColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Short Authentication Code (SAS)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sasCode.substring(0, 3)} - ${sasCode.substring(3)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: NexoraColors.signalTeal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Security notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Session token expires in 10 minutes • Replay Protected',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  if (onManualConnect != null)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onManualConnect,
                        child: const Text(
                          'Add by IP',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  if (onManualConnect != null) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
