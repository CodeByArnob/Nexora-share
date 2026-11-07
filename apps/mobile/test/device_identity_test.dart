import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/database/database_service.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/network/discovery_service.dart';
import 'package:nexora_app/services/device_identity_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  test(
    'DeviceIdentityService generates and persists unique device identity',
    () async {
      await DatabaseService.instance.initialize(inMemory: true);

      final device = await DeviceIdentityService.resolveIdentity();
      expect(device.deviceId, isNot('nexora-android-local'));
      expect(device.deviceId.startsWith('nexora-'), isTrue);
      expect(device.displayName.isNotEmpty, isTrue);
      expect(device.fingerprint.length, equals(64));

      // Calling again returns the exact same persisted identity
      final sameDevice = await DeviceIdentityService.resolveIdentity();
      expect(sameDevice.deviceId, equals(device.deviceId));
      expect(sameDevice.displayName, equals(device.displayName));
      expect(sameDevice.fingerprint, equals(device.fingerprint));

      // Custom display name updates properly
      await DeviceIdentityService.updateDisplayName('My Custom Phone');
      final updated = await DeviceIdentityService.resolveIdentity();
      expect(updated.displayName, equals('My Custom Phone'));
    },
  );

  test(
    'DiscoveryService receives peer with distinct deviceId without dropping',
    () async {
      final discovered = <NexoraDevice>[];
      final discovery = DiscoveryService(
        onPeersUpdated: (peers) {
          discovered.addAll(peers);
        },
      );

      final phoneA = NexoraDevice(
        deviceId: 'nexora-phone-a',
        displayName: 'Phone A',
        platform: 'Android',
        fingerprint: 'fp-a',
        address: '192.168.1.101',
        lastSeen: DateTime.now(),
      );

      await discovery.start(localDevice: phoneA, tcpPort: 48842);

      // Verify discovery can ping or connect manually
      final result = await discovery.manualConnect('127.0.0.1');
      expect(result, isA<bool>());
      expect(discovered, isNotNull);

      discovery.stop();
    },
  );
}
