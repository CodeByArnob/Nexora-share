import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';

class DeviceIdentityService {
  static const String keyDeviceId = 'device_id';
  static const String keyDisplayName = 'display_name';
  static const String keyFingerprint = 'fingerprint';

  /// Resolves or initializes the unique persistent identity of this device.
  static Future<NexoraDevice> resolveIdentity() async {
    String? deviceId = await DatabaseService.instance.getSetting(keyDeviceId);
    String? displayName = await DatabaseService.instance.getSetting(
      keyDisplayName,
    );
    String? fingerprint = await DatabaseService.instance.getSetting(
      keyFingerprint,
    );

    final platformName = _getPlatformName();

    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceId == 'nexora-android-local') {
      // Generate genuine unique UUID for this installation
      deviceId = 'nexora-${const Uuid().v4()}';
      await DatabaseService.instance.setSetting(keyDeviceId, deviceId);
    }

    if (displayName == null ||
        displayName.isEmpty ||
        displayName == 'Pixel 9 Pro (NEXORA)') {
      displayName = await _detectGenuineDeviceModel();
      await DatabaseService.instance.setSetting(keyDisplayName, displayName);
    }

    if (fingerprint == null || fingerprint.isEmpty) {
      final rawKey =
          '$deviceId-${Platform.operatingSystem}-${DateTime.now().microsecondsSinceEpoch}';
      fingerprint = sha256.convert(utf8.encode(rawKey)).toString();
      await DatabaseService.instance.setSetting(keyFingerprint, fingerprint);
    }

    final primaryIp = await getPrimaryLocalIp();

    return NexoraDevice(
      deviceId: deviceId,
      displayName: displayName,
      platform: platformName,
      fingerprint: fingerprint,
      address: primaryIp,
      lastSeen: DateTime.now(),
    );
  }

  /// Updates and persists the user-customized device display name.
  static Future<void> updateDisplayName(String newName) async {
    await DatabaseService.instance.setSetting(keyDisplayName, newName.trim());
  }

  /// Detects the actual hardware brand and model of the phone or computer.
  static Future<String> _detectGenuineDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        if (model.isNotEmpty) {
          if (brand.isNotEmpty &&
              !model.toLowerCase().contains(brand.toLowerCase())) {
            return '${_capitalize(brand)} $model';
          }
          return model;
        }
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        final name = info.computerName.trim();
        if (name.isNotEmpty) return name;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        final name = info.name.trim();
        if (name.isNotEmpty) return name;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        final name = info.computerName.trim();
        if (name.isNotEmpty) return name;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        final name = info.name.trim();
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}

    final host = Platform.localHostname;
    if (host.isNotEmpty && host != 'localhost') {
      return host;
    }
    return '${_getPlatformName()} Peer';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _getPlatformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isIOS) return 'iOS';
    return 'Desktop';
  }

  /// Returns the current active Wi-Fi, Ethernet, or Hotspot IPv4 address.
  static Future<String?> getPrimaryLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Prioritize Wi-Fi (wlan), Hotspot (ap), or Ethernet (eth, en)
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('wlan') ||
            name.contains('ap') ||
            name.contains('eth') ||
            name.contains('en')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback &&
                !addr.isLinkLocal &&
                addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }

      // Fallback: any active IPv4 non-loopback
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              !addr.isLinkLocal &&
              addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Enumerates directed subnet broadcast addresses for all active local interfaces.
  /// (e.g., 192.168.1.255 for standard Wi-Fi, 192.168.43.255 for Android Hotspot).
  static Future<List<String>> getSubnetBroadcastAddresses() async {
    final broadcastAddresses = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              !addr.isLinkLocal &&
              addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              // Direct /24 subnet broadcast
              broadcastAddresses.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
            }
          }
        }
      }
    } catch (_) {}
    return broadcastAddresses.toList();
  }
}
