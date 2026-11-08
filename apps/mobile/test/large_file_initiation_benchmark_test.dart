import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_app/models/device_model.dart';
import 'package:nexora_app/network/file_transfer_manifest.dart';
import 'package:nexora_app/network/transfer_client.dart';
import 'package:nexora_app/network/transfer_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Large-File Transfer Initiation Latency Benchmarks', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nexora_mobile_perf_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test(
      'BENCHMARK: 2 GB Sparse File Mobile Initiation Latency is < 1 second',
      () async {
        final largeFile = File('${tempDir.path}/mobile_sparse_2gb.iso');
        final raf = await largeFile.open(mode: FileMode.write);
        const int twoGigabytes = 2 * 1024 * 1024 * 1024;
        await raf.setPosition(twoGigabytes - 1);
        await raf.writeByte(0x7F);
        await raf.close();

        expect(await largeFile.length(), twoGigabytes);

        final reqCreatedStopwatch = Stopwatch()..start();
        final manifest = await TransferManifest.fromFiles([largeFile]);
        reqCreatedStopwatch.stop();

        expect(reqCreatedStopwatch.elapsedMilliseconds, lessThan(50));
        expect(manifest.totalBytes, twoGigabytes);
        expect(manifest.files.first.sizeBytes, twoGigabytes);
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
            return false;
          },
          onTransferProgress: (_) {},
          onTransferCompleted: (_) {},
        );

        final port = await server.start();

        final receiverPeer = NexoraDevice(
          deviceId: 'receiver-mobile-bench',
          displayName: 'Receiver Mobile Bench',
          platform: 'Android',
          fingerprint: 'dummy-recv-fp',
          address: '127.0.0.1',
          port: port,
          lastSeen: DateTime.now(),
        );

        final senderDevice = NexoraDevice(
          deviceId: 'sender-mobile-bench',
          displayName: 'Sender Mobile Bench',
          platform: 'Android',
          fingerprint: 'dummy-send-fp',
          lastSeen: DateTime.now(),
        );

        final client = TransferClient(
          onProgress: (_) {},
          onCompleted: (_) {},
          onError: (_) {},
        );

        notificationStopwatch.start();

        unawaited(
          client.sendManifest(
            peer: receiverPeer,
            manifest: manifest,
            localDevice: senderDevice,
          ),
        );

        final receivedOffer = await offerReceivedCompleter.future.timeout(
          const Duration(seconds: 3),
        );

        final latencyMs = notificationStopwatch.elapsedMilliseconds;
        // ignore: avoid_print
        print(
          '===============================================================',
        );
        // ignore: avoid_print
        print('[MOBILE BENCHMARK: 2 GB FILE INITIATION LATENCY]');
        // ignore: avoid_print
        print(
          'Manifest Creation Time: ${reqCreatedStopwatch.elapsedMilliseconds} ms',
        );
        // ignore: avoid_print
        print('Receiver Notification Latency: $latencyMs ms');
        // ignore: avoid_print
        print('Target Threshold: < 1000 ms');
        // ignore: avoid_print
        print(
          '===============================================================',
        );

        expect(receivedOffer.totalBytes, twoGigabytes);
        expect(receivedOffer.fileName, 'mobile_sparse_2gb.iso');
        expect(latencyMs, lessThan(1000));

        server.stop();
      },
    );
  });
}
