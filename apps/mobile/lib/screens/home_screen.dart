import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import '../widgets/pairing_dialog.dart';

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
              'Enter the Wi-Fi or Hotspot IP address of the other NEXORA phone (shown on their home screen):',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDevice = ref.watch(localDeviceProvider);
    final nearbyPeers = ref.watch(discoveredPeersProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);
    final history = ref.watch(transferHistoryProvider);
    final controller = ref.read(networkControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: NexoraColors.midnightNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: NexoraColors.electricBlue,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: NexoraColors.signalTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'NEXORA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
            tooltip: 'Pair Device (QR & Code)',
            onPressed: () {
              final qrPayload = jsonEncode({
                'version': 1,
                'device_id': localDevice.deviceId,
                'display_name': localDevice.displayName,
                'platform': localDevice.platform,
                'fingerprint': localDevice.fingerprint,
                'address': localDevice.address,
                'port': controller.tcpPort,
              });
              showDialog(
                context: context,
                builder: (context) => PairingDialog(
                  localDevice: localDevice,
                  sasCode: '482910',
                  qrData: qrPayload,
                  onManualConnect: () {
                    Navigator.of(context).pop();
                    _showManualConnectDialog(context, controller);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Local Device Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NexoraColors.electricBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: NexoraColors.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localDevice.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                      : 'Local Network Discovery Active',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
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
            ),

            const SizedBox(height: 16),

            // Quick Actions: Send & Receive
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexoraColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text(
                      'Send Files',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (nearbyPeers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No nearby NEXORA peers detected yet. Wait for discovery or Connect by IP.',
                            ),
                          ),
                        );
                      } else {
                        // Pick first peer or show selector
                        controller.pickAndSendFile(
                          context: context,
                          targetPeer: nearbyPeers.first,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexoraColors.electricBlue,
                      side: const BorderSide(
                        color: NexoraColors.electricBlue,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'Receive Files',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Receiver active. Waiting for incoming transfer offer...',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Active Transfer Summary if any
            if (activeTransfers.isNotEmpty) ...[
              const Text(
                'Active Transfers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...activeTransfers.map(
                (t) => Card(
                  child: ListTile(
                    leading: Icon(
                      t.direction == TransferDirection.send
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: NexoraColors.electricBlue,
                    ),
                    title: Text(t.remoteDeviceName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.currentFile} • ${t.formattedSpeed}'),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: t.progressPercentage),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nearby Devices Header
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
                      icon: const Icon(Icons.add_link, size: 16),
                      label: const Text('Add IP'),
                      onPressed: () =>
                          _showManualConnectDialog(context, controller),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Scanning'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (nearbyPeers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.wifi_tethering,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Searching for nearby NEXORA devices',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ensure both devices are on the same Wi-Fi network or mobile hotspot, and have NEXORA open.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.wifi_find, size: 18),
                        label: const Text('Connect Directly by IP Address'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NexoraColors.electricBlue,
                        ),
                        onPressed: () =>
                            _showManualConnectDialog(context, controller),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...nearbyPeers.map(
                (peer) => Card(
                  child: ListTile(
                    leading: NexoraPulseRing(
                      child: CircleAvatar(
                        backgroundColor: NexoraColors.midnightNavy,
                        child: Icon(
                          peer.platform.toLowerCase().contains('android')
                              ? Icons.phone_android
                              : peer.platform.toLowerCase().contains('linux')
                              ? Icons.terminal
                              : Icons.laptop_windows,
                          color: NexoraColors.signalTeal,
                        ),
                      ),
                    ),
                    title: Text(
                      peer.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${peer.platform} • ${peer.address ?? 'Direct'}',
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.electricBlue,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send'),
                      onPressed: () {
                        controller.pickAndSendFile(
                          context: context,
                          targetPeer: peer,
                        );
                      },
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Recent Activity Section
            const Text(
              'Recent Activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (history.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent transfers yet.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else
              ...history
                  .take(3)
                  .map(
                    (item) => Card(
                      child: ListTile(
                        leading: Icon(
                          item.direction == TransferDirection.send
                              ? Icons.upload
                              : Icons.download,
                          color: NexoraColors.signalTeal,
                        ),
                        title: Text(item.remoteDeviceName),
                        subtitle: Text(
                          '${item.totalFiles} files • ${item.createdAt.toLocal().toString().split('.')[0]}',
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: NexoraColors.signalTeal,
                          size: 20,
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
