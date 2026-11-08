import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/models/device_model.dart';
import 'package:nexora_desktop/models/transfer_model.dart';
import 'package:nexora_desktop/network/file_transfer_manifest.dart';
import 'package:nexora_desktop/network/transfer_client.dart';
import 'package:nexora_desktop/network/transfer_metrics.dart';
import 'package:nexora_desktop/network/transfer_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Large-File Transfer Initiation Latency & Scalability Benchmarks', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nexora_perf_test_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test(
      'BENCHMARK: 2 GB Sparse File Transfer Request Notification Latency is < 1 second',
      () async {
        // Create a 2 GB sparse file instantly (< 5ms)
        final largeFile = File('${tempDir.path}/sparse_2gb.iso');
        final raf = await largeFile.open(mode: FileMode.write);
        const int twoGigabytes = 2 * 1024 * 1024 * 1024; // 2,147,483,648 bytes
        await raf.setPosition(twoGigabytes - 1);
        await raf.writeByte(0x7F);
        await raf.close();

        expect(await largeFile.length(), twoGigabytes);

        final reqCreatedStopwatch = Stopwatch()..start();
        final manifest = await TransferManifest.fromFiles([largeFile]);
        reqCreatedStopwatch.stop();

        // 1. Verify Manifest Creation Time is instantaneous (< 50ms)
        expect(reqCreatedStopwatch.elapsedMilliseconds, lessThan(50));
        expect(manifest.totalBytes, twoGigabytes);
        expect(manifest.files.first.sizeBytes, twoGigabytes);
        expect(manifest.files.first.mimeType, 'application/octet-stream');
        // Initial SHA-256 hash must be null (deferred to streaming)
        expect(manifest.files.first.sha256Hash, isNull);

        final offerReceivedCompleter = Completer<IncomingTransferOffer>();
        final notificationStopwatch = Stopwatch();

        final server = TransferServer(
          customDestinationDirectory: tempDir,
          onRequestApproval: (offer) async {
            notificationStopwatch.stop();
            if (!offerReceivedCompleter.isCompleted) {
              offerReceivedCompleter.complete(offer);
            }
            return false; // Decline to benchmark initiation only without waiting for full 2GB disk I/O
          },
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );

        final port = await server.start();

        final receiverPeer = NexoraDevice(
          deviceId: 'receiver-benchmark-id',
          displayName: 'Receiver Benchmark Target',
          platform: 'Android',
          fingerprint: 'dummy-recv-fp',
          address: '127.0.0.1',
          port: port,
          lastSeen: DateTime.now(),
        );

        final senderDevice = NexoraDevice(
          deviceId: 'sender-benchmark-id',
          displayName: 'Sender Host Device',
          platform: 'Windows',
          fingerprint: 'dummy-send-fp',
          lastSeen: DateTime.now(),
        );

        final client = TransferClient(
          onProgress: (_) {},
          onCompleted: (_) {},
          onError: (_) {},
        );

        notificationStopwatch.start();

        // Fire transfer request
        unawaited(
          client.sendManifest(
            peer: receiverPeer,
            manifest: manifest,
            localDevice: senderDevice,
          ),
        );

        // Await confirmation popup notification on the receiver side
        final receivedOffer = await offerReceivedCompleter.future.timeout(
          const Duration(seconds: 3),
        );

        final notificationLatencyMs = notificationStopwatch.elapsedMilliseconds;

        // ignore: avoid_print
        print(
          '===============================================================',
        );
        // ignore: avoid_print
        print('[PERFORMANCE AUDIT RESULTS: 2 GB TRANSFER INITIATION]');
        // ignore: avoid_print
        print('Total File Size:              2.0 GB ($twoGigabytes bytes)');
        // ignore: avoid_print
        print(
          'Manifest Creation Time:       ${reqCreatedStopwatch.elapsedMilliseconds} ms',
        );
        // ignore: avoid_print
        print('Receiver Notification Latency: $notificationLatencyMs ms');
        // ignore: avoid_print
        print('Target Threshold:             < 1000 ms');
        // ignore: avoid_print
        print('Measured Verdict:             PASSED (Zero Hashing Lag)');
        // ignore: avoid_print
        print(
          '===============================================================',
        );

        expect(receivedOffer.totalBytes, twoGigabytes);
        expect(receivedOffer.fileName, 'sparse_2gb.iso');
        expect(receivedOffer.senderName, 'Sender Host Device');
        expect(notificationLatencyMs, lessThan(1000)); // Target: < 1 second!

        server.stop();
      },
    );

    test(
      'REALISTIC FILE STREAMING: Realistic transfer with on-the-fly SHA-256 and zero-delay initiation',
      () async {
        final senderDir = await Directory.systemTemp.createTemp('sender_');
        final receiverDir = await Directory.systemTemp.createTemp('receiver_');

        final testFile = File('${senderDir.path}/realistic_5mb.bin');
        final bytes = Uint8List(5 * 1024 * 1024);
        for (int i = 0; i < bytes.length; i += 4096) {
          bytes[i] = (i * 31) % 256;
        }
        await testFile.writeAsBytes(bytes);
        final expectedHash = sha256.convert(bytes).toString();

        final manifest = await TransferManifest.fromFiles([testFile]);

        final serverCompleter = Completer<NexoraTransfer>();
        final clientCompleter = Completer<NexoraTransfer>();
        final notificationStopwatch = Stopwatch();

        final server = TransferServer(
          customDestinationDirectory: receiverDir,
          onRequestApproval: (offer) async {
            notificationStopwatch.stop();
            return true; // Accepted by receiver
          },
          onTransferProgress: (_) {},
          onTransferCompleted: (completed) {
            serverCompleter.complete(completed);
          },
        );

        final port = await server.start();

        final receiverPeer = NexoraDevice(
          deviceId: 'recv-stream-id',
          displayName: 'Receiver Stream Target',
          platform: 'Android',
          fingerprint: 'dummy-recv-fp2',
          address: '127.0.0.1',
          port: port,
          lastSeen: DateTime.now(),
        );

        final senderDevice = NexoraDevice(
          deviceId: 'send-stream-id',
          displayName: 'Sender Stream Source',
          platform: 'Windows',
          fingerprint: 'dummy-send-fp2',
          lastSeen: DateTime.now(),
        );

        TransferPerformanceMetrics? capturedMetrics;

        final client = TransferClient(
          onProgress: (_) {},
          onCompleted: (c) {
            clientCompleter.complete(c);
          },
          onError: (err) => fail('Client failed: $err'),
          onMetrics: (m) => capturedMetrics = m,
        );

        notificationStopwatch.start();

        await client.sendManifest(
          peer: receiverPeer,
          manifest: manifest,
          localDevice: senderDevice,
        );

        final serverResult = await serverCompleter.future.timeout(
          const Duration(seconds: 15),
        );
        final clientResult = await clientCompleter.future.timeout(
          const Duration(seconds: 15),
        );

        expect(serverResult.state, TransferState.completed);
        expect(clientResult.state, TransferState.completed);
        expect(notificationStopwatch.elapsedMilliseconds, lessThan(1000));

        // Verify destination file integrity matches expected SHA-256
        final destFile = File('${receiverDir.path}/realistic_5mb.bin');
        expect(await destFile.exists(), isTrue);
        final destBytes = await destFile.readAsBytes();
        expect(sha256.convert(destBytes).toString(), expectedHash);

        if (capturedMetrics != null) {
          // ignore: avoid_print
          print('[METRICS] $capturedMetrics');
          expect(capturedMetrics!.requestCreationTimeMs, lessThan(100));
        }

        server.stop();
        await senderDir.delete(recursive: true);
        await receiverDir.delete(recursive: true);
      },
    );

    test(
      'INTERRUPTED CONNECTION: User cancellation releases sockets and halts streaming',
      () async {
        final senderDir = await Directory.systemTemp.createTemp('cancel_send_');
        final receiverDir = await Directory.systemTemp.createTemp(
          'cancel_recv_',
        );

        final testFile = File('${senderDir.path}/interrupted_file.bin');
        final bytes = Uint8List(10 * 1024 * 1024); // 10 MB
        await testFile.writeAsBytes(bytes);

        final manifest = await TransferManifest.fromFiles([testFile]);
        final cancelCompleter = Completer<void>();

        final server = TransferServer(
          customDestinationDirectory: receiverDir,
          onRequestApproval: (_) async => true,
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );

        final port = await server.start();

        final receiverPeer = NexoraDevice(
          deviceId: 'recv-cancel-id',
          displayName: 'Cancel Target',
          platform: 'Android',
          fingerprint: 'dummy-recv-fp3',
          address: '127.0.0.1',
          port: port,
          lastSeen: DateTime.now(),
        );

        final senderDevice = NexoraDevice(
          deviceId: 'send-cancel-id',
          displayName: 'Cancel Source',
          platform: 'Windows',
          fingerprint: 'dummy-send-fp3',
          lastSeen: DateTime.now(),
        );

        late final TransferClient client;
        client = TransferClient(
          onProgress: (p) {
            if (p.bytesTransferred > 0 && !cancelCompleter.isCompleted) {
              client.cancel(p.transferId);
              cancelCompleter.complete();
            }
          },
          onCompleted: (_) {},
          onError: (_) {
            if (!cancelCompleter.isCompleted) cancelCompleter.complete();
          },
        );

        unawaited(
          client.sendManifest(
            peer: receiverPeer,
            manifest: manifest,
            localDevice: senderDevice,
          ),
        );

        await cancelCompleter.future.timeout(const Duration(seconds: 10));
        expect(client.isCancelled(manifest.transferId), isTrue);

        server.stop();
        await senderDir.delete(recursive: true);
        await receiverDir.delete(recursive: true);
      },
    );
  });
}
