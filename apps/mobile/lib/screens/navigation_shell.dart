import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../widgets/receiver_approval_dialog.dart';
import 'home_screen.dart';
import 'transfers_screen.dart';
import 'history_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _currentIndex = 0;
  late NetworkController _controller;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransfersScreen(),
    HistoryScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = ref.read(networkControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNetwork();
    });
  }

  Future<void> _initNetwork() async {
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
      approvalCallback: (offer) async {
        if (!mounted) return false;
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ReceiverApprovalDialog(offer: offer),
        );
        return result ?? false;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transfers',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
