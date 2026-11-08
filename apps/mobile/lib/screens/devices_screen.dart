import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../providers/app_state.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';
import 'file_selection_screen.dart';
import 'qr_scanner_screen.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('windows')) return Icons.laptop_windows;
    if (p.contains('linux')) return Icons.terminal;
    if (p.contains('mac') || p.contains('ios')) return Icons.laptop_mac;
    return Icons.devices;
  }

  void _showDeviceDetails(BuildContext context, NexoraDevice device) {
    final formattedFp = PairingSecurityService.formatFingerprint(
      device.fingerprint,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPlatformIcon(device.platform),
              color: NexoraColors.electricBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                device.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaRow(label: 'Device ID', value: device.deviceId),
            _MetaRow(label: 'Platform', value: device.platform),
            _MetaRow(
              label: 'IP Address',
              value: device.address ?? 'Direct LAN',
            ),
            _MetaRow(
              label: 'Last Seen',
              value: device.lastSeen.toLocal().toString().split('.')[0],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cryptographic SHA-256 Fingerprint:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? NexoraColors.midnightNavy
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formattedFp,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: NexoraColors.signalTeal,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTrust(
    BuildContext context,
    WidgetRef ref,
    NexoraDevice device,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget Trusted Device?'),
        content: Text(
          'Remove "${device.displayName}" from trusted devices? Future transfer offers will require manual approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NexoraColors.errorRed,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.removeDevice(device.deviceId);
              final updated = await DatabaseService.instance
                  .getTrustedDevices();
              ref.read(trustedDevicesProvider.notifier).state = updated;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed ${device.displayName} from trusted devices.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Forget Device',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustedDevices = ref.watch(trustedDevicesProvider);
    final nearbyPeers = ref.watch(discoveredPeersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Devices & Trust Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // Section 1: Discovered Nearby Devices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Discoverable Peers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${nearbyPeers.length} Active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: NexoraColors.signalTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (nearbyPeers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? NexoraColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? NexoraColors.darkBorder
                      : NexoraColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.radar,
                    color: NexoraColors.signalTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No other NEXORA devices active on this Wi-Fi network.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...nearbyPeers.map(
              (peer) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? NexoraColors.darkBorder
                        : NexoraColors.lightBorder,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(
                      _getPlatformIcon(peer.platform),
                      color: NexoraColors.electricBlue,
                    ),
                    title: Text(
                      peer.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${peer.platform} • ${peer.address ?? 'LAN'}',
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FileSelectionScreen(targetPeer: peer),
                          ),
                        );
                      },
                      child: const Text('Send Files'),
                    ),
                    onTap: () => _showDeviceDetails(context, peer),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Section 2: Trusted Devices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trusted Devices',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${trustedDevices.length} Saved',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (trustedDevices.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: NexoraColors.signalTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: NexoraColors.signalTeal,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No trusted devices',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pair with another phone or PC via QR Optical Scan and select "Always trust this device" to enable seamless auto-transfers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Pair Device Now'),
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
            )
          else
            ...trustedDevices.map(
              (device) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPlatformIcon(device.platform),
                        color: NexoraColors.signalTeal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device.platform} • ${device.address ?? 'Saved Peer'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fingerprint: ${device.fingerprint.substring(0, 16)}...',
                            style: const TextStyle(
                              fontSize: 10,
                              color: NexoraColors.signalTeal,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'View Details',
                      onPressed: () => _showDeviceDetails(context, device),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: NexoraColors.errorRed,
                      ),
                      tooltip: 'Forget Trust',
                      onPressed: () =>
                          _confirmRemoveTrust(context, ref, device),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
