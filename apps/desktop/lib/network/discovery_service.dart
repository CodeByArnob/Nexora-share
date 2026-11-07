import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device_model.dart';

class DiscoveryService {
  static const int discoveryPort = 48843;
  static const String multicastAddress = '224.0.0.167';

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _evictionTimer;

  final Map<String, NexoraDevice> _activePeers = {};
  final void Function(List<NexoraDevice> peers) onPeersUpdated;

  DiscoveryService({required this.onPeersUpdated});

  /// Starts listening for nearby peer discovery packets and broadcasting local device presence.
  Future<void> start({
    required NexoraDevice localDevice,
    required int tcpPort,
  }) async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      _socket?.broadcastEnabled = true;

      try {
        _socket?.joinMulticast(InternetAddress(multicastAddress));
      } catch (_) {}

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram, localDevice.deviceId);
          }
        }
      });

      // Broadcast local presence every 3 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastPresence(localDevice, tcpPort);
      });

      // Evict stale peers every 5 seconds
      _evictionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _evictStalePeers();
      });

      // Send initial announcement immediately
      _broadcastPresence(localDevice, tcpPort);
    } catch (_) {}
  }

  void _broadcastPresence(NexoraDevice localDevice, int tcpPort) {
    if (_socket == null) return;
    try {
      final packet = {
        'nexora_discovery': 1,
        'device_id': localDevice.deviceId,
        'display_name': localDevice.displayName,
        'platform': localDevice.platform,
        'fingerprint': localDevice.fingerprint,
        'tcp_port': tcpPort,
      };

      final data = utf8.encode(jsonEncode(packet));
      _socket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
      try {
        _socket?.send(data, InternetAddress(multicastAddress), discoveryPort);
      } catch (_) {}
    } catch (_) {}
  }

  void _handleIncomingPacket(Datagram datagram, String localDeviceId) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;

      if (json['nexora_discovery'] != 1) return;

      final peerId = json['device_id'] as String;
      if (peerId == localDeviceId) return;

      final peer = NexoraDevice(
        deviceId: peerId,
        displayName: json['display_name'] as String? ?? 'Nearby Device',
        platform: json['platform'] as String? ?? 'Unknown',
        fingerprint: json['fingerprint'] as String? ?? '',
        address: datagram.address.address,
        port: json['tcp_port'] as int? ?? 48842,
        lastSeen: DateTime.now(),
      );

      _activePeers[peerId] = peer;
      onPeersUpdated(_activePeers.values.toList());
    } catch (_) {}
  }

  void _evictStalePeers() {
    final now = DateTime.now();
    bool changed = false;
    _activePeers.removeWhere((id, peer) {
      if (now.difference(peer.lastSeen).inSeconds > 10) {
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
