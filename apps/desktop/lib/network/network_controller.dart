import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';
import 'discovery_service.dart';
import 'transfer_client.dart';
import 'transfer_server.dart';

final networkControllerProvider = Provider<DesktopNetworkController>((ref) {
  return DesktopNetworkController(ref);
});

class DesktopNetworkController {
  final Ref _ref;
  DiscoveryService? _discovery;
  TransferServer? _server;
  TransferClient? _client;
  int _tcpPort = 48842;

  // Active receiver approval prompt hook
  Future<bool> Function(IncomingTransferOffer offer)? onApprovalRequested;

  DesktopNetworkController(this._ref);

  int get tcpPort => _tcpPort;

  /// Initializes local network services, TCP server, and discovery broadcaster.
  Future<void> initialize({
    required Future<bool> Function(IncomingTransferOffer offer) approvalCallback,
    Directory? customDestinationDirectory,
  }) async {
    onApprovalRequested = approvalCallback;
    final localDevice = _ref.read(localDeviceProvider);

    // Initialize TCP Server
    _server = TransferServer(
      customDestinationDirectory: customDestinationDirectory,
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

    await _discovery!.start(
      localDevice: localDevice,
      tcpPort: _tcpPort,
    );

    // Initialize Transfer Client
    _client = TransferClient(
      onProgress: (transfer) {
        _updateActiveTransfer(transfer);
      },
      onCompleted: (transfer) {
        _completeTransfer(transfer);
      },
      onError: (err) {
        // Log or handle transfer error
      },
    );
  }

  void _updateActiveTransfer(NexoraTransfer transfer) {
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
    // Remove from active
    final active = List<NexoraTransfer>.from(_ref.read(activeTransfersProvider))
      ..removeWhere((t) => t.transferId == transfer.transferId);
    _ref.read(activeTransfersProvider.notifier).state = active;

    // Add to history
    final history = <NexoraTransfer>[transfer, ..._ref.read(transferHistoryProvider)];
    _ref.read(transferHistoryProvider.notifier).state = history;
  }

  /// Sends a specific file to a peer (e.g. from file picker or drag-and-drop).
  Future<void> sendFile({
    required NexoraDevice peer,
    required File file,
  }) async {
    if (_client == null) return;
    final localDevice = _ref.read(localDeviceProvider);
    await _client!.sendFile(
      peer: peer,
      file: file,
      localDevice: localDevice,
    );
  }

  /// Launches the native Windows file picker and initiates transmission to the selected peer.
  Future<void> pickAndSendFile({
    required BuildContext context,
    required NexoraDevice targetPeer,
  }) async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.any,
    );

    if (pickedFile != null && pickedFile.path != null) {
      final file = File(pickedFile.path!);
      await sendFile(peer: targetPeer, file: file);
    }
  }

  /// Launches the native Windows folder picker and initiates transmission.
  Future<void> pickFolderAndSend({
    required BuildContext context,
    required NexoraDevice targetPeer,
  }) async {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      final entities = await dir.list(recursive: false).toList();
      for (final entity in entities) {
        if (entity is File) {
          await sendFile(peer: targetPeer, file: entity);
        }
      }
    }
  }

  void dispose() {
    _discovery?.stop();
    _server?.stop();
  }
}
