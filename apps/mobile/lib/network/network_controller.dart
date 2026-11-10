import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';
import '../transport/direct_connection_manager.dart';
import '../transport/transport_type.dart';
import 'discovery_service.dart';
import 'transfer_client.dart';
import 'transfer_server.dart';

final networkControllerProvider = Provider<NetworkController>((ref) {
  return NetworkController(ref);
});

class NetworkController {
  final Ref _ref;
  DiscoveryService? _discovery;
  TransferServer? _server;
  TransferClient? _client;
  int _tcpPort = 48842;

  int get tcpPort => _tcpPort;

  DirectConnectionManager get directManager =>
      _ref.read(directConnectionManagerProvider);

  // Active receiver approval prompt hook
  Future<bool> Function(IncomingTransferOffer offer)? onApprovalRequested;

  final Map<String, NexoraDevice> _lanPeers = {};
  final Map<String, NexoraDevice> _directPeers = {};

  StreamSubscription? _directPeersSub;
  StreamSubscription? _phaseSub;

  NetworkController(this._ref);

  /// Initializes local network services, TCP server, Wi-Fi Direct, and discovery broadcasters.
  Future<void> initialize({
    required Future<bool> Function(IncomingTransferOffer offer)
    approvalCallback,
  }) async {
    onApprovalRequested = approvalCallback;
    final localDevice = _ref.read(localDeviceProvider);

    // Initialize Direct Connection Manager (Wi-Fi Direct, Wi-Fi Aware, BLE)
    await directManager.initialize();

    // Wire up Direct connection phase
    _phaseSub?.cancel();
    _phaseSub = directManager.onPhaseChanged.listen((phase) {
      _ref.read(connectionPhaseProvider.notifier).state = phase;
    });

    // Wire up Direct peers stream
    _directPeersSub?.cancel();
    _directPeersSub = directManager.onPeersUpdated.listen((directList) {
      _directPeers.clear();
      for (final p in directList) {
        _directPeers[p.deviceId] = p;
      }
      _publishUnifiedPeers();
    });

    // Initialize TCP Server with native StatFs storage verification
    _server = TransferServer(
      onRequestApproval: (offer) async {
        if (onApprovalRequested != null) {
          return await onApprovalRequested!(offer);
        }
        return false;
      },
      onTransferProgress: (transfer) {
        _updateActiveTransfer(transfer);
      },
      onTransferCompleted: (transfer) {
        _completeTransfer(transfer);
      },
      checkStorageSpace: (requiredBytes) async {
        try {
          final free = await directManager.checkFreeStorageSpace();
          // Require at least file size + 50 MB safety margin
          return free >= (requiredBytes + 50 * 1024 * 1024);
        } catch (_) {
          return true; // Fallback to allowing if check fails
        }
      },
    );

    _tcpPort = await _server!.start();

    // Initialize Local Network UDP Multicast/Broadcast Discovery Service
    _discovery = DiscoveryService(
      onPeersUpdated: (peers) {
        _lanPeers.clear();
        for (final p in peers) {
          _lanPeers[p.deviceId] = p.copyWith(
            transportHint: TransportType.localNetwork.shortTag,
          );
        }
        _publishUnifiedPeers();
      },
    );

    await _discovery!.start(localDevice: localDevice, tcpPort: _tcpPort);

    // Initialize Transfer Client
    _client = TransferClient(
      onProgress: (transfer) {
        _updateActiveTransfer(transfer);
      },
      onCompleted: (transfer) {
        _completeTransfer(transfer);
      },
      onError: (err) {
        // Handle error state
      },
    );
  }

  void _publishUnifiedPeers() {
    final combined = <String, NexoraDevice>{};

    // Add Direct P2P peers (Priority 1)
    for (final entry in _directPeers.entries) {
      combined[entry.key] = entry.value;
    }

    // Add LAN peers
    for (final entry in _lanPeers.entries) {
      if (!combined.containsKey(entry.key)) {
        combined[entry.key] = entry.value;
      }
    }

    _ref.read(discoveredPeersProvider.notifier).state =
        combined.values.toList();
  }

  /// Updates the local device announcement broadcast
  void updateLocalDevice(NexoraDevice updatedDevice) {
    _discovery?.updateLocalDevice(updatedDevice);
  }

  /// Manually triggers a network discovery rescan beacon across all transports
  Future<void> rescan() async {
    final localDevice = _ref.read(localDeviceProvider);
    await _discovery?.rescan();
    await directManager.startUnifiedDiscovery(localDevice: localDevice);
  }

  /// Prepares device for router-free direct file reception via autonomous Wi-Fi Direct
  Future<ReceiveDirectSession> prepareReceiveMode() async {
    final localDevice = _ref.read(localDeviceProvider);
    final session = await directManager.prepareReceiveMode(
      localDevice: localDevice,
      tcpPort: _tcpPort,
    );
    _ref.read(activeTransportProvider.notifier).state = session.transport;
    return session;
  }

  /// Manually pings and discovers a peer by IP address
  Future<bool> manualConnect(String targetIp, {int targetPort = 48842}) async {
    if (_discovery == null) return false;
    return await _discovery!.manualConnect(targetIp, targetPort: targetPort);
  }

  void _updateActiveTransfer(NexoraTransfer transfer) {
    if (transfer.state == TransferState.cancelled ||
        transfer.state == TransferState.completed) {
      _completeTransfer(transfer);
      return;
    }
    final list = List<NexoraTransfer>.from(_ref.read(activeTransfersProvider));
    final idx = list.indexWhere((t) => t.transferId == transfer.transferId);
    if (idx >= 0) {
      list[idx] = transfer;
    } else {
      list.insert(0, transfer);
    }
    _ref.read(activeTransfersProvider.notifier).state = list;
  }

  void _completeTransfer(NexoraTransfer transfer) {
    // 1. Remove from active
    final active = List<NexoraTransfer>.from(_ref.read(activeTransfersProvider))
      ..removeWhere((t) => t.transferId == transfer.transferId);
    _ref.read(activeTransfersProvider.notifier).state = active;

    // 2. Add to history without duplicates
    final history = _ref.read(transferHistoryProvider);
    final alreadyCompleted = history.any(
      (t) => t.transferId == transfer.transferId && t.state == transfer.state,
    );
    if (!alreadyCompleted) {
      final finalized = transfer.copyWith(
        speedBytesPerSec: 0,
        etaSeconds: 0,
        completedAt: transfer.completedAt ?? DateTime.now(),
      );
      _ref.read(transferHistoryProvider.notifier).state = [
        finalized,
        ...history.where((t) => t.transferId != transfer.transferId),
      ];
    }
  }

  /// Cancels an active in-flight transfer (sending or receiving).
  Future<void> cancelTransfer(String transferId) async {
    _client?.cancel(transferId);
    _server?.cancel(transferId);

    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transferId);
    if (idx >= 0) {
      final cancelled = active[idx].copyWith(
        state: TransferState.cancelled,
        speedBytesPerSec: 0,
        etaSeconds: 0,
        completedAt: DateTime.now(),
      );
      active.removeAt(idx);
      _ref.read(activeTransfersProvider.notifier).state = active;

      final history = <NexoraTransfer>[
        cancelled,
        ..._ref.read(transferHistoryProvider),
      ];
      _ref.read(transferHistoryProvider.notifier).state = history;

      try {
        await DatabaseService.instance.updateTransferProgress(
          transferId,
          cancelled.bytesTransferred,
          TransferState.cancelled,
        );
      } catch (_) {}
    }
  }

  /// Pauses an active in-flight transfer.
  void pauseTransfer(String transferId) {
    _client?.pause(transferId);
    _server?.pause(transferId);

    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transferId);
    if (idx >= 0) {
      active[idx] = active[idx].copyWith(
        state: TransferState.paused,
        speedBytesPerSec: 0,
      );
      _ref.read(activeTransfersProvider.notifier).state = active;
    }
  }

  /// Resumes a paused transfer.
  void resumeTransfer(String transferId) {
    _client?.resume(transferId);
    _server?.resume(transferId);

    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transferId);
    if (idx >= 0) {
      active[idx] = active[idx].copyWith(state: TransferState.inProgress);
      _ref.read(activeTransfersProvider.notifier).state = active;
    }
  }

  /// Resolves the peer connection transport and address, establishing Wi-Fi Direct if needed
  Future<NexoraDevice> _resolvePeerTransport(NexoraDevice peer) async {
    if (peer.address != null &&
        peer.address!.isNotEmpty &&
        peer.address != '127.0.0.1') {
      return peer;
    }

    final targetIp = await directManager.connectDirect(targetPeer: peer);
    return peer.copyWith(address: targetIp, port: _tcpPort);
  }

  /// Sends a specific file to a peer (e.g. from file picker, Share Intent, or tests).
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
  }) async {
    if (_client == null) return;
    final resolved = await _resolvePeerTransport(peer);
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendFile(peer: resolved, file: file, localDevice: localDevice);
  }

  /// Sends multiple files in a batch to a peer.
  Future<void> sendFiles({
    required NexoraDevice peer,
    required List<File> files,
  }) async {
    if (_client == null) return;
    final resolved = await _resolvePeerTransport(peer);
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendFiles(
      peer: resolved,
      files: files,
      localDevice: localDevice,
    );
  }

  /// Sends an entire directory structure to a peer.
  Future<void> sendDirectory({
    required NexoraDevice peer,
    required Directory directory,
  }) async {
    if (_client == null) return;
    final resolved = await _resolvePeerTransport(peer);
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendDirectory(
      peer: resolved,
      directory: directory,
      localDevice: localDevice,
    );
  }

  /// Launches the native Storage Access Framework (SAF) / file picker
  /// and initiates file transmission to target peer.
  Future<void> pickAndSendFile({
    required BuildContext context,
    required NexoraDevice targetPeer,
  }) async {
    final files = await FilePicker.pickFiles(type: FileType.any);

    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      await sendFile(peer: targetPeer, file: file);
    }
  }

  void dispose() {
    _phaseSub?.cancel();
    _directPeersSub?.cancel();
    _discovery?.stop();
    _server?.stop();
    directManager.teardownSession();
  }
}
