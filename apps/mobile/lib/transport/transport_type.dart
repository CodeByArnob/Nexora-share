import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';

/// Available transport technologies in NEXORA
enum TransportType {
  /// Wi-Fi Direct (P2P): High-speed (50-150+ MB/s), router-free direct link
  wifiDirect,

  /// Wi-Fi Aware (NAN): Neighbor awareness networking, low-latency direct link
  wifiAware,

  /// Same-network TCP/IP: Fallback when both devices are on the same Wi-Fi router or hotspot
  localNetwork,

  /// Direct manual IP connection
  directIp,
}

extension TransportTypeExt on TransportType {
  String get label {
    switch (this) {
      case TransportType.wifiDirect:
        return 'Wi-Fi Direct P2P';
      case TransportType.wifiAware:
        return 'Wi-Fi Aware (NAN)';
      case TransportType.localNetwork:
        return 'Local Wi-Fi Network';
      case TransportType.directIp:
        return 'Direct IP';
    }
  }

  String get shortTag {
    switch (this) {
      case TransportType.wifiDirect:
        return 'WIFI-DIRECT';
      case TransportType.wifiAware:
        return 'WIFI-AWARE';
      case TransportType.localNetwork:
        return 'LOCAL-LAN';
      case TransportType.directIp:
        return 'DIRECT-IP';
    }
  }

  String get description {
    switch (this) {
      case TransportType.wifiDirect:
        return 'Ultra high-speed router-free direct Wi-Fi P2P';
      case TransportType.wifiAware:
        return 'Zero-configuration neighbor discovery & direct link';
      case TransportType.localNetwork:
        return 'High-speed local network transfer over existing Wi-Fi';
      case TransportType.directIp:
        return 'Point-to-point IP connection';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportType.wifiDirect:
        return Icons.bolt;
      case TransportType.wifiAware:
        return Icons.sensors;
      case TransportType.localNetwork:
        return Icons.wifi;
      case TransportType.directIp:
        return Icons.lan;
    }
  }

  Color get color {
    switch (this) {
      case TransportType.wifiDirect:
        return NexoraColors.electricBlue;
      case TransportType.wifiAware:
        return NexoraColors.signalTeal;
      case TransportType.localNetwork:
        return const Color(0xFF3DDC84);
      case TransportType.directIp:
        return const Color(0xFFF59E0B);
    }
  }

  /// Whether this transport operates completely without an external Wi-Fi router or mobile data
  bool get isRouterFree {
    return this == TransportType.wifiDirect || this == TransportType.wifiAware;
  }
}
