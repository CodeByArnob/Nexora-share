import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late TextEditingController _nameController;
  String _downloadDirectory = '';
  bool _isTestingFirewall = false;
  String? _firewallStatus;

  @override
  void initState() {
    super.initState();
    final device = ref.read(localDeviceProvider);
    _nameController = TextEditingController(text: device.displayName);

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      _downloadDirectory = userProfile != null
          ? '$userProfile\\Downloads\\NEXORA'
          : 'Downloads\\NEXORA';
    } else {
      final homeDir = Platform.environment['HOME'];
      _downloadDirectory = homeDir != null
          ? '$homeDir/Downloads/NEXORA'
          : 'Downloads/NEXORA';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDownloadDirectory() async {
    final selected = await FilePicker.getDirectoryPath();
    if (selected != null) {
      setState(() {
        _downloadDirectory = selected;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download folder set to: $selected')),
        );
      }
    }
  }

  Future<void> _runFirewallDiagnostics() async {
    setState(() {
      _isTestingFirewall = true;
      _firewallStatus = null;
    });

    try {
      // Test binding local ports
      final testTcp = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      await testTcp.close();

      final testUdp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      testUdp.close();

      setState(() {
        _firewallStatus =
            'SUCCESS: Network socket binding verified. Local interface allows UDP & TCP socket operations.';
        _isTestingFirewall = false;
      });
    } catch (e) {
      setState(() {
        _firewallStatus =
            'NOTICE: Socket check reported: $e. You may need to adjust your system firewall rules.';
        _isTestingFirewall = false;
      });
    }
  }

  void _copyFirewallCommands() {
    if (Platform.isLinux) {
      const cmd =
          '# UFW (Ubuntu/Debian):\n'
          'sudo ufw allow 48842/tcp comment "NEXORA File Sharing"\n'
          'sudo ufw allow 48843/udp comment "NEXORA Discovery"\n\n'
          '# Firewalld (Fedora/RHEL/openSUSE):\n'
          'sudo firewall-cmd --add-port=48842/tcp --add-port=48843/udp --permanent\n'
          'sudo firewall-cmd --reload';
      Clipboard.setData(const ClipboardData(text: cmd));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Linux firewall commands copied to clipboard.'),
        ),
      );
    } else {
      const cmd =
          'netsh advfirewall firewall add rule name="NEXORA File Sharing" dir=in action=allow protocol=TCP localport=48842\n'
          'netsh advfirewall firewall add rule name="NEXORA Discovery" dir=in action=allow protocol=UDP localport=48843';
      Clipboard.setData(const ClipboardData(text: cmd));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PowerShell firewall rules copied to clipboard.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localDevice = ref.watch(localDeviceProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Configure your Windows device identity, network storage, and firewall compatibility.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Device Identity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? NexoraColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Identity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Device Display Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        onPressed: () {
                          final updated = localDevice.copyWith(
                            displayName: _nameController.text.trim(),
                          );
                          ref.read(localDeviceProvider.notifier).state =
                              updated;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device name updated.'),
                            ),
                          );
                        },
                        child: const Text('Save Name'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Device ID: ${localDevice.deviceId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fingerprint: ${localDevice.fingerprint}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Destination Directory
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? NexoraColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Storage & Downloads',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _downloadDirectory,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.signalTeal,
                          foregroundColor: NexoraColors.midnightNavy,
                        ),
                        onPressed: _pickDownloadDirectory,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Change Location'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Appearance & Theme Mode
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? NexoraColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selected) {
                      ref.read(themeModeProvider.notifier).state =
                          selected.first;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Network Diagnostics & Firewall Troubleshooter
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? NexoraColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: NexoraColors.electricBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Platform.isLinux
                            ? 'Linux Network & Firewall Diagnostics'
                            : 'Windows Firewall Troubleshooter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Platform.isLinux
                        ? 'Local Linux firewalls (UFW, firewalld, iptables) can block peer discovery (UDP 48843) or incoming streaming connections (TCP 48842).'
                        : 'Windows Defender Firewall can sometimes block peer discovery (UDP 48843) or incoming streaming connections (TCP 48842).',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isTestingFirewall
                            ? null
                            : _runFirewallDiagnostics,
                        icon: _isTestingFirewall
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Run Port Check'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _copyFirewallCommands,
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(
                          Platform.isLinux
                              ? 'Copy Linux Firewall Rules (UFW / firewalld)'
                              : 'Copy Inbound Firewall Rules (PowerShell)',
                        ),
                      ),
                    ],
                  ),
                  if (_firewallStatus != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _firewallStatus!.startsWith('SUCCESS')
                            ? NexoraColors.signalTeal.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _firewallStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _firewallStatus!.startsWith('SUCCESS')
                              ? NexoraColors.midnightNavy
                              : Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // About NEXORA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? NexoraColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About NEXORA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'CONNECT. SHARE. ANYWHERE.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: NexoraColors.electricBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PRIVATE BY DESIGN. OPEN BY NATURE.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0 (Build 100) • Apache License 2.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developer: CodeByArnob (https://github.com/CodeByArnob)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Repository: https://github.com/CodeByArnob/Nexora-share',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Technologies: Flutter, Rust core crates, Riverpod, SQLite, SHA-256',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
