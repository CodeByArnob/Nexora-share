import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/transfer_model.dart';
import '../providers/app_state.dart';

final transferCoordinatorProvider = Provider<TransferCoordinator>((ref) {
  final coordinator = TransferCoordinator(ref);
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

/// Unified Transfer Coordinator establishing a shared state-management
/// and event-coordination layer across all supported transport engines.
class TransferCoordinator {
  final Ref _ref;

  final StreamController<NexoraTransfer> _transferUpdatesController =
      StreamController<NexoraTransfer>.broadcast();
  final StreamController<NexoraTransfer> _incomingOfferController =
      StreamController<NexoraTransfer>.broadcast();
  final StreamController<NexoraTransfer> _transferTerminatedController =
      StreamController<NexoraTransfer>.broadcast();

  final Set<String> _finalizedTransferIds = {};

  Stream<NexoraTransfer> get onTransferUpdated =>
      _transferUpdatesController.stream;
  Stream<NexoraTransfer> get onIncomingOffer => _incomingOfferController.stream;
  Stream<NexoraTransfer> get onTransferTerminated =>
      _transferTerminatedController.stream;

  TransferCoordinator(this._ref);

  /// Registers a newly initiated or incoming transfer in active state.
  void registerTransfer(NexoraTransfer transfer) {
    _finalizedTransferIds.remove(transfer.transferId);

    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transfer.transferId);
    if (idx >= 0) {
      active[idx] = transfer;
    } else {
      active.insert(0, transfer);
    }
    _ref.read(activeTransfersProvider.notifier).state = active;
    _transferUpdatesController.add(transfer);

    if (transfer.direction == TransferDirection.receive &&
        (transfer.state == TransferState.awaitingAcceptance ||
            transfer.state == TransferState.offered)) {
      _incomingOfferController.add(transfer);
    }

    // Persist immediately in SQLite
    unawaited(
      DatabaseService.instance.logTransfer(transfer).catchError((_) {}),
    );
  }

  /// Updates progress of an in-flight transfer with real byte counters and speeds.
  void updateProgress(NexoraTransfer transfer) {
    if (transfer.state.isTerminal) {
      terminateTransfer(
        transfer.transferId,
        transfer.state,
        failureReason: transfer.failureReason,
        transferredBytes: transfer.bytesTransferred,
        completedAt: transfer.completedAt,
      );
      return;
    }

    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transfer.transferId);
    if (idx >= 0) {
      active[idx] = transfer;
    } else {
      active.insert(0, transfer);
    }
    _ref.read(activeTransfersProvider.notifier).state = active;
    _transferUpdatesController.add(transfer);
  }

  /// Transitions a transfer's state atomically.
  void transitionState(
    String transferId,
    TransferState newState, {
    String? failureReason,
    int? bytesTransferred,
  }) {
    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final idx = active.indexWhere((t) => t.transferId == transferId);
    if (idx >= 0) {
      final updated = active[idx].copyWith(
        state: newState,
        failureReason: failureReason,
        bytesTransferred: bytesTransferred ?? active[idx].bytesTransferred,
        speedBytesPerSec: newState.isTerminal ? 0.0 : null,
        etaSeconds: newState.isTerminal ? 0 : null,
      );
      if (newState.isTerminal) {
        terminateTransfer(
          transferId,
          newState,
          failureReason: failureReason,
          transferredBytes: updated.bytesTransferred,
        );
      } else {
        active[idx] = updated;
        _ref.read(activeTransfersProvider.notifier).state = active;
        _transferUpdatesController.add(updated);
      }
    }
  }

  /// Idempotently terminates an active transfer and commits exactly one record to history.
  void terminateTransfer(
    String transferId,
    TransferState terminalState, {
    String? failureReason,
    int? transferredBytes,
    DateTime? completedAt,
  }) {
    // 1. Remove from active transfers atomically
    final active = List<NexoraTransfer>.from(
      _ref.read(activeTransfersProvider),
    );
    final activeIdx = active.indexWhere((t) => t.transferId == transferId);
    NexoraTransfer? transferToFinalize;
    if (activeIdx >= 0) {
      transferToFinalize = active.removeAt(activeIdx);
      _ref.read(activeTransfersProvider.notifier).state = active;
    }

    // 2. Resolve base transfer info
    final base =
        transferToFinalize ??
        _ref
            .read(transferHistoryProvider)
            .where((t) => t.transferId == transferId)
            .firstOrNull;

    final effectiveTransferred =
        transferredBytes ?? base?.bytesTransferred ?? 0;
    final finalized = (base ??
            NexoraTransfer(
              transferId: transferId,
              direction: TransferDirection.send,
              remoteDeviceId: 'peer',
              remoteDeviceName: 'Peer Device',
              totalFiles: 1,
              totalBytes: effectiveTransferred,
              createdAt: DateTime.now(),
            ))
        .copyWith(
          state: terminalState,
          failureReason: failureReason,
          bytesTransferred: effectiveTransferred,
          speedBytesPerSec: 0.0,
          etaSeconds: 0,
          completedAt: completedAt ?? DateTime.now(),
        );

    // 3. Update or prepend in history without duplicates
    final history = List<NexoraTransfer>.from(
      _ref.read(transferHistoryProvider),
    );
    final historyIdx = history.indexWhere((t) => t.transferId == transferId);
    if (historyIdx >= 0) {
      history[historyIdx] = finalized;
    } else {
      history.insert(0, finalized);
    }
    _ref.read(transferHistoryProvider.notifier).state = history;
    _finalizedTransferIds.add(transferId);

    _transferUpdatesController.add(finalized);
    _transferTerminatedController.add(finalized);

    // 4. Update SQLite database
    unawaited(
      DatabaseService.instance.logTransfer(finalized).catchError((_) {}),
    );
    unawaited(
      DatabaseService.instance
          .updateTransferProgress(
            transferId,
            finalized.bytesTransferred,
            terminalState,
          )
          .catchError((_) {}),
    );
  }

  NexoraTransfer? getTransfer(String transferId) {
    return _ref
            .read(activeTransfersProvider)
            .where((t) => t.transferId == transferId)
            .firstOrNull ??
        _ref
            .read(transferHistoryProvider)
            .where((t) => t.transferId == transferId)
            .firstOrNull;
  }

  void dispose() {
    _transferUpdatesController.close();
    _incomingOfferController.close();
    _transferTerminatedController.close();
  }
}
