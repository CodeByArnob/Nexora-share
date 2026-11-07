import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustedDevices = ref.watch(trustedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Devices', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: trustedDevices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No trusted devices',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When you pair with devices, you can mark them as trusted for faster subsequent transfers with verified public keys.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trustedDevices.length,
              itemBuilder: (context, index) {
                final device = trustedDevices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: NexoraColors.midnightNavy,
                      child: Icon(Icons.shield, color: NexoraColors.signalTeal),
                    ),
                    title: Text(device.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Fingerprint: ${device.fingerprint.substring(0, 16)}...',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        const PopupMenuItem(
                          value: 'revoke',
                          child: Text('Revoke Trust', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'revoke') {
                          final updated = [...trustedDevices]..removeAt(index);
                          ref.read(trustedDevicesProvider.notifier).state = updated;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
