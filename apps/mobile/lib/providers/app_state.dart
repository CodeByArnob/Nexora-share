import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../transport/direct_connection_manager.dart';
import '../transport/transport_type.dart';

/// Provider for local device identity
final localDeviceProvider = StateProvider<NexoraDevice>((ref) {
  return NexoraDevice(
    deviceId: 'nexora-android-local',
    displayName: 'Pixel 9 Pro (NEXORA)',
    platform: 'Android',
    fingerprint:
        '3978f639c6b014243b0d142017243af5f7fb00112233445566778899aabbccdd',
    lastSeen: DateTime.now(),
  );
});

/// Provider for discovered nearby peers
final discoveredPeersProvider = StateProvider<List<NexoraDevice>>((ref) {
  return [];
});

/// Provider for active transfers
final activeTransfersProvider = StateProvider<List<NexoraTransfer>>((ref) {
  return [];
});

/// Provider for transfer history
final transferHistoryProvider = StateProvider<List<NexoraTransfer>>((ref) {
  return [];
});

/// Provider for trusted devices
final trustedDevicesProvider = StateProvider<List<NexoraDevice>>((ref) {
  return [];
});

/// Provider for app theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Provider for DirectConnectionManager singleton
final directConnectionManagerProvider = Provider<DirectConnectionManager>((ref) {
  final manager = DirectConnectionManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider for current direct transport type (Wi-Fi Direct, Wi-Fi Aware, Local LAN, Direct IP)
final activeTransportProvider = StateProvider<TransportType>((ref) {
  return TransportType.wifiDirect;
});

/// Provider for current connection phase
final connectionPhaseProvider = StateProvider<ConnectionPhase>((ref) {
  return ConnectionPhase.idle;
});
