import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../providers/app_state.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import 'file_selection_screen.dart';

class PairingScreen extends ConsumerStatefulWidget {
  final NexoraDevice remoteDevice;
  final String sasCode;
  final String sessionId;
  final QrPairingData? pairingData;

  const PairingScreen({
    super.key,
    required this.remoteDevice,
    required this.sasCode,
    required this.sessionId,
    this.pairingData,
  });

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  bool _alwaysTrust = false;
  bool _isSaving = false;

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('windows')) return Icons.laptop_windows;
    if (p.contains('linux')) return Icons.terminal;
    if (p.contains('mac') || p.contains('ios')) return Icons.laptop_mac;
    return Icons.devices;
  }

  Future<void> _confirmPairing() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
    });

    try {
      if (_alwaysTrust) {
        await DatabaseService.instance.upsertDevice(
          widget.remoteDevice,
          isTrusted: true,
        );
        final trusted = await DatabaseService.instance.getTrustedDevices();
        ref.read(trustedDevicesProvider.notifier).state = trusted;
      }
    } catch (_) {}

    if (!mounted) return;

    // Navigate to File Selection Screen to choose files for this paired device
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            FileSelectionScreen(targetPeer: widget.remoteDevice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localDevice = ref.watch(localDeviceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedFingerprint = PairingSecurityService.formatFingerprint(
      widget.remoteDevice.fingerprint,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Pairing & Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Top Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NexoraColors.signalTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: NexoraColors.signalTeal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cryptographic Handshake Verified',
                    style: TextStyle(
                      color: NexoraColors.signalTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Two Devices Animated Profile Cards with Connection Beam
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Local Device Card
                Expanded(
                  child: _DeviceCard(
                    title: 'This Device',
                    name: localDevice.displayName,
                    platform: localDevice.platform,
                    ip: localDevice.address ?? '127.0.0.1',
                    icon: _getPlatformIcon(localDevice.platform),
                    isLocal: true,
                    isDark: isDark,
                  ),
                ),

                // Connection Beam
                const SizedBox(
                  width: 50,
                  child: NexoraConnectionBeam(height: 36),
                ),

                // Remote Device Card
                Expanded(
                  child: _DeviceCard(
                    title: 'Target Peer',
                    name: widget.remoteDevice.displayName,
                    platform: widget.remoteDevice.platform,
                    ip: widget.remoteDevice.address ?? 'Direct LAN',
                    icon: _getPlatformIcon(widget.remoteDevice.platform),
                    isLocal: false,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // SAS Code Comparison Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? NexoraColors.darkSurfaceVariant
                    : NexoraColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: NexoraColors.electricBlue.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Short Authentication String (SAS)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? NexoraColors.midnightNavy : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: NexoraColors.signalTeal.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '${widget.sasCode.substring(0, 3)} - ${widget.sasCode.substring(3)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: NexoraColors.electricBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confirm that this exact 6-digit code matches on both screens to eliminate man-in-the-middle attacks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Security Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? NexoraColors.darkBorder
                      : NexoraColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: NexoraColors.signalTeal,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Public Key Fingerprint',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF090D18)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formattedFingerprint,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: NexoraColors.signalTeal,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _SecurityPill(
                        icon: Icons.timer_outlined,
                        label: 'Expires in 10m',
                        color: NexoraColors.electricBlue,
                      ),
                      const SizedBox(width: 8),
                      _SecurityPill(
                        icon: Icons.lock_outline,
                        label: 'Replay Protected',
                        color: NexoraColors.signalTeal,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Always Trust Device Switch
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text(
                'Always trust this device',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Automatically approve future transfer requests from this peer.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _alwaysTrust,
              activeThumbColor: NexoraColors.signalTeal,
              onChanged: (val) {
                setState(() {
                  _alwaysTrust = val;
                });
              },
            ),

            const SizedBox(height: 24),

            // Confirm & Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: NexoraColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text(
                  'Confirm & Select Files',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _confirmPairing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String title;
  final String name;
  final String platform;
  final String ip;
  final IconData icon;
  final bool isLocal;
  final bool isDark;

  const _DeviceCard({
    required this.title,
    required this.name,
    required this.platform,
    required this.ip,
    required this.icon,
    required this.isLocal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocal
              ? NexoraColors.electricBlue.withValues(alpha: 0.4)
              : NexoraColors.signalTeal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isLocal
                          ? NexoraColors.electricBlue
                          : NexoraColors.signalTeal)
                      .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isLocal
                  ? NexoraColors.electricBlue
                  : NexoraColors.signalTeal,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLocal
                  ? NexoraColors.electricBlue
                  : NexoraColors.signalTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            ip,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SecurityPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SecurityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
