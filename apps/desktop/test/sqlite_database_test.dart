import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_desktop/database/database_service.dart';
import 'package:nexora_desktop/models/device_model.dart';
import 'package:nexora_desktop/models/transfer_model.dart';

void main() {
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService.instance;
    await dbService.initialize(inMemory: true);
  });

  tearDown(() async {
    await dbService.close();
  });

  test('SQLite: Schema migrations and device trusted store', () async {
    final device = NexoraDevice(
      deviceId: 'test-device-uuid-1',
      displayName: 'Pixel 9 Pro (NEXORA)',
      platform: 'Android',
      fingerprint:
          '3978f639c6b014243b0d142017243af5f7fb00112233445566778899aabbccdd',
      lastSeen: DateTime.now(),
    );

    // Initial upsert (not trusted yet)
    await dbService.upsertDevice(device, isTrusted: false);
    var trustedList = await dbService.getTrustedDevices();
    expect(trustedList, isEmpty);

    // Mark device trusted
    await dbService.setDeviceTrust(device.deviceId, true);
    trustedList = await dbService.getTrustedDevices();
    expect(trustedList.length, equals(1));
    expect(trustedList.first.deviceId, equals(device.deviceId));
    expect(trustedList.first.displayName, equals('Pixel 9 Pro (NEXORA)'));

    // Revoke trust
    await dbService.setDeviceTrust(device.deviceId, false);
    trustedList = await dbService.getTrustedDevices();
    expect(trustedList, isEmpty);
  });

  test('SQLite: Transfer history logging and status progression', () async {
    final transfer = NexoraTransfer(
      transferId: 't-uuid-101',
      direction: TransferDirection.send,
      remoteDeviceId: 'remote-pc-1',
      remoteDeviceName: 'Linux Workstation',
      totalFiles: 3,
      totalBytes: 5242880,
      bytesTransferred: 0,
      currentFile: 'archive.tar.gz',
      state: TransferState.inProgress,
      createdAt: DateTime.now(),
    );

    await dbService.logTransfer(transfer);

    var history = await dbService.getTransferHistory();
    expect(history.length, equals(1));
    expect(history.first.transferId, equals('t-uuid-101'));
    expect(history.first.state, equals(TransferState.inProgress));

    // Update progress to completed
    await dbService.updateTransferProgress(
      't-uuid-101',
      5242880,
      TransferState.completed,
    );

    history = await dbService.getTransferHistory();
    expect(history.first.bytesTransferred, equals(5242880));
    expect(history.first.state, equals(TransferState.completed));
    expect(history.first.completedAt, isNotNull);
  });

  test('SQLite: Resume chunk checkpoints and offset tracking', () async {
    const transferId = 'resume-test-session-1';
    const fileId = 'f-100';

    await dbService.recordVerifiedChunk(
      transferId: transferId,
      fileId: fileId,
      chunkIndex: 0,
      chunkOffset: 0,
      chunkSize: 1048576,
      chunkSha256: 'chunk0hash',
    );

    var highestOffset = await dbService.getHighestVerifiedOffset(
      transferId,
      fileId,
    );
    expect(highestOffset, equals(1048576));

    await dbService.recordVerifiedChunk(
      transferId: transferId,
      fileId: fileId,
      chunkIndex: 1,
      chunkOffset: 1048576,
      chunkSize: 1048576,
      chunkSha256: 'chunk1hash',
    );

    highestOffset = await dbService.getHighestVerifiedOffset(
      transferId,
      fileId,
    );
    expect(highestOffset, equals(2097152));

    await dbService.clearResumeCheckpoints(transferId);
    highestOffset = await dbService.getHighestVerifiedOffset(
      transferId,
      fileId,
    );
    expect(highestOffset, equals(0));
  });

  test('SQLite: App settings persistence key-value store', () async {
    await dbService.setSetting('device_name', 'Windows Ultra PC');
    await dbService.setSetting('downloads_folder', 'C:\\Downloads\\NEXORA');

    final name = await dbService.getSetting('device_name');
    final folder = await dbService.getSetting('downloads_folder');
    final nonExistent = await dbService.getSetting('non_existent_key');

    expect(name, equals('Windows Ultra PC'));
    expect(folder, equals('C:\\Downloads\\NEXORA'));
    expect(nonExistent, isNull);
  });
}
