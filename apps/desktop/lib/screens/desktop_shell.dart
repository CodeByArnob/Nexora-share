import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../network/network_controller.dart';
import '../network/transfer_server.dart';
import '../providers/app_state.dart';
import '../theme/nexora_theme.dart';
import '../widgets/receiver_approval_dialog.dart';
import 'devices_view.dart';
import 'history_view.dart';
import 'home_view.dart';
import 'receive_view.dart';
import 'send_view.dart';
import 'settings_view.dart';
import 'transfers_view.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  late DesktopNetworkController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(networkControllerProvider);

    // Initialize database, history, and network stack
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await DatabaseService.instance.initialize();
        final history = await DatabaseService.instance.getTransferHistory();
        if (history.isNotEmpty) {
          ref.read(transferHistoryProvider.notifier).state = history;
        }
        final trusted = await DatabaseService.instance.getTrustedDevices();
        if (trusted.isNotEmpty) {
          ref.read(trustedDevicesProvider.notifier).state = trusted;
        }
      } catch (_) {}

      _controller.initialize(
        approvalCallback: _handleIncomingApproval,
      );
    });
  }

  Future<bool> _handleIncomingApproval(IncomingTransferOffer offer) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReceiverApprovalDialog(offer: offer),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNavDestination({
    required IconData icon,
    required String label,
    required DesktopNavSection section,
    required DesktopNavSection currentSection,
    int badgeCount = 0,
  }) {
    final isSelected = currentSection == section;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected
            ? NexoraColors.electricBlue.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ref.read(activeNavSectionProvider.notifier).state = section;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? NexoraColors.electricBlue
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? NexoraColors.electricBlue
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800),
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: NexoraColors.electricBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSection = ref.watch(activeNavSectionProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);
    final localDevice = ref.watch(localDeviceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget currentView = const HomeView();
    switch (activeSection) {
      case DesktopNavSection.home:
        currentView = const HomeView();
        break;
      case DesktopNavSection.send:
        currentView = const SendView();
        break;
      case DesktopNavSection.receive:
        currentView = const ReceiveView();
        break;
      case DesktopNavSection.transfers:
        currentView = const TransfersView();
        break;
      case DesktopNavSection.history:
        currentView = const HistoryView();
        break;
      case DesktopNavSection.trustedDevices:
        currentView = const DevicesView();
        break;
      case DesktopNavSection.settings:
        currentView = const SettingsView();
        break;
    }

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : NexoraColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: NexoraColors.midnightNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: NexoraColors.signalTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXORA',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'CONNECT. SHARE.',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: NexoraColors.electricBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 12),

                // Navigation Items
                _buildNavDestination(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  section: DesktopNavSection.home,
                  currentSection: activeSection,
                ),
                _buildNavDestination(
                  icon: Icons.upload_file_outlined,
                  label: 'Send',
                  section: DesktopNavSection.send,
                  currentSection: activeSection,
                ),
                _buildNavDestination(
                  icon: Icons.download_outlined,
                  label: 'Receive',
                  section: DesktopNavSection.receive,
                  currentSection: activeSection,
                ),
                _buildNavDestination(
                  icon: Icons.swap_vert_outlined,
                  label: 'Transfers',
                  section: DesktopNavSection.transfers,
                  currentSection: activeSection,
                  badgeCount: activeTransfers.length,
                ),
                _buildNavDestination(
                  icon: Icons.history_outlined,
                  label: 'History',
                  section: DesktopNavSection.history,
                  currentSection: activeSection,
                ),
                _buildNavDestination(
                  icon: Icons.verified_user_outlined,
                  label: 'Trusted Devices',
                  section: DesktopNavSection.trustedDevices,
                  currentSection: activeSection,
                ),
                _buildNavDestination(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  section: DesktopNavSection.settings,
                  currentSection: activeSection,
                ),

                const Spacer(),

                // Bottom Device Card in Sidebar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? NexoraColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: NexoraColors.signalTeal,
                          child: Icon(Icons.computer, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localDevice.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Port ${_controller.tcpPort}',
                                style: const TextStyle(color: NexoraColors.signalTeal, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main View Pane
          Expanded(
            child: currentView,
          ),
        ],
      ),
    );
  }
}
