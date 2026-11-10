import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/transport/direct_connection_manager.dart';
import 'package:nexora_app/transport/transport_capability.dart';
import 'package:nexora_app/transport/transport_type.dart';
import 'package:nexora_app/transport/wifi_direct_service.dart';

class MockWifiDirectService extends WifiDirectService {
  TransportCapabilities mockCapabilities = const TransportCapabilities(
    wifiDirectSupported: true,
    wifiAwareSupported: true,
    bleSupported: true,
    isWifiEnabled: true,
    isBleEnabled: true,
    isAwareAvailable: true,
    sdkInt: 34,
  );

  bool isGroupCreated = false;
  bool isDiscoveryStarted = false;
  bool isBleScanningStarted = false;
  bool isBleAdvertisingStarted = false;
  int mockFreeSpace = 1024 * 1024 * 1024 * 20; // 20 GB free

  final _mockPeersController =
      StreamController<List<WifiDirectPeer>>.broadcast();
  final _mockConnectionController =
      StreamController<WifiDirectConnectionInfo>.broadcast();
  final _mockBlePeerController =
      StreamController<BleDiscoveredPeer>.broadcast();

  @override
  Stream<List<WifiDirectPeer>> get onPeersChanged =>
      _mockPeersController.stream;

  @override
  Stream<WifiDirectConnectionInfo> get onConnectionChanged =>
      _mockConnectionController.stream;

  @override
  Stream<BleDiscoveredPeer> get onBlePeerDiscovered =>
      _mockBlePeerController.stream;

  @override
  Future<TransportCapabilities> getCapabilities() async => mockCapabilities;

  @override
  Future<bool> startDiscovery() async {
    isDiscoveryStarted = true;
    return true;
  }

  @override
  Future<bool> stopDiscovery() async {
    isDiscoveryStarted = false;
    return true;
  }

  @override
  Future<WifiDirectGroupInfo?> createGroup() async {
    isGroupCreated = true;
    return const WifiDirectGroupInfo(
      groupCreated: true,
      networkName: 'DIRECT-Nexora-Fast',
      passphrase: 'passphrase1234',
      interfaceName: 'p2p0',
      isGroupOwner: true,
    );
  }

  @override
  Future<bool> removeGroup() async {
    isGroupCreated = false;
    return true;
  }

  @override
  Future<bool> connect(String deviceAddress) async {
    // Simulate async connection info emission
    Future.microtask(() {
      _mockConnectionController.add(
        const WifiDirectConnectionInfo(
          groupFormed: true,
          isGroupOwner: false,
          groupOwnerAddress: '192.168.49.1',
        ),
      );
    });
    return true;
  }

  @override
  Future<bool> startBleAdvertising({
    required String deviceId,
    required String displayName,
    String? wifiDirectMac,
  }) async {
    isBleAdvertisingStarted = true;
    return true;
  }

  @override
  Future<bool> stopBleAdvertising() async {
    isBleAdvertisingStarted = false;
    return true;
  }

  @override
  Future<bool> startBleScanning() async {
    isBleScanningStarted = true;
    return true;
  }

  @override
  Future<bool> stopBleScanning() async {
    isBleScanningStarted = false;
    return true;
  }

  @override
  Future<int> getFreeDiskSpace({String? path}) async => mockFreeSpace;

  void emitPeers(List<WifiDirectPeer> peers) {
    _mockPeersController.add(peers);
  }

  void emitBlePeer(BleDiscoveredPeer peer) {
    _mockBlePeerController.add(peer);
  }

  @override
  void dispose() {
    _mockPeersController.close();
    _mockConnectionController.close();
    _mockBlePeerController.close();
    super.dispose();
  }
}

void main() {
  group('Transport Capabilities & Selection Tests', () {
    test('TransportCapabilities prefers Wi-Fi Direct when available', () {
      const caps = TransportCapabilities(
        wifiDirectSupported: true,
        wifiAwareSupported: true,
        bleSupported: true,
        isWifiEnabled: true,
        isBleEnabled: true,
        isAwareAvailable: true,
        sdkInt: 34,
      );

      expect(caps.optimalTransport, equals(TransportType.wifiDirect));
      expect(caps.canUseBleDiscovery, isTrue);
      expect(caps.isAndroid13OrHigher, isTrue);
    });

    test('TransportCapabilities falls back to Wi-Fi Aware if P2P unsupported', () {
      const caps = TransportCapabilities(
        wifiDirectSupported: false,
        wifiAwareSupported: true,
        bleSupported: true,
        isWifiEnabled: true,
        isBleEnabled: true,
        isAwareAvailable: true,
        sdkInt: 34,
      );

      expect(caps.optimalTransport, equals(TransportType.wifiAware));
    });

    test('TransportCapabilities falls back to Local Network if direct radios disabled', () {
      const caps = TransportCapabilities(
        wifiDirectSupported: true,
        wifiAwareSupported: true,
        bleSupported: false,
        isWifiEnabled: false,
        isBleEnabled: false,
        isAwareAvailable: false,
        sdkInt: 31,
      );

      expect(caps.optimalTransport, equals(TransportType.localNetwork));
      expect(caps.isAndroid13OrHigher, isFalse);
    });
  });

  group('DirectConnectionManager Orchestration Tests', () {
    late MockWifiDirectService mockService;
    late DirectConnectionManager manager;

    setUp(() {
      mockService = MockWifiDirectService();
      manager = DirectConnectionManager(service: mockService);
    });

    tearDown(() {
      manager.dispose();
    });

    test('DirectConnectionManager initializes and detects optimal transport', () async {
      await manager.initialize();
      expect(manager.capabilities.wifiDirectSupported, isTrue);
      expect(manager.activeTransport, equals(TransportType.wifiDirect));
      expect(manager.currentPhase, equals(ConnectionPhase.idle));
    });

    test('prepareReceiveMode creates autonomous group with standard P2P IP 192.168.49.1', () async {
      await manager.initialize();
      final localDevice = NexoraDevice(
        deviceId: 'local-test-dev',
        displayName: 'Pixel 9 Pro',
        platform: 'Android',
        fingerprint: 'abcdef123456',
        lastSeen: DateTime.now(),
      );

      final session = await manager.prepareReceiveMode(
        localDevice: localDevice,
        tcpPort: 48842,
      );

      expect(session.transport, equals(TransportType.wifiDirect));
      expect(session.ipAddress, equals('192.168.49.1'));
      expect(session.ssid, equals('DIRECT-Nexora-Fast'));
      expect(session.passphrase, equals('passphrase1234'));
      expect(mockService.isGroupCreated, isTrue);
      expect(mockService.isBleAdvertisingStarted, isTrue);
      expect(manager.currentPhase, equals(ConnectionPhase.groupFormed));
    });

    test('startUnifiedDiscovery engages Wi-Fi Direct and BLE scanning simultaneously', () async {
      await manager.initialize();
      final localDevice = NexoraDevice(
        deviceId: 'local-test-dev',
        displayName: 'Pixel 9 Pro',
        platform: 'Android',
        fingerprint: 'abcdef123456',
        lastSeen: DateTime.now(),
      );

      await manager.startUnifiedDiscovery(localDevice: localDevice);

      expect(manager.currentPhase, equals(ConnectionPhase.discovering));
      expect(mockService.isDiscoveryStarted, isTrue);
      expect(mockService.isBleScanningStarted, isTrue);

      await manager.stopUnifiedDiscovery();
      expect(mockService.isDiscoveryStarted, isFalse);
      expect(mockService.isBleScanningStarted, isFalse);
      expect(manager.currentPhase, equals(ConnectionPhase.idle));
    });

    test('connectDirect resolves Group Owner IP for Wi-Fi Direct peer', () async {
      await manager.initialize();
      final p2pPeer = NexoraDevice(
        deviceId: 'p2p-12:34:56:78:9A:BC',
        displayName: 'Receiver Galaxy S24',
        platform: 'Android (Wi-Fi Direct)',
        transportHint: 'WIFI-DIRECT',
        lastSeen: DateTime.now(),
      );

      final resolvedIp = await manager.connectDirect(targetPeer: p2pPeer);
      expect(resolvedIp, equals('192.168.49.1'));
      expect(manager.currentPhase, equals(ConnectionPhase.connected));
    });

    test('checkFreeStorageSpace checks available disk space accurately', () async {
      await manager.initialize();
      mockService.mockFreeSpace = 1024 * 1024 * 1024 * 5; // 5 GB
      final space = await manager.checkFreeStorageSpace();
      expect(space, equals(1024 * 1024 * 1024 * 5));
    });

    test('teardownSession cleanly releases Wi-Fi Direct groups and restores idle state', () async {
      await manager.initialize();
      final localDevice = NexoraDevice(
        deviceId: 'local-test-dev',
        displayName: 'Pixel 9 Pro',
        platform: 'Android',
        fingerprint: 'abcdef123456',
        lastSeen: DateTime.now(),
      );

      await manager.prepareReceiveMode(
        localDevice: localDevice,
        tcpPort: 48842,
      );
      expect(mockService.isGroupCreated, isTrue);

      await manager.teardownSession();
      expect(mockService.isGroupCreated, isFalse);
      expect(manager.currentPhase, equals(ConnectionPhase.idle));
    });
  });
}
