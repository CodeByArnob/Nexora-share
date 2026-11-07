import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';

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
