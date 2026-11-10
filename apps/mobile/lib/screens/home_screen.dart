import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import '../widgets/pairing_dialog.dart';
import 'file_selection_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showManualConnectDialog(
    BuildContext context,
    NetworkController controller,
  ) {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_find, color: NexoraColors.electricBlue),
            SizedBox(width: 8),
            Text('Connect by IP'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Wi-Fi or Hotspot IP address of the peer NEXORA device:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. 192.168.1.45 or 192.168.43.1',
                labelText: 'Peer IP Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetIp = ipController.text.trim();
              if (targetIp.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await controller.manualConnect(targetIp);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Connected to $targetIp successfully!'
                            : 'Discovery ping sent to $targetIp. Waiting for response...',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReceiveDialog(
    BuildContext context,
    NexoraDevice localDevice,
    int tcpPort,
    NetworkController controller,
  ) async {
    final directSession = await controller.prepareReceiveMode();
    final effectiveDevice = localDevice.copyWith(
      address: directSession.ipAddress,
      port: directSession.port,
    );
    final payload = PairingSecurityService.createPayload(
      localDevice: effectiveDevice,
      port: directSession.port,
    );
    final qrString = jsonEncode(payload.toJson());

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => PairingDialog(
        localDevice: effectiveDevice,
        sasCode: payload.sasCode,
        qrData: qrString,
        directSession: directSession,
        onManualConnect: () {
          Navigator.of(context).pop();
          _showManualConnectDialog(context, controller);
        },
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('windows')) return Icons.laptop_windows;
    if (p.contains('linux')) return Icons.terminal;
    if (p.contains('mac') || p.contains('ios')) return Icons.laptop_mac;
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDevice = ref.watch(localDeviceProvider);
    final nearbyPeers = ref.watch(discoveredPeersProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);
    final history = ref.watch(transferHistoryProvider);
    final controller = ref.read(networkControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: NexoraColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: NexoraColors.electricBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXORA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Text(
                  'Private & High-Speed File Share',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Connect by IP',
            onPressed: () => _showManualConnectDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Receive & QR Code',
            onPressed: () => _showReceiveDialog(
              context,
              localDevice,
              controller.tcpPort,
              controller,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // 1. Device Connection Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? NexoraColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? NexoraColors.darkBorder
                      : NexoraColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPlatformIcon(localDevice.platform),
                      color: NexoraColors.electricBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localDevice.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: NexoraColors.signalTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                localDevice.address != null
                                    ? 'Online • IP: ${localDevice.address}:${controller.tcpPort}'
                                    : 'Discovery Active • Port ${controller.tcpPort}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NexoraColors.signalTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: NexoraColors.signalTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Large & Eye-Catching "Scan & Send" Primary Action Card
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Scan & Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Aim camera at peer QR code for instant optical pairing and fast transfer',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Quick Action Bar: Send Files & Receive Files
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexoraColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text(
                      'Send Files',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (nearbyPeers.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FileSelectionScreen(
                              targetPeer: nearbyPeers.first,
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QrScannerScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexoraColors.signalTeal,
                      side: const BorderSide(
                        color: NexoraColors.signalTeal,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.download_rounded,
                      color: NexoraColors.signalTeal,
                      size: 20,
                    ),
                    label: const Text(
                      'Receive Files',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showReceiveDialog(
                        context,
                        localDevice,
                        controller.tcpPort,
                        controller,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Active Transfers Summary Banner if active
            if (activeTransfers.isNotEmpty) ...[
              const Text(
                'Active Transfers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...activeTransfers.map(
                (t) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? NexoraColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            t.direction == TransferDirection.send
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: NexoraColors.electricBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.remoteDeviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            t.formattedSpeed,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: NexoraColors.signalTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.currentFile,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      NexoraAnimatedProgressBar(progress: t.progressPercentage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 5. Nearby Devices Header & Radar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Devices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add IP'),
                      onPressed: () =>
                          _showManualConnectDialog(context, controller),
                    ),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NexoraColors.signalTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (nearbyPeers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
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
                    const NexoraPulseRing(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: NexoraColors.midnightNavyElevated,
                        child: Icon(
                          Icons.wifi_tethering,
                          color: NexoraColors.signalTeal,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Scanning for nearby NEXORA devices...',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ensure both devices are connected to the same Wi-Fi network or mobile hotspot and have NEXORA open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.wifi_find, size: 16),
                      label: const Text('Connect Directly by IP'),
                      onPressed: () =>
                          _showManualConnectDialog(context, controller),
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
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: NexoraColors.electricBlue.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getPlatformIcon(peer.platform),
                          color: NexoraColors.electricBlue,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        peer.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${peer.platform} • ${peer.address ?? 'LAN'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Send'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FileSelectionScreen(targetPeer: peer),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 6. Recent Transfers Section
            const Text(
              'Recent Transfers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? NexoraColors.darkBorder
                        : NexoraColors.lightBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No transfers recorded yet.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              )
            else
              ...history
                  .take(4)
                  .map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? NexoraColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? NexoraColors.darkBorder
                              : NexoraColors.lightBorder,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NexoraColors.signalTeal.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.direction == TransferDirection.send
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: NexoraColors.signalTeal,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.remoteDeviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${item.totalFiles} files • ${item.createdAt.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.check_circle_rounded,
                            color: NexoraColors.signalTeal,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
