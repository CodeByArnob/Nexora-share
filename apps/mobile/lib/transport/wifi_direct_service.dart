import 'dart:async';
import 'package:flutter/services.dart';
import 'transport_capability.dart';

/// Representation of an Android Wi-Fi Direct (P2P) discovered peer
class WifiDirectPeer {
  final String deviceName;
  final String deviceAddress; // Hardware MAC
  final String primaryDeviceType;
  final int status; // 0=Connected, 1=Invited, 2=Failed, 3=Available, 4=Unavailable
  final bool isGroupOwner;

  const WifiDirectPeer({
    required this.deviceName,
    required this.deviceAddress,
    this.primaryDeviceType = '',
    this.status = 3,
    this.isGroupOwner = false,
  });

  factory WifiDirectPeer.fromMap(Map<dynamic, dynamic> map) {
    return WifiDirectPeer(
      deviceName: map['deviceName'] as String? ?? 'Nearby Android Device',
      deviceAddress: map['deviceAddress'] as String? ?? '',
      primaryDeviceType: map['primaryDeviceType'] as String? ?? '',
      status: (map['status'] as num?)?.toInt() ?? 3,
      isGroupOwner: map['isGroupOwner'] == true,
    );
  }

  bool get isAvailable => status == 3;
  bool get isConnected => status == 0;
}

/// Representation of an established Wi-Fi Direct connection
class WifiDirectConnectionInfo {
  final bool groupFormed;
  final bool isGroupOwner;
  final String? groupOwnerAddress; // Usually 192.168.49.1

  const WifiDirectConnectionInfo({
    required this.groupFormed,
    required this.isGroupOwner,
    this.groupOwnerAddress,
  });

  factory WifiDirectConnectionInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiDirectConnectionInfo(
      groupFormed: map['groupFormed'] == true,
      isGroupOwner: map['isGroupOwner'] == true,
      groupOwnerAddress: map['groupOwnerAddress'] as String?,
    );
  }
}

/// Representation of an autonomous Wi-Fi Direct group created on the receiver
class WifiDirectGroupInfo {
  final bool groupCreated;
  final String networkName; // SSID, e.g. DIRECT-xx-NEXORA
  final String passphrase; // WPA2 Pre-shared Key
  final String interfaceName;
  final bool isGroupOwner;

  const WifiDirectGroupInfo({
    required this.groupCreated,
    required this.networkName,
    required this.passphrase,
    this.interfaceName = 'p2p0',
    this.isGroupOwner = true,
  });

  factory WifiDirectGroupInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiDirectGroupInfo(
      groupCreated: map['groupCreated'] == true,
      networkName: map['networkName'] as String? ?? 'NEXORA-DIRECT',
      passphrase: map['passphrase'] as String? ?? '',
      interfaceName: map['interface'] as String? ?? 'p2p0',
      isGroupOwner: map['isGroupOwner'] == true,
    );
  }
}

/// Discovered peer via Bluetooth Low Energy advertisement
class BleDiscoveredPeer {
  final String deviceId;
  final String displayName;
  final String? wifiDirectMac;
  final String? bluetoothAddress;
  final int rssi;

  const BleDiscoveredPeer({
    required this.deviceId,
    required this.displayName,
    this.wifiDirectMac,
    this.bluetoothAddress,
    this.rssi = 0,
  });

  factory BleDiscoveredPeer.fromMap(Map<dynamic, dynamic> map) {
    return BleDiscoveredPeer(
      deviceId: map['deviceId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Nearby Device',
      wifiDirectMac: map['wifiDirectMac'] as String?,
      bluetoothAddress: map['bluetoothAddress'] as String?,
      rssi: (map['rssi'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Native Android Direct Transport Service Bridge
class WifiDirectService {
  static const MethodChannel _methodChannel = MethodChannel(
    'io.github.codebyarnob.nexora/direct_transport',
  );
  static const EventChannel _eventChannel = EventChannel(
    'io.github.codebyarnob.nexora/direct_transport_events',
  );

  StreamSubscription? _eventSubscription;

  final _peersController = StreamController<List<WifiDirectPeer>>.broadcast();
  final _connectionController =
      StreamController<WifiDirectConnectionInfo>.broadcast();
  final _p2pStateController = StreamController<bool>.broadcast();
  final _awareStateController = StreamController<bool>.broadcast();
  final _blePeerController = StreamController<BleDiscoveredPeer>.broadcast();

  Stream<List<WifiDirectPeer>> get onPeersChanged => _peersController.stream;
  Stream<WifiDirectConnectionInfo> get onConnectionChanged =>
      _connectionController.stream;
  Stream<bool> get onP2pStateChanged => _p2pStateController.stream;
  Stream<bool> get onAwareAvailabilityChanged => _awareStateController.stream;
  Stream<BleDiscoveredPeer> get onBlePeerDiscovered =>
      _blePeerController.stream;

  bool _isListening = false;

  void ensureListening() {
    if (_isListening) return;
    _isListening = true;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final eventType = event['eventType'] as String?;
          switch (eventType) {
            case 'peersChanged':
              final rawList = event['peers'] as List<dynamic>? ?? [];
              final peers = rawList
                  .whereType<Map<dynamic, dynamic>>()
                  .map((m) => WifiDirectPeer.fromMap(m))
                  .toList();
              if (!_peersController.isClosed) _peersController.add(peers);
              break;

            case 'connectionChanged':
              final connMap =
                  event['connection'] as Map<dynamic, dynamic>? ?? {};
              if (!_connectionController.isClosed) {
                _connectionController.add(
                  WifiDirectConnectionInfo.fromMap(connMap),
                );
              }
              break;

            case 'p2pStateChanged':
              final enabled = event['enabled'] == true;
              if (!_p2pStateController.isClosed) _p2pStateController.add(enabled);
              break;

            case 'awareAvailabilityChanged':
              final available = event['available'] == true;
              if (!_awareStateController.isClosed) {
                _awareStateController.add(available);
              }
              break;

            case 'blePeerDiscovered':
              final peerMap = event['peer'] as Map<dynamic, dynamic>? ?? {};
              if (!_blePeerController.isClosed) {
                _blePeerController.add(BleDiscoveredPeer.fromMap(peerMap));
              }
              break;
          }
        }
      },
      onError: (err) {
        // Stream listener error handled gracefully
      },
    );
  }

  /// Queries native hardware capabilities and radio states
  Future<TransportCapabilities> getCapabilities() async {
    try {
      final res = await _methodChannel.invokeMethod('getCapabilities');
      if (res is Map) {
        return TransportCapabilities.fromMap(res);
      }
    } catch (_) {}
    return const TransportCapabilities();
  }

  /// Starts scanning for nearby Wi-Fi Direct devices
  Future<bool> startDiscovery() async {
    ensureListening();
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'startWifiDirectDiscovery',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Halts Wi-Fi Direct device discovery to conserve battery
  Future<bool> stopDiscovery() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'stopWifiDirectDiscovery',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Creates an autonomous Wi-Fi Direct group (acts as receiver Group Owner)
  Future<WifiDirectGroupInfo?> createGroup() async {
    ensureListening();
    try {
      final res = await _methodChannel.invokeMethod('createWifiDirectGroup');
      if (res is Map) {
        return WifiDirectGroupInfo.fromMap(res);
      }
    } catch (_) {}
    return null;
  }

  /// Destroys the active Wi-Fi Direct group
  Future<bool> removeGroup() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'removeWifiDirectGroup',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Connects to a target peer device address (MAC)
  Future<bool> connect(String deviceAddress) async {
    ensureListening();
    try {
      final res = await _methodChannel.invokeMethod<bool>('connectWifiDirect', {
        'deviceAddress': deviceAddress,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cancels an in-flight Wi-Fi Direct connection attempt
  Future<bool> cancelConnect() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'cancelConnectWifiDirect',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Synchronously queries active Wi-Fi Direct connection info
  Future<WifiDirectConnectionInfo?> getConnectionInfo() async {
    try {
      final res = await _methodChannel.invokeMethod(
        'getWifiDirectConnectionInfo',
      );
      if (res is Map) {
        return WifiDirectConnectionInfo.fromMap(res);
      }
    } catch (_) {}
    return null;
  }

  /// Starts BLE advertisement of device presence
  Future<bool> startBleAdvertising({
    required String deviceId,
    required String displayName,
    String? wifiDirectMac,
  }) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>(
        'startBleAdvertising',
        {
          'deviceId': deviceId,
          'displayName': displayName,
          'wifiDirectMac': ?wifiDirectMac,
        },
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops BLE advertisement
  Future<bool> stopBleAdvertising() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopBleAdvertising');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Starts BLE scanning for nearby NEXORA devices
  Future<bool> startBleScanning() async {
    ensureListening();
    try {
      final res = await _methodChannel.invokeMethod<bool>('startBleScanning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stops BLE scanning
  Future<bool> stopBleScanning() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopBleScanning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Queries available free disk space on storage via native StatFs
  Future<int> getFreeDiskSpace({String? path}) async {
    try {
      final res = await _methodChannel.invokeMethod<int>('getFreeDiskSpace', {
        'path': ?path,
      });
      return res ?? (1024 * 1024 * 1024 * 10); // Default to 10 GB if unresolvable
    } catch (_) {
      return 1024 * 1024 * 1024 * 10;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    if (!_peersController.isClosed) _peersController.close();
    if (!_connectionController.isClosed) _connectionController.close();
    if (!_p2pStateController.isClosed) _p2pStateController.close();
    if (!_awareStateController.isClosed) _awareStateController.close();
    if (!_blePeerController.isClosed) _blePeerController.close();
    _isListening = false;
  }
}
