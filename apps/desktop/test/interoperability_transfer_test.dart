import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/models/device_model.dart';
import 'package:nexora_desktop/models/transfer_model.dart';
import 'package:nexora_desktop/network/transfer_client.dart';
import 'package:nexora_desktop/network/transfer_server.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexora_interop_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Windows Sender -> Android Receiver: streams 2.5MB with verified SHA-256 integrity', () async {
    // 1. Create a 2.5MB test file on Windows sender
    final sourceFile = File('${tempDir.path}${Platform.pathSeparator}windows_export_doc.bin');
    final chunkPattern = utf8.encode('NEXORA_CROSS_PLATFORM_INTEROPERABILITY_PAYLOAD_BLOCK_');
    final bytesBuilder = BytesBuilder(copy: false);
    while (bytesBuilder.length < 2500000) {
      bytesBuilder.add(chunkPattern);
    }
    final originalBytes = bytesBuilder.toBytes().sublist(0, 2500000);
    await sourceFile.writeAsBytes(originalBytes);
    final expectedSha256 = sha256.convert(originalBytes).toString();

    // 2. Setup receiver representing Android device
    final receiverDestDir = Directory('${tempDir.path}${Platform.pathSeparator}android_downloads');
    await receiverDestDir.create();

    NexoraTransfer? receiverCompletedTransfer;
    final receiverServer = TransferServer(
      customDestinationDirectory: receiverDestDir,
      onRequestApproval: (offer) async => true,
      onTransferProgress: (_) {},
      onTransferCompleted: (completed) {
        receiverCompletedTransfer = completed;
      },
    );

    final receiverPort = await receiverServer.start();

    // 3. Setup Windows Sender Client
    NexoraTransfer? clientCompletedTransfer;
    final client = TransferClient(
      onProgress: (_) {},
      onCompleted: (completed) {
        clientCompletedTransfer = completed;
      },
      onError: (err) {
        fail('Client transfer error: $err');
      },
    );

    final androidPeer = NexoraDevice(
      deviceId: 'nexora-android-device-id',
      displayName: 'Pixel 9 Pro (NEXORA)',
      platform: 'Android',
      fingerprint: '3978f639c6b014243b0d142017243af5f7fb00112233445566778899aabbccdd',
      address: '127.0.0.1',
      port: receiverPort,
      lastSeen: DateTime.now(),
    );

    final windowsDevice = NexoraDevice(
      deviceId: 'nexora-windows-workstation',
      displayName: 'Windows Workstation (NEXORA)',
      platform: 'Windows',
      fingerprint: '14243b3978f639c6b00d142017243af5f7fb00112233445566778899aabbccdd',
      lastSeen: DateTime.now(),
    );

    // 4. Execute file transmission
    await client.sendFile(
      peer: androidPeer,
      file: sourceFile,
      localDevice: windowsDevice,
    );

    // Give asynchronous server stream handlers a moment to complete
    await Future.delayed(const Duration(milliseconds: 300));

    // 5. Verify assertions
    expect(clientCompletedTransfer, isNotNull);
    expect(clientCompletedTransfer!.totalBytes, equals(2500000));
    expect(clientCompletedTransfer!.bytesTransferred, equals(2500000));

    expect(receiverCompletedTransfer, isNotNull);
    expect(receiverCompletedTransfer!.totalBytes, equals(2500000));

    // Verify written file on receiver's disk
    final receivedFile = File('${receiverDestDir.path}${Platform.pathSeparator}windows_export_doc.bin');
    expect(await receivedFile.exists(), isTrue);
    final receivedBytes = await receivedFile.readAsBytes();
    expect(receivedBytes.length, equals(2500000));

    // Verify SHA-256 match
    final actualReceivedSha256 = sha256.convert(receivedBytes).toString();
    expect(actualReceivedSha256, equals(expectedSha256));

    receiverServer.stop();
  });

  test('Android Sender -> Windows Receiver: streams file and Windows verifies SHA-256', () async {
    // 1. Setup Windows Receiver Server
    final windowsDestDir = Directory('${tempDir.path}${Platform.pathSeparator}windows_downloads');
    await windowsDestDir.create();

    IncomingTransferOffer? receivedOffer;
    NexoraTransfer? windowsCompletedTransfer;

    final windowsServer = TransferServer(
      customDestinationDirectory: windowsDestDir,
      onRequestApproval: (offer) async {
        receivedOffer = offer;
        return true;
      },
      onTransferProgress: (_) {},
      onTransferCompleted: (completed) {
        windowsCompletedTransfer = completed;
      },
    );

    final serverPort = await windowsServer.start();

    // 2. Setup Android Sender File
    final androidFile = File('${tempDir.path}${Platform.pathSeparator}camera_photo.jpg');
    final payloadBytes = utf8.encode('ANDROID_JPEG_STREAM_SIMULATION_RAW_BYTES_VALIDATION');
    await androidFile.writeAsBytes(payloadBytes);
    final expectedSha256 = sha256.convert(payloadBytes).toString();

    final androidLocalDevice = NexoraDevice(
      deviceId: 'nexora-android-local',
      displayName: 'Samsung Galaxy S24 (NEXORA)',
      platform: 'Android',
      fingerprint: 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      lastSeen: DateTime.now(),
    );

    final windowsTargetPeer = NexoraDevice(
      deviceId: 'nexora-windows-workstation',
      displayName: 'Windows Workstation (NEXORA)',
      platform: 'Windows',
      fingerprint: '14243b3978f639c6b00d142017243af5f7fb00112233445566778899aabbccdd',
      address: '127.0.0.1',
      port: serverPort,
      lastSeen: DateTime.now(),
    );

    // 3. Initiate Transfer from Android Client
    NexoraTransfer? androidCompletedTransfer;
    final androidClient = TransferClient(
      onProgress: (_) {},
      onCompleted: (c) {
        androidCompletedTransfer = c;
      },
      onError: (err) => fail(err),
    );

    await androidClient.sendFile(
      peer: windowsTargetPeer,
      file: androidFile,
      localDevice: androidLocalDevice,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Assert Windows receiver behavior
    expect(receivedOffer, isNotNull);
    expect(receivedOffer!.fileName, equals('camera_photo.jpg'));
    expect(receivedOffer!.senderName, equals('Samsung Galaxy S24 (NEXORA)'));
    expect(windowsCompletedTransfer, isNotNull);
    expect(androidCompletedTransfer, isNotNull);

    // Verify saved file on Windows disk
    final savedFile = File('${windowsDestDir.path}${Platform.pathSeparator}camera_photo.jpg');
    expect(await savedFile.exists(), isTrue);
    final savedBytes = await savedFile.readAsBytes();
    expect(savedBytes, equals(payloadBytes));
    expect(sha256.convert(savedBytes).toString(), equals(expectedSha256));

    windowsServer.stop();
  });

  test('Receiver declines transfer offer: sender handles TransferReject gracefully', () async {
    final server = TransferServer(
      onRequestApproval: (offer) async => false, // Explicit decline
      onTransferProgress: (_) {},
      onTransferCompleted: (_) {},
    );
    final port = await server.start();

    final testFile = File('${tempDir.path}${Platform.pathSeparator}declined_doc.pdf');
    await testFile.writeAsString('Confidential document payload');

    String? capturedError;
    final client = TransferClient(
      onProgress: (_) {},
      onCompleted: (_) {},
      onError: (err) {
        capturedError = err;
      },
    );

    final peer = NexoraDevice(
      deviceId: 'peer-device',
      displayName: 'Peer Device',
      platform: 'Android',
      fingerprint: 'fp',
      address: '127.0.0.1',
      port: port,
      lastSeen: DateTime.now(),
    );

    final local = NexoraDevice(
      deviceId: 'local-device',
      displayName: 'Local PC',
      platform: 'Windows',
      fingerprint: 'fp',
      lastSeen: DateTime.now(),
    );

    await client.sendFile(peer: peer, file: testFile, localDevice: local);

    expect(capturedError, isNotNull);
    expect(capturedError, contains('declined'));

    server.stop();
  });

  test('Security: Oversized frame prefix (> 16MB) causes immediate socket drop', () async {
    final server = TransferServer(
      onRequestApproval: (_) async => true,
      onTransferProgress: (_) {},
      onTransferCompleted: (_) {},
    );
    final port = await server.start();

    final socket = await Socket.connect('127.0.0.1', port);

    // Send fraudulent frame length prefix claiming 64MB (> maxFrameSize 16MB)
    final evilPrefix = ByteData(4)..setUint32(0, 64 * 1024 * 1024, Endian.big);
    socket.add(evilPrefix.buffer.asUint8List());

    final completer = Completer<void>();
    socket.listen(
      (_) {},
      onDone: () => completer.complete(),
      onError: (_) => completer.complete(),
    );

    await completer.future.timeout(const Duration(seconds: 2));
    socket.destroy();
    server.stop();
  });
}
