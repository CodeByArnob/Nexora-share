import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../services/device_identity_service.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  bool _autoAcceptTrusted = true;
  String _downloadDirectory = 'Downloads/NEXORA';
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    final localDevice = ref.read(localDeviceProvider);
    _nameController = TextEditingController(text: localDevice.displayName);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      if (!DatabaseService.instance.isInitialized) return;
      final auto = await DatabaseService.instance.getSetting(
        'auto_accept_trusted',
      );
      if (auto != null && mounted) {
        setState(() {
          _autoAcceptTrusted = auto == 'true';
        });
      }
      final dl = await DatabaseService.instance.getSetting('download_path');
      if (dl != null && dl.isNotEmpty && mounted) {
        setState(() {
          _downloadDirectory = dl;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isSavingName = true;
    });

    await DeviceIdentityService.updateDisplayName(newName);
    final current = ref.read(localDeviceProvider);
    final updated = NexoraDevice(
      deviceId: current.deviceId,
      displayName: newName,
      platform: current.platform,
      fingerprint: current.fingerprint,
      address: current.address,
      lastSeen: DateTime.now(),
    );

    ref.read(localDeviceProvider.notifier).state = updated;
    ref.read(networkControllerProvider).updateLocalDevice(updated);

    setState(() {
      _isSavingName = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device name updated to "$newName"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDownloadPath() async {
    final selected = await FilePicker.getDirectoryPath();
    if (selected != null) {
      setState(() {
        _downloadDirectory = selected;
      });
      await DatabaseService.instance.setSetting('download_path', selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download directory updated to $selected')),
        );
      }
    }
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All NEXORA Data?'),
        content: const Text(
          'This will erase all transfer logs, trusted peers, and restore default preferences. Downloaded files on disk will NOT be deleted.',
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
              await DatabaseService.instance.clearHistory();
              ref.read(transferHistoryProvider.notifier).state = [];
              ref.read(trustedDevicesProvider.notifier).state = [];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('NEXORA data cleared successfully.'),
                  ),
                );
              }
            },
            child: const Text(
              'Reset Data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localDevice = ref.watch(localDeviceProvider);
    final controller = ref.watch(networkControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedFp = PairingSecurityService.formatFingerprint(
      localDevice.fingerprint,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Network',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Section 1: Device Identity
          Text(
            'DEVICE IDENTITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Display Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? NexoraColors.darkSurfaceVariant
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexoraColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSavingName ? null : _saveDisplayName,
                      child: _isSavingName
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Platform: ${localDevice.platform} • Device ID: ${localDevice.deviceId.substring(0, 16)}...',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fingerprint: $formattedFp',
                  style: const TextStyle(
                    fontSize: 10,
                    color: NexoraColors.signalTeal,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Appearance & Theme
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? NexoraColors.darkBorder
                    : NexoraColors.lightBorder,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.dark_mode_outlined,
                  color: NexoraColors.electricBlue,
                ),
                title: const Text(
                  'Theme Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
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
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Storage & Downloads
          Text(
            'TRANSFER & STORAGE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? NexoraColors.darkBorder
                    : NexoraColors.lightBorder,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.folder_open,
                      color: NexoraColors.electricBlue,
                    ),
                    title: const Text(
                      'Download Directory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _downloadDirectory,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: _pickDownloadPath,
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Auto-accept from Trusted Devices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Automatically download files sent from previously verified peers.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _autoAcceptTrusted,
                    activeThumbColor: NexoraColors.signalTeal,
                    onChanged: (val) async {
                      setState(() {
                        _autoAcceptTrusted = val;
                      });
                      await DatabaseService.instance.setSetting(
                        'auto_accept_trusted',
                        val.toString(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Network & Diagnostics
          const Text(
            'Network & Engine',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
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
                _NetworkInfoRow(
                  label: 'TCP Transfer Port',
                  value: '${controller.tcpPort}',
                ),
                const Divider(height: 16),
                _NetworkInfoRow(
                  label: 'Local IP Address',
                  value: localDevice.address ?? '127.0.0.1',
                ),
                const Divider(height: 16),
                const _NetworkInfoRow(
                  label: 'Streaming Protocol',
                  value: 'NEXORA TCP Bounded 1MB Chunks',
                ),
                const Divider(height: 16),
                const _NetworkInfoRow(
                  label: 'Integrity Engine',
                  value: 'SHA-256 Incremental Ledger',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: Maintenance & Reset
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: NexoraColors.errorRed.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.cleaning_services,
                      color: NexoraColors.errorRed,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Clear Database & History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Removes all SQLite transfer history records and trusted device relationships.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NexoraColors.errorRed,
                    side: const BorderSide(color: NexoraColors.errorRed),
                  ),
                  onPressed: _confirmResetData,
                  child: const Text('Reset All App Data'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // About NEXORA Card
          Center(
            child: Column(
              children: [
                Text(
                  'NEXORA v1.0.1 (Production Release)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Private by Design • Open by Nature • Apache 2.0',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _NetworkInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
