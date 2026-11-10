import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/database/database_service.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/models/transfer_model.dart';
import 'package:nexora_app/network/transfer_client.dart';
import 'package:nexora_app/network/transfer_coordinator.dart';
import 'package:nexora_app/network/transfer_server.dart';
import 'package:nexora_app/providers/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = await Directory.systemTemp.createTemp('nexora_bidirectional_test_');
    await DatabaseService.instance.initialize(inMemory: true);
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('1. Progress Zero-Byte Bug Elimination', () {
    test('progressPercentage returns 0.0 when 0 bytes transferred (no fake 5%)', () {
      final transfer = NexoraTransfer(
        transferId: 't-zero',
        direction: TransferDirection.send,
        remoteDeviceId: 'peer-1',
        remoteDeviceName: 'Pixel 9 Pro',
        remotePlatform: 'Android',
        totalFiles: 1,
        totalBytes: 1048576,
        bytesTransferred: 0,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: 'test.mp4',
        state: TransferState.connecting,
        createdAt: DateTime.now(),
      );

      expect(transfer.progressPercentage, equals(0.0));
      expect(transfer.progressPercentage, isNot(equals(0.05)));
    });

    test('progressPercentage handles 0 totalBytes safely without NaN or divide-by-zero', () {
      final transfer = NexoraTransfer(
        transferId: 't-zero-size',
        direction: TransferDirection.receive,
        remoteDeviceId: 'peer-2',
        remoteDeviceName: 'Galaxy S24',
        remotePlatform: 'Android',
        totalFiles: 0,
        totalBytes: 0,
        bytesTransferred: 0,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: 'empty',
        state: TransferState.offered,
        createdAt: DateTime.now(),
      );

      expect(transfer.progressPercentage, equals(0.0));
    });
  });

  group('2. TransferCoordinator Lifecycle & History Deduplication', () {
    test('Coordinator registers active transfer, transitions states, and deduplicates history', () async {
      final container = ProviderContainer();
      final coordinator = container.read(transferCoordinatorProvider);

      final initial = NexoraTransfer(
        transferId: 'sync-test-coord-1',
        direction: TransferDirection.send,
        remoteDeviceId: 'device-target',
        remoteDeviceName: 'Target Device',
        remotePlatform: 'Android',
        totalFiles: 1,
        totalBytes: 5000,
        bytesTransferred: 0,
        speedBytesPerSec: 0.0,
        etaSeconds: 0,
        currentFile: 'presentation.pdf',
        state: TransferState.connecting,
        createdAt: DateTime.now(),
      );

      // Register transfer
      coordinator.registerTransfer(initial);
      expect(container.read(activeTransfersProvider).length, equals(1));
      expect(container.read(activeTransfersProvider).first.state, equals(TransferState.connecting));

      // Transition to awaitingAcceptance
      coordinator.transitionState('sync-test-coord-1', TransferState.awaitingAcceptance);
      expect(container.read(activeTransfersProvider).first.state, equals(TransferState.awaitingAcceptance));

      // Update progress
      coordinator.updateProgress(
        initial.copyWith(
          bytesTransferred: 2500,
          speedBytesPerSec: 500000.0,
          etaSeconds: 5,
        ),
      );
      final active = container.read(activeTransfersProvider).first;
      expect(active.bytesTransferred, equals(2500));
      expect(active.progressPercentage, equals(0.5));

      // Terminate transfer (Completed)
      coordinator.terminateTransfer(
        'sync-test-coord-1',
        TransferState.completed,
        transferredBytes: 5000,
        completedAt: DateTime.now(),
      );

      // Active transfers must be empty
      expect(container.read(activeTransfersProvider), isEmpty);

      // History must contain exactly 1 entry for this transferId
      final history = container.read(transferHistoryProvider);
      final matching = history.where((t) => t.transferId == 'sync-test-coord-1').toList();
      expect(matching.length, equals(1));
      expect(matching.first.state, equals(TransferState.completed));

      // Calling terminateTransfer a second time (e.g. redundant frame) must not duplicate history
      coordinator.terminateTransfer(
        'sync-test-coord-1',
        TransferState.completed,
      );
      final historyAfterRedundant = container.read(transferHistoryProvider);
      final matchingAfterRedundant = historyAfterRedundant
          .where((t) => t.transferId == 'sync-test-coord-1')
          .toList();
      expect(matchingAfterRedundant.length, equals(1));
    });
  });

  group('3. Receiver Instant Awareness & Approval Handshake', () {
    test('Receiver gets immediate awaitingAcceptance notification upon TransferOffer', () async {
      final serverDir = Directory('${tempDir.path}${Platform.pathSeparator}receiver_instant');
      await serverDir.create();

      final offerReceivedCompleter = Completer<IncomingTransferOffer>();
      final serverProgressList = <NexoraTransfer>[];

      final server = TransferServer(
        customDestinationDirectory: serverDir,
        onRequestApproval: (offer) async {
          if (!offerReceivedCompleter.isCompleted) {
            offerReceivedCompleter.complete(offer);
          }
          return true; // Approve
        },
        onTransferProgress: (progress) {
          serverProgressList.add(progress);
        },
        onTransferCompleted: (_) {},
      );

      final port = await server.start();

      final testFile = File('${tempDir.path}${Platform.pathSeparator}instant_test.txt');
      await testFile.writeAsString('Instant Awareness Verification Payload');

      final client = TransferClient(
        onProgress: (_) {},
        onCompleted: (_) {},
        onError: (_) {},
      );

      final peer = NexoraDevice(
        deviceId: 'server-peer',
        displayName: 'Receiver Phone',
        platform: 'Android',
        fingerprint: 'fp-server',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final localDevice = NexoraDevice(
        deviceId: 'sender-peer',
        displayName: 'Sender Phone',
        platform: 'Android',
        fingerprint: 'fp-sender',
        lastSeen: DateTime.now(),
      );

      // Trigger send in background
      final sendFuture = client.sendFile(peer: peer, file: testFile, localDevice: localDevice);

      // Await receiver offer
      final offer = await offerReceivedCompleter.future.timeout(const Duration(seconds: 3));

      expect(offer.fileName, equals('instant_test.txt'));
      expect(offer.senderName, equals('Sender Phone'));
      expect(offer.totalBytes, equals(await testFile.length()));

      // Verify server emitted awaitingAcceptance immediately to onTransferProgress
      expect(serverProgressList.isNotEmpty, isTrue);
      final firstServerEvent = serverProgressList.first;
      expect(firstServerEvent.state, equals(TransferState.awaitingAcceptance));
      expect(firstServerEvent.bytesTransferred, equals(0));
      expect(firstServerEvent.currentFile, equals('instant_test.txt'));

      await sendFuture;
      server.stop();
    });

    test('Receiver rejects transfer when storage space is insufficient', () async {
      final serverDir = Directory('${tempDir.path}${Platform.pathSeparator}receiver_storage');
      await serverDir.create();

      final server = TransferServer(
        customDestinationDirectory: serverDir,
        checkStorageSpace: (requiredBytes) async => false, // Simulate full disk
        onRequestApproval: (offer) async => true,
        onTransferProgress: (_) {},
        onTransferCompleted: (_) {},
      );

      final port = await server.start();

      final testFile = File('${tempDir.path}${Platform.pathSeparator}storage_test.bin');
      await testFile.writeAsBytes(List.filled(1024, 42));

      final clientCompleter = Completer<String>();
      final client = TransferClient(
        onProgress: (p) {
          if (p.state == TransferState.rejected || p.state == TransferState.failed) {
            if (!clientCompleter.isCompleted) {
              clientCompleter.complete(p.failureReason ?? 'rejected');
            }
          }
        },
        onCompleted: (_) {},
        onError: (err) {
          if (!clientCompleter.isCompleted) clientCompleter.complete(err);
        },
      );

      final peer = NexoraDevice(
        deviceId: 'server-peer-2',
        displayName: 'Receiver Full Disk',
        platform: 'Android',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final localDevice = NexoraDevice(
        deviceId: 'sender-peer-2',
        displayName: 'Sender Phone',
        platform: 'Android',
        lastSeen: DateTime.now(),
      );

      await client.sendFile(peer: peer, file: testFile, localDevice: localDevice);

      final reason = await clientCompleter.future.timeout(const Duration(seconds: 3));
      expect(reason, contains('Insufficient storage space'));

      server.stop();
    });
  });

  group('4. Bidirectional Cancellation Handshake & Partial File Cleanup', () {
    test('Sender cancellation transmits TransferCancel and receiver acknowledges and deletes partial file', () async {
      final serverDir = Directory('${tempDir.path}${Platform.pathSeparator}receiver_cancel');
      await serverDir.create();

      final receiverCancelledCompleter = Completer<NexoraTransfer>();
      final server = TransferServer(
        customDestinationDirectory: serverDir,
        onRequestApproval: (offer) async => true,
        onTransferProgress: (progress) {
          if (progress.state == TransferState.cancelled) {
            if (!receiverCancelledCompleter.isCompleted) {
              receiverCancelledCompleter.complete(progress);
            }
          }
        },
        onTransferCompleted: (_) {},
      );

      final port = await server.start();

      // Create a 3 MB file so cancellation occurs mid-flight across chunks
      final largeFile = File('${tempDir.path}${Platform.pathSeparator}large_in_flight.dat');
      await largeFile.writeAsBytes(List.filled(3 * 1024 * 1024, 7));

      late final TransferClient client;
      client = TransferClient(
        onProgress: (progress) {
          if (progress.bytesTransferred > 0 && !client.isCancelled(progress.transferId)) {
            // Sender cancels while streaming
            client.cancel(progress.transferId, reason: 'Cancelled by sender');
          }
        },
        onCompleted: (_) {},
        onError: (_) {},
      );

      final peer = NexoraDevice(
        deviceId: 'server-cancel-peer',
        displayName: 'Receiver Peer',
        platform: 'Android',
        address: '127.0.0.1',
        port: port,
        lastSeen: DateTime.now(),
      );

      final localDevice = NexoraDevice(
        deviceId: 'sender-cancel-peer',
        displayName: 'Sender Peer',
        platform: 'Android',
        lastSeen: DateTime.now(),
      );

      final sendFuture = client.sendFile(peer: peer, file: largeFile, localDevice: localDevice);

      final cancelledTransfer = await receiverCancelledCompleter.future.timeout(
        const Duration(seconds: 4),
      );
      await sendFuture.catchError((_) {});

      expect(cancelledTransfer.state, equals(TransferState.cancelled));
      expect(cancelledTransfer.failureReason, contains('Cancelled by sender'));

      // Verify that the incomplete file was deleted on receiver disk
      final partialFile = File('${serverDir.path}${Platform.pathSeparator}large_in_flight.dat');
      bool fileDeleted = false;
      for (int i = 0; i < 25; i++) {
        if (!await partialFile.exists()) {
          fileDeleted = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      expect(fileDeleted, isTrue);

      server.stop();
    });
  });
}
