import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../network/network_controller.dart';
import '../providers/app_state.dart';
import '../services/pairing_security_service.dart';
import '../theme/nexora_theme.dart';
import 'file_selection_screen.dart';
import 'qr_scanner_screen.dart';

/// Discovery State Machine for Devices Screen
enum DiscoveryStatus {
  idle,
  scanning,
  permissionDenied,
  permissionPermanentlyDenied,
  error,
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  /// Safe helper to truncate fingerprints without throwing RangeError
  static String formatShortFingerprint(String rawFp) {
    if (rawFp.isEmpty) return 'Unverified';
    final clean = rawFp.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toUpperCase();
    if (clean.isEmpty) return 'Unverified';
    if (clean.length <= 16) return clean;
    return '${clean.substring(0, 16)}...';
  }

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarScaleAnimation;
  late Animation<double> _radarOpacityAnimation;

  DiscoveryStatus _discoveryStatus = DiscoveryStatus.idle;
  String? _errorMessage;
  Timer? _scanTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _radarScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _radarController, curve: Curves.easeOutCubic));

    _radarOpacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _radarController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndInitialScan();
    });
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.phone_android;
    if (p.contains('windows')) return Icons.laptop_windows;
    if (p.contains('linux')) return Icons.terminal;
    if (p.contains('mac') || p.contains('ios')) return Icons.laptop_mac;
    return Icons.devices;
  }

  Color _getPlatformColor(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return const Color(0xFF3DDC84);
    if (p.contains('windows')) return NexoraColors.electricBlue;
    if (p.contains('mac') || p.contains('ios')) return const Color(0xFFA2AAAD);
    if (p.contains('linux')) return const Color(0xFFFCC624);
    return NexoraColors.signalTeal;
  }

  /// Checks nearby discovery permissions on Android; starts scan if granted
  Future<void> _checkPermissionsAndInitialScan({bool request = false}) async {
    if (!Platform.isAndroid) {
      _startScan();
      return;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      Permission permissionToQuery;
      if (sdkInt >= 33) {
        permissionToQuery = Permission.nearbyWifiDevices;
      } else {
        permissionToQuery = Permission.location;
      }

      PermissionStatus status = await permissionToQuery.status;
      if (request && !status.isGranted) {
        status = await permissionToQuery.request();
      }

      if (!mounted) return;

      if (status.isGranted || status.isLimited) {
        setState(() {
          _discoveryStatus = DiscoveryStatus.idle;
          _errorMessage = null;
        });
        _startScan();
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _discoveryStatus = DiscoveryStatus.permissionPermanentlyDenied;
        });
      } else {
        setState(() {
          _discoveryStatus = DiscoveryStatus.permissionDenied;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback gracefully without crashing
        _startScan();
      }
    }
  }

  /// Starts discovery scan and triggers UDP beacon broadcasts
  void _startScan() {
    try {
      HapticFeedback.lightImpact();
      _scanTimeoutTimer?.cancel();

      setState(() {
        _discoveryStatus = DiscoveryStatus.scanning;
        _errorMessage = null;
      });

      _radarController.repeat();

      // Trigger immediate discovery broadcast beacon
      ref.read(networkControllerProvider).rescan();

      // Complete scanning state after 4 seconds of active beacons
      _scanTimeoutTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _discoveryStatus = DiscoveryStatus.idle;
          });
          _radarController.stop();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _discoveryStatus = DiscoveryStatus.error;
          _errorMessage = 'Failed to initiate network scan: $e';
        });
        _radarController.stop();
      }
    }
  }

  void _cancelScan() {
    _scanTimeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _discoveryStatus = DiscoveryStatus.idle;
      });
      _radarController.stop();
    }
  }

  void _showManualConnectDialog() {
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
              'Enter the Wi-Fi or Mobile Hotspot IP address of the peer NEXORA device:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final controller = ref.read(networkControllerProvider);
                final success = await controller.manualConnect(targetIp);
                if (mounted) {
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

  void _showDeviceDetails(NexoraDevice device) {
    final formattedFp = PairingSecurityService.formatFingerprint(
      device.fingerprint,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPlatformIcon(device.platform),
              color: _getPlatformColor(device.platform),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                device.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaRow(label: 'Device ID', value: device.deviceId),
            _MetaRow(label: 'Platform', value: device.platform),
            _MetaRow(label: 'IP Address', value: device.address ?? 'Direct LAN'),
            _MetaRow(
              label: 'Last Seen',
              value: device.lastSeen.toLocal().toString().split('.')[0],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cryptographic SHA-256 Fingerprint:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? NexoraColors.midnightNavy : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formattedFp,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: NexoraColors.signalTeal,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTrust(NexoraDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget Trusted Device?'),
        content: Text(
          'Remove "${device.displayName}" from trusted devices? Future transfer offers will require manual approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NexoraColors.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.removeDevice(device.deviceId);
              final updated = await DatabaseService.instance.getTrustedDevices();
              ref.read(trustedDevicesProvider.notifier).state = updated;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed ${device.displayName} from trusted devices.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Forget Device', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localDevice = ref.watch(localDeviceProvider);
    final nearbyPeers = ref.watch(discoveredPeersProvider);
    final trustedDevices = ref.watch(trustedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.devices, color: NexoraColors.electricBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Devices & Trust Hub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Connect by IP',
            onPressed: _showManualConnectDialog,
          ),
          IconButton(
            icon: _discoveryStatus == DiscoveryStatus.scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NexoraColors.electricBlue,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh / Rescan',
            onPressed: _startScan,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _startScan();
          await Future.delayed(const Duration(milliseconds: 1500));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Initial State Header & Device Status Banner
            _buildDeviceStatusBanner(localDevice, isDark),
            const SizedBox(height: 16),

            // 2. Main Discovery Content Section (Handling all 6 States)
            _buildDiscoverySection(nearbyPeers, isDark),
            const SizedBox(height: 24),

            // 3. Trusted Devices Section
            _buildTrustedDevicesSection(trustedDevices, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// State 1 Header: Branded Device Status Banner
  Widget _buildDeviceStatusBanner(NexoraDevice localDevice, bool isDark) {
    final isScanning = _discoveryStatus == DiscoveryStatus.scanning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isScanning
                                ? NexoraColors.signalTeal
                                : NexoraColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isScanning ? 'Discoverable & Scanning...' : 'Discoverable on Wi-Fi',
                          style: TextStyle(
                            fontSize: 12,
                            color: isScanning
                                ? NexoraColors.signalTeal
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.radar, size: 16),
                label: Text(isScanning ? 'Scanning' : 'Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NexoraColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: isScanning ? _cancelScan : _startScan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.midnightNavy : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: NexoraColors.signalTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keep both devices on the same Wi-Fi or mobile hotspot for instant P2P transfer.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Main Discovery Section: Routes between all required states
  Widget _buildDiscoverySection(List<NexoraDevice> nearbyPeers, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Discoverable Peers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NexoraColors.signalTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${nearbyPeers.length} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: NexoraColors.signalTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Route to the appropriate state view
        if (_discoveryStatus == DiscoveryStatus.permissionDenied ||
            _discoveryStatus == DiscoveryStatus.permissionPermanentlyDenied)
          _buildPermissionRequiredState(isDark)
        else if (_discoveryStatus == DiscoveryStatus.error)
          _buildErrorState(isDark)
        else if (_discoveryStatus == DiscoveryStatus.scanning && nearbyPeers.isEmpty)
          _buildScanningState(isDark)
        else if (nearbyPeers.isNotEmpty)
          _buildDevicesFoundState(nearbyPeers, isDark)
        else
          _buildNoDevicesFoundState(isDark),
      ],
    );
  }

  /// State 2: Scanning State with Animated Radar Pulse Ring
  Widget _buildScanningState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Radar pulse ring animation
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _radarScaleAnimation.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NexoraColors.signalTeal.withValues(
                              alpha: _radarOpacityAnimation.value,
                            ),
                            width: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar,
                    color: NexoraColors.signalTeal,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scanning for nearby NEXORA devices...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Broadcasting multicast discovery beacons on 224.0.0.167:48843 and subnet broadcast...',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _cancelScan,
                child: const Text('Cancel Scan'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.wifi_find, size: 16),
                label: const Text('Connect by IP'),
                onPressed: _showManualConnectDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State 3: Devices Found State (Material 3 Cards with Platform Badge, IP, and Connect Action)
  Widget _buildDevicesFoundState(List<NexoraDevice> nearbyPeers, bool isDark) {
    return Column(
      children: [
        if (_discoveryStatus == DiscoveryStatus.scanning)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NexoraColors.signalTeal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Scanning for additional devices...',
                  style: TextStyle(
                    fontSize: 12,
                    color: NexoraColors.signalTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ...nearbyPeers.map(
          (peer) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showDeviceDetails(peer),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Platform Icon Avatar with colored badge
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getPlatformColor(peer.platform).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getPlatformIcon(peer.platform),
                              color: _getPlatformColor(peer.platform),
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: NexoraColors.successGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? NexoraColors.darkSurface : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Device Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peer.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  peer.platform,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getPlatformColor(peer.platform),
                                  ),
                                ),
                                const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Expanded(
                                  child: Text(
                                    peer.address ?? 'LAN Direct',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fingerprint: ${DevicesScreen.formatShortFingerprint(peer.fingerprint)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: NexoraColors.signalTeal,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Primary Action: Send Files / Connect
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexoraColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FileSelectionScreen(targetPeer: peer),
                            ),
                          );
                        },
                        child: const Text('Send Files'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// State 4: No Devices Found State with helpful guidance and direct shortcuts
  Widget _buildNoDevicesFoundState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexoraColors.signalTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radar_outlined,
              size: 38,
              color: NexoraColors.signalTeal,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No nearby devices found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Ensure both devices are on the same Wi-Fi network or mobile hotspot, and NEXORA is open.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Scan Again'),
                onPressed: _startScan,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.wifi_find, size: 16),
                label: const Text('Connect by IP'),
                onPressed: _showManualConnectDialog,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Scan QR Code'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State 5: Permission Required State
  Widget _buildPermissionRequiredState(bool isDark) {
    final isPermanent =
        _discoveryStatus == DiscoveryStatus.permissionPermanentlyDenied;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NexoraColors.warningAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexoraColors.warningAmber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_tethering_off,
              size: 38,
              color: NexoraColors.warningAmber,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nearby Devices Permission Required',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            isPermanent
                ? 'Nearby Wi-Fi devices permission is disabled in App Settings. Please enable it to discover other NEXORA devices automatically.'
                : 'Android requires Nearby Devices permission to scan for other phones and computers on your Wi-Fi network. NEXORA never tracks your location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isPermanent)
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Open App Settings'),
                  onPressed: () async {
                    await openAppSettings();
                  },
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('Grant Permission'),
                  onPressed: () => _checkPermissionsAndInitialScan(request: true),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.wifi_find, size: 16),
                label: const Text('Connect by IP'),
                onPressed: _showManualConnectDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// State 6: Error State with User-Friendly Message and Retry Action
  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? NexoraColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NexoraColors.errorRed.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexoraColors.errorRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 38,
              color: NexoraColors.errorRed,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Discovery Encountered an Issue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ??
                'Unable to bind multicast network sockets. Ensure Wi-Fi is enabled on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry Scan'),
                onPressed: _startScan,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.wifi_find, size: 16),
                label: const Text('Connect by IP'),
                onPressed: _showManualConnectDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 3: Trusted Devices Hub with Safe Fingerprints & Details Modal
  Widget _buildTrustedDevicesSection(List<NexoraDevice> trustedDevices, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trusted Devices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${trustedDevices.length} Saved',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (trustedDevices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? NexoraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? NexoraColors.darkBorder : NexoraColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NexoraColors.signalTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 38,
                    color: NexoraColors.signalTeal,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No trusted devices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pair with another phone or PC via QR Optical Scan and select "Always trust this device" to enable seamless auto-transfers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Pair Device Now'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const QrScannerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        else
          ...trustedDevices.map(
            (device) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? NexoraColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPlatformIcon(device.platform),
                      color: NexoraColors.signalTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${device.platform} • ${device.address ?? 'Saved Peer'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fingerprint: ${DevicesScreen.formatShortFingerprint(device.fingerprint)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: NexoraColors.signalTeal,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    tooltip: 'View Details',
                    onPressed: () => _showDeviceDetails(device),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: NexoraColors.errorRed,
                    ),
                    tooltip: 'Forget Trust',
                    onPressed: () => _confirmRemoveTrust(device),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
