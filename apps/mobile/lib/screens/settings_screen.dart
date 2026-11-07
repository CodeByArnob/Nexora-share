import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDevice = ref.watch(localDeviceProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Device Identity Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'DEVICE IDENTITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Device Display Name'),
            subtitle: Text(localDevice.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final controller = TextEditingController(
                text: localDevice.displayName,
              );
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Device Name'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          ref
                              .read(localDeviceProvider.notifier)
                              .state = localDevice.copyWith(
                            displayName: controller.text.trim(),
                          );
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Device Fingerprint'),
            subtitle: Text(
              '${localDevice.fingerprint.substring(0, 24)}...',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),

          const Divider(),

          // Transfer & Storage Preferences
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'TRANSFER & STORAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Download Destination'),
            subtitle: const Text('Downloads / NEXORA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome),
            title: const Text('Auto-accept from Trusted Devices'),
            subtitle: const Text(
              'Skip explicit confirmation for verified peers',
            ),
            value: false,
            onChanged: (val) {},
          ),

          const Divider(),

          // Appearance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: PopupMenuButton<ThemeMode>(
              initialValue: themeMode,
              onSelected: (mode) {
                ref.read(themeModeProvider.notifier).state = mode;
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
                const PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Mode'),
                ),
                const PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Mode'),
                ),
              ],
            ),
          ),

          const Divider(),

          // About & Privacy
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'ABOUT NEXORA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy-First Design'),
            subtitle: Text(
              'No account, no cloud, no tracking. Direct local peer-to-peer transfers.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('0.1.0 (Phase 1 Foundation)'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Open Source License'),
            subtitle: Text('Apache License 2.0'),
          ),
        ],
      ),
    );
  }
}
