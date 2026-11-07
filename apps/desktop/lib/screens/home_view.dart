import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';
import '../widgets/nexora_motion.dart';
import '../widgets/pairing_dialog.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final localDevice = ref.watch(localDeviceProvider);
    final discoveredPeers = ref.watch(discoveredPeersProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);
    final history = ref.watch(transferHistoryProvider);
    final networkController = ref.watch(networkControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome / Identity Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NexoraColors.midnightNavy, NexoraColors.darkSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NexoraColors.electricBlue,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: NexoraColors.signalTeal,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'NEXORA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: NexoraColors.signalTeal.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: NexoraColors.signalTeal,
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.wifi,
                                    size: 14,
                                    color: NexoraColors.signalTeal,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Online & Discoverable',
                                    style: TextStyle(
                                      color: NexoraColors.signalTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${localDevice.displayName} • TCP Port ${networkController.tcpPort}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fingerprint: ${localDevice.fingerprint.substring(0, 16)}...',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NexoraColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PairingDialog(
                          localDevice: localDevice,
                          sasCode: '749-183',
                          qrData:
                              'nexora://${localDevice.deviceId}?fp=${localDevice.fingerprint}&p=${networkController.tcpPort}',
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    label: const Text('Show Pairing Code'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Actions: Send & Receive
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(activeNavSectionProvider.notifier).state =
                          DesktopNavSection.send;
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            NexoraColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NexoraColors.electricBlue.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: NexoraColors.electricBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send Files',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pick files or drop to transfer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(activeNavSectionProvider.notifier).state =
                          DesktopNavSection.receive;
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            NexoraColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NexoraColors.signalTeal.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: NexoraColors.signalTeal,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Receive Files',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ready for incoming streams',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Nearby Discovered Devices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${discoveredPeers.length} online',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (discoveredPeers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      NexoraColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.radar, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Searching for nearby NEXORA devices...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ensure other devices have NEXORA open on the same local Wi-Fi or subnet.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 96,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: discoveredPeers.length,
                itemBuilder: (context, index) {
                  final peer = discoveredPeers[index];
                  final pLower = peer.platform.toLowerCase();
                  final isAndroid = pLower.contains('android');
                  final isLinux = pLower.contains('linux');
                  final iconData = isAndroid
                      ? Icons.phone_android
                      : (isLinux ? Icons.terminal : Icons.laptop_windows);
                  final avatarColor = isAndroid
                      ? NexoraColors.signalTeal
                      : (isLinux
                            ? Colors.purpleAccent
                            : NexoraColors.electricBlue);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          NexoraColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        NexoraPulseRing(
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: avatarColor.withValues(
                              alpha: 0.15,
                            ),
                            child: Icon(iconData, color: avatarColor),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                peer.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${peer.platform} • ${peer.address ?? "local"}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.send_rounded, size: 18),
                          onPressed: () {
                            networkController.pickAndSendFile(
                              context: context,
                              targetPeer: peer,
                            );
                          },
                          tooltip: 'Send File to ${peer.displayName}',
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // Active Transfer Summary or Recent Activity
            if (activeTransfers.isNotEmpty) ...[
              const Text(
                'Active Transfers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...activeTransfers.map((transfer) {
                final progressPct = transfer.totalBytes > 0
                    ? (transfer.transferredBytes / transfer.totalBytes).clamp(
                        0.0,
                        1.0,
                      )
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardTheme.color ??
                        NexoraColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: NexoraColors.electricBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            transfer.direction == TransferDirection.receive
                                ? Icons.downloading
                                : Icons.upload,
                            color: NexoraColors.electricBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              transfer.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(progressPct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPct,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(
                          NexoraColors.electricBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatBytes(transfer.transferredBytes)} / ${_formatBytes(transfer.totalBytes)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${_formatBytes(transfer.bytesPerSecond.round())}/s',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardTheme.color ??
                        NexoraColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No recent transfers yet. Transferred files will appear here with cryptographic integrity verification.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...history.take(3).map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          NexoraColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle,
                        color: NexoraColors.signalTeal,
                      ),
                      title: Text(
                        item.fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_formatBytes(item.totalBytes)} • Verified SHA-256',
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
