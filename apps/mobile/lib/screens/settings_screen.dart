import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

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
          ListTile(
            leading: const Icon(Icons.security, color: NexoraColors.signalTeal),
            title: const Text('Privacy-First Design'),
            subtitle: const Text(
              'PRIVATE BY DESIGN. OPEN BY NATURE.\nDirect local peer-to-peer transfers with zero cloud intermediaries.',
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: NexoraColors.electricBlue,
            ),
            title: const Text('Version & Build'),
            subtitle: const Text('Version 1.0.0 (Build 100) — Release Stable'),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: NexoraColors.signalTeal,
            ),
            title: const Text('Developer'),
            subtitle: const Text(
              'CodeByArnob (https://github.com/CodeByArnob)',
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.source_outlined,
              color: NexoraColors.electricBlue,
            ),
            title: const Text('Open Source Repository'),
            subtitle: const Text('https://github.com/CodeByArnob/Nexora-share'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.grey),
            title: const Text('License & Technologies'),
            subtitle: const Text(
              'Apache 2.0 • Flutter, Rust, Riverpod, SQLite, SHA-256',
            ),
          ),
        ],
      ),
    );
  }
}
