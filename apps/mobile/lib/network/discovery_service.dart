import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device_model.dart';
import '../services/device_identity_service.dart';

class DiscoveryService {
  static const int discoveryPort = 48843;
  static const String multicastAddress = '224.0.0.167';

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _evictionTimer;

  final Map<String, NexoraDevice> _activePeers = {};
  final void Function(List<NexoraDevice> peers) onPeersUpdated;

  NexoraDevice? _currentLocalDevice;
  int _currentTcpPort = 48842;

  DiscoveryService({required this.onPeersUpdated});

  /// Starts listening for nearby peer discovery packets and broadcasting local device presence.
  Future<void> start({
    required NexoraDevice localDevice,
    required int tcpPort,
  }) async {
    _currentLocalDevice = localDevice;
    _currentTcpPort = tcpPort;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: false,
      );
      _socket?.broadcastEnabled = true;

      // Join multicast on default and on all active network interfaces
      try {
        _socket?.joinMulticast(InternetAddress(multicastAddress));
      } catch (_) {}

      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          try {
            _socket?.joinMulticast(InternetAddress(multicastAddress), iface);
          } catch (_) {}
        }
      } catch (_) {}

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null && _currentLocalDevice != null) {
            _handleIncomingPacket(
              datagram,
              _currentLocalDevice!,
              _currentTcpPort,
            );
          }
        }
      });

      // Broadcast local presence every 3 seconds
      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_currentLocalDevice != null) {
          _broadcastPresence(_currentLocalDevice!, _currentTcpPort);
        }
      });

      // Evict stale peers every 5 seconds
      _evictionTimer?.cancel();
      _evictionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _evictStalePeers();
      });

      // Send initial announcement immediately
      _broadcastPresence(localDevice, tcpPort);
    } catch (_) {
      // Socket bind error handled gracefully
    }
  }

  /// Updates local device identity if user updates their name or IP changes.
  void updateLocalDevice(NexoraDevice updatedDevice) {
    _currentLocalDevice = updatedDevice;
    if (_socket != null) {
      _broadcastPresence(updatedDevice, _currentTcpPort);
    }
  }

  Future<void> _broadcastPresence(NexoraDevice localDevice, int tcpPort) async {
    if (_socket == null) return;
    try {
      final packet = {
        'nexora_discovery': 1,
        'device_id': localDevice.deviceId,
        'display_name': localDevice.displayName,
        'platform': localDevice.platform,
        'fingerprint': localDevice.fingerprint,
        'tcp_port': tcpPort,
        if (localDevice.address != null) 'address': localDevice.address,
      };

      final data = utf8.encode(jsonEncode(packet));

      // 1. Send to all directed subnet broadcasts (e.g. 192.168.1.255, 192.168.43.255)
      final subnetBroadcasts =
          await DeviceIdentityService.getSubnetBroadcastAddresses();
      for (final broadcastIp in subnetBroadcasts) {
        try {
          _socket?.send(data, InternetAddress(broadcastIp), discoveryPort);
        } catch (_) {}
      }

      // 2. Send to global broadcast 255.255.255.255
      try {
        _socket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
      } catch (_) {}

      // 3. Send to Multicast group 224.0.0.167
      try {
        _socket?.send(data, InternetAddress(multicastAddress), discoveryPort);
      } catch (_) {}
    } catch (_) {}
  }

  void _handleIncomingPacket(
    Datagram datagram,
    NexoraDevice localDevice,
    int tcpPort,
  ) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;

      if (json['nexora_discovery'] != 1) return;

      final peerId = json['device_id'] as String;
      // Skip our own broadcasts
      if (peerId == localDevice.deviceId) return;

      final incomingAddress = datagram.address.address;
      final payloadAddress = json['address'] as String?;
      final resolvedAddress =
          (payloadAddress != null &&
              payloadAddress.isNotEmpty &&
              payloadAddress != '127.0.0.1')
          ? payloadAddress
          : incomingAddress;

      final peer = NexoraDevice(
        deviceId: peerId,
        displayName: json['display_name'] as String? ?? 'Nearby Device',
        platform: json['platform'] as String? ?? 'Unknown',
        fingerprint: json['fingerprint'] as String? ?? '',
        address: resolvedAddress,
        port: json['tcp_port'] as int? ?? 48842,
        lastSeen: DateTime.now(),
      );

      final isNewPeer = !_activePeers.containsKey(peerId);
      _activePeers[peerId] = peer;
      onPeersUpdated(_activePeers.values.toList());

      // If this is a new discovery or first packet from this peer,
      // immediately reply with a unicast packet back to their IP so bi-directional discovery is instantaneous!
      if (isNewPeer) {
        _sendUnicastAnnouncement(datagram.address, localDevice, tcpPort);
      }
    } catch (_) {}
  }

  void _sendUnicastAnnouncement(
    InternetAddress targetAddress,
    NexoraDevice localDevice,
    int tcpPort,
  ) {
    if (_socket == null) return;
    try {
      final packet = {
        'nexora_discovery': 1,
        'device_id': localDevice.deviceId,
        'display_name': localDevice.displayName,
        'platform': localDevice.platform,
        'fingerprint': localDevice.fingerprint,
        'tcp_port': tcpPort,
        if (localDevice.address != null) 'address': localDevice.address,
      };
      final data = utf8.encode(jsonEncode(packet));
      _socket?.send(data, targetAddress, discoveryPort);
    } catch (_) {}
  }

  /// Manually pings and discovers a peer by direct IP address.
  /// Bypasses router AP isolation / multicast blocking.
  Future<bool> manualConnect(String targetIp, {int targetPort = 48842}) async {
    final cleanIp = targetIp.trim();
    if (cleanIp.isEmpty || _currentLocalDevice == null) return false;

    try {
      final targetAddr = InternetAddress(cleanIp);
      // Send direct discovery UDP packet
      _sendUnicastAnnouncement(
        targetAddr,
        _currentLocalDevice!,
        _currentTcpPort,
      );

      // Also verify TCP connectivity
      final socket = await Socket.connect(
        targetAddr,
        targetPort,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();

      final peer = NexoraDevice(
        deviceId: 'manual-$cleanIp',
        displayName: 'Direct Device ($cleanIp)',
        platform: 'NEXORA',
        fingerprint: '',
        address: cleanIp,
        port: targetPort,
        lastSeen: DateTime.now(),
      );

      _activePeers[peer.deviceId] = peer;
      onPeersUpdated(_activePeers.values.toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  void _evictStalePeers() {
    final now = DateTime.now();
    bool changed = false;
    _activePeers.removeWhere((id, peer) {
      if (now.difference(peer.lastSeen).inSeconds > 12) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed) {
      onPeersUpdated(_activePeers.values.toList());
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _evictionTimer?.cancel();
    _socket?.close();
    _socket = null;
    _activePeers.clear();
  }
}
