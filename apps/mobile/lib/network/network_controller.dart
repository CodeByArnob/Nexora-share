import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';
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

  // Active receiver approval prompt hook
  Future<bool> Function(IncomingTransferOffer offer)? onApprovalRequested;

  NetworkController(this._ref);

  /// Initializes local network services, TCP server, and discovery broadcaster.
  Future<void> initialize({
    required Future<bool> Function(IncomingTransferOffer offer)
    approvalCallback,
  }) async {
    onApprovalRequested = approvalCallback;
    final localDevice = _ref.read(localDeviceProvider);

    // Initialize TCP Server
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
    );

    _tcpPort = await _server!.start();

    // Initialize Discovery Service
    _discovery = DiscoveryService(
      onPeersUpdated: (peers) {
        _ref.read(discoveredPeersProvider.notifier).state = peers;
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

  /// Updates the local device announcement broadcast
  void updateLocalDevice(NexoraDevice updatedDevice) {
    _discovery?.updateLocalDevice(updatedDevice);
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

  /// Sends a specific file to a peer (e.g. from file picker, Share Intent, or tests).
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
  }) async {
    if (_client == null) return;
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendFile(peer: peer, file: file, localDevice: localDevice);
  }

  /// Sends multiple files in a batch to a peer.
  Future<void> sendFiles({
    required NexoraDevice peer,
    required List<File> files,
  }) async {
    if (_client == null) return;
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendFiles(
      peer: peer,
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
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendDirectory(
      peer: peer,
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
    _discovery?.stop();
    _server?.stop();
  }
}
