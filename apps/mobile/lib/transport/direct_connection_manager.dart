import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';
import 'transport_capability.dart';
import 'transport_type.dart';
import 'wifi_direct_service.dart';

enum ConnectionPhase {
  idle,
  discovering,
  connecting,
  groupFormed,
  connected,
  transferring,
  disconnected,
  error,
}

class ReceiveDirectSession {
  final TransportType transport;
  final String? ssid;
  final String? passphrase;
  final String ipAddress;
  final int port;

  const ReceiveDirectSession({
    required this.transport,
    this.ssid,
    this.passphrase,
    required this.ipAddress,
    required this.port,
  });
}

class DirectConnectionManager {
  final WifiDirectService wifiDirectService;

  ConnectionPhase _currentPhase = ConnectionPhase.idle;
  ConnectionPhase get currentPhase => _currentPhase;

  TransportType _activeTransport = TransportType.wifiDirect;
  TransportType get activeTransport => _activeTransport;

  TransportCapabilities _capabilities = const TransportCapabilities();
  TransportCapabilities get capabilities => _capabilities;

  WifiDirectGroupInfo? _activeGroupInfo;
  WifiDirectGroupInfo? get activeGroupInfo => _activeGroupInfo;

  StreamSubscription? _p2pPeersSub;
  StreamSubscription? _p2pConnSub;
  StreamSubscription? _blePeersSub;

  final _phaseController = StreamController<ConnectionPhase>.broadcast();
  Stream<ConnectionPhase> get onPhaseChanged => _phaseController.stream;

  final _discoveredDirectPeers = <String, NexoraDevice>{};
  final _peersStreamController =
      StreamController<List<NexoraDevice>>.broadcast();
  Stream<List<NexoraDevice>> get onPeersUpdated =>
      _peersStreamController.stream;

  DirectConnectionManager({WifiDirectService? service})
    : wifiDirectService = service ?? WifiDirectService();

  Future<void> initialize() async {
    _capabilities = await wifiDirectService.getCapabilities();
    _activeTransport = _capabilities.optimalTransport;

    _p2pConnSub = wifiDirectService.onConnectionChanged.listen((info) {
      if (info.groupFormed) {
        _setPhase(ConnectionPhase.groupFormed);
      }
    });

    _p2pPeersSub = wifiDirectService.onPeersChanged.listen((p2pList) {
      for (final p in p2pList) {
        final id = 'p2p-${p.deviceAddress}';
        _discoveredDirectPeers[id] = NexoraDevice(
          deviceId: id,
          displayName: p.deviceName,
          platform: 'Android (Wi-Fi Direct)',
          address: p.isGroupOwner ? '192.168.49.1' : null,
          transportHint: TransportType.wifiDirect.shortTag,
          lastSeen: DateTime.now(),
        );
      }
      if (!_peersStreamController.isClosed) {
        _peersStreamController.add(_discoveredDirectPeers.values.toList());
      }
    });

    _blePeersSub = wifiDirectService.onBlePeerDiscovered.listen((blePeer) {
      final id = blePeer.deviceId.isNotEmpty
          ? blePeer.deviceId
          : 'ble-${blePeer.bluetoothAddress}';
      _discoveredDirectPeers[id] = NexoraDevice(
        deviceId: id,
        displayName: blePeer.displayName,
        platform: 'Android (BLE Assisted)',
        transportHint: TransportType.wifiDirect.shortTag,
        lastSeen: DateTime.now(),
      );
      if (!_peersStreamController.isClosed) {
        _peersStreamController.add(_discoveredDirectPeers.values.toList());
      }
    });
  }

  void _setPhase(ConnectionPhase phase) {
    _currentPhase = phase;
    if (!_phaseController.isClosed) {
      _phaseController.add(phase);
    }
  }

  /// Verifies and requests only permissions strictly necessary for the selected Android OS
  Future<bool> requestTransportPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final caps = await wifiDirectService.getCapabilities();
      _capabilities = caps;

      if (caps.isAndroid13OrHigher) {
        // Android 13+ (API 33+): Request NEARBY_WIFI_DEVICES (does NOT require Location)
        final wifiStatus = await Permission.nearbyWifiDevices.request();
        if (!wifiStatus.isGranted) return false;

        if (caps.bleSupported) {
          await [
            Permission.bluetoothScan,
            Permission.bluetoothAdvertise,
            Permission.bluetoothConnect,
          ].request();
        }
        return true;
      } else {
        // Android 12 and below: Location is required by system for Wi-Fi scanning
        final locStatus = await Permission.location.request();
        return locStatus.isGranted;
      }
    } catch (_) {
      return true;
    }
  }

  /// Starts discovery across Wi-Fi Direct and BLE
  Future<void> startUnifiedDiscovery({required NexoraDevice localDevice}) async {
    _setPhase(ConnectionPhase.discovering);
    _discoveredDirectPeers.clear();

    if (_capabilities.wifiDirectSupported) {
      await wifiDirectService.startDiscovery();
    }

    if (_capabilities.canUseBleDiscovery) {
      await wifiDirectService.startBleScanning();
    }
  }

  /// Stops discovery to preserve battery
  Future<void> stopUnifiedDiscovery() async {
    if (_capabilities.wifiDirectSupported) {
      await wifiDirectService.stopDiscovery();
    }
    if (_capabilities.bleSupported) {
      await wifiDirectService.stopBleScanning();
      await wifiDirectService.stopBleAdvertising();
    }
    if (_currentPhase == ConnectionPhase.discovering) {
      _setPhase(ConnectionPhase.idle);
    }
  }

  /// Prepares the device to receive incoming transfers directly without a router
  Future<ReceiveDirectSession> prepareReceiveMode({
    required NexoraDevice localDevice,
    required int tcpPort,
  }) async {
    _setPhase(ConnectionPhase.connecting);

    // 1. Attempt autonomous Wi-Fi Direct Group creation (Priority 1)
    if (_capabilities.wifiDirectSupported) {
      try {
        final group = await wifiDirectService.createGroup();
        if (group != null && group.groupCreated) {
          _activeGroupInfo = group;
          _activeTransport = TransportType.wifiDirect;

          // Start BLE advertising to assist nearby senders
          if (_capabilities.canUseBleDiscovery) {
            await wifiDirectService.startBleAdvertising(
              deviceId: localDevice.deviceId,
              displayName: localDevice.displayName,
            );
          }

          _setPhase(ConnectionPhase.groupFormed);

          return ReceiveDirectSession(
            transport: TransportType.wifiDirect,
            ssid: group.networkName,
            passphrase: group.passphrase,
            ipAddress: '192.168.49.1', // Standard Android Wi-Fi Direct Group Owner IP
            port: tcpPort,
          );
        }
      } catch (e) {
        debugPrint('Wi-Fi Direct group creation failed: $e. Falling back...');
      }
    }

    // 2. Fallback to existing Local Network TCP
    _activeTransport = TransportType.localNetwork;
    _setPhase(ConnectionPhase.connected);
    return ReceiveDirectSession(
      transport: TransportType.localNetwork,
      ipAddress: localDevice.address ?? '127.0.0.1',
      port: tcpPort,
    );
  }

  /// Connects to a target peer device and returns the resolved target IP address
  Future<String> connectDirect({required NexoraDevice targetPeer}) async {
    _setPhase(ConnectionPhase.connecting);

    // If target has an explicit IP address already (e.g. Local Network or direct connect)
    if (targetPeer.address != null &&
        targetPeer.address!.isNotEmpty &&
        targetPeer.address != '127.0.0.1') {
      _setPhase(ConnectionPhase.connected);
      return targetPeer.address!;
    }

    // If target is a Wi-Fi Direct peer (has MAC address in ID or transport)
    final isP2p = targetPeer.deviceId.startsWith('p2p-');
    if (isP2p && _capabilities.wifiDirectSupported) {
      final mac = targetPeer.deviceId.replaceFirst('p2p-', '');

      // Set up listener before initiating connection to catch early group formation
      final completer = Completer<String>();
      final sub = wifiDirectService.onConnectionChanged.listen((info) {
        if (info.groupFormed && info.groupOwnerAddress != null) {
          if (!completer.isCompleted) {
            completer.complete(info.groupOwnerAddress!);
          }
        }
      });

      final connected = await wifiDirectService.connect(mac);
      if (connected) {
        try {
          final targetIp = await completer.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () => '192.168.49.1',
          );
          await sub.cancel();
          _setPhase(ConnectionPhase.connected);
          return targetIp;
        } catch (_) {
          await sub.cancel();
        }
      } else {
        await sub.cancel();
      }
    }

    // Default fallback IP
    _setPhase(ConnectionPhase.connected);
    return targetPeer.address ?? '192.168.49.1';
  }

  /// Checks available free disk space on storage via native StatFs
  Future<int> checkFreeStorageSpace({String? path}) async {
    return await wifiDirectService.getFreeDiskSpace(path: path);
  }

  /// Teardown session and release all direct transport hardware resources
  Future<void> teardownSession() async {
    await stopUnifiedDiscovery();
    if (_activeGroupInfo != null) {
      await wifiDirectService.removeGroup();
      _activeGroupInfo = null;
    }
    _setPhase(ConnectionPhase.idle);
  }

  void dispose() {
    _p2pPeersSub?.cancel();
    _p2pConnSub?.cancel();
    _blePeersSub?.cancel();
    if (!_phaseController.isClosed) _phaseController.close();
    if (!_peersStreamController.isClosed) _peersStreamController.close();
    wifiDirectService.dispose();
  }
}
