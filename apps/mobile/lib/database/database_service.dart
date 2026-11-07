import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Database? _db;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Database get db {
    if (_db == null) {
      throw StateError(
        'DatabaseService has not been initialized. Call initialize() first.',
      );
    }
    return _db!;
  }

  /// Initializes the SQLite database. If [inMemory] is true, uses an in-memory database for tests.
  Future<void> initialize({bool inMemory = false, String? customPath}) async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (inMemory) {
      path = inMemoryDatabasePath;
    } else if (customPath != null) {
      path = customPath;
    } else {
      Directory docDir;
      try {
        docDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        docDir = Directory.systemTemp;
      }
      final nexoraDir = Directory(
        '${docDir.path}${Platform.pathSeparator}NEXORA',
      );
      if (!await nexoraDir.exists()) {
        await nexoraDir.create(recursive: true);
      }
      path = '${nexoraDir.path}${Platform.pathSeparator}nexora.db';
    }

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _runMigrations(db, 0, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    final batch = db.batch();

    if (oldVersion < 1) {
      // Schema migrations tracker
      batch.execute('''
        CREATE TABLE IF NOT EXISTS schema_migrations (
          version INTEGER PRIMARY KEY,
          applied_at TEXT NOT NULL
        )
      ''');

      // Devices
      batch.execute('''
        CREATE TABLE IF NOT EXISTS devices (
          device_id TEXT PRIMARY KEY,
          display_name TEXT NOT NULL,
          platform TEXT NOT NULL,
          fingerprint TEXT NOT NULL,
          is_trusted INTEGER NOT NULL DEFAULT 0,
          paired_at TEXT,
          last_seen TEXT NOT NULL
        )
      ''');

      // Transfers
      batch.execute('''
        CREATE TABLE IF NOT EXISTS transfers (
          transfer_id TEXT PRIMARY KEY,
          direction TEXT NOT NULL,
          remote_device_id TEXT NOT NULL,
          remote_device_name TEXT NOT NULL,
          total_files INTEGER NOT NULL,
          total_bytes INTEGER NOT NULL,
          bytes_transferred INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          completed_at TEXT
        )
      ''');

      // Transfer Files (for multi-file and folder transfers)
      batch.execute('''
        CREATE TABLE IF NOT EXISTS transfer_files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transfer_id TEXT NOT NULL,
          file_id TEXT NOT NULL,
          filename TEXT NOT NULL,
          relative_path TEXT,
          size_bytes INTEGER NOT NULL,
          bytes_transferred INTEGER NOT NULL DEFAULT 0,
          sha256_hash TEXT,
          status TEXT NOT NULL,
          FOREIGN KEY(transfer_id) REFERENCES transfers(transfer_id) ON DELETE CASCADE
        )
      ''');

      // Resume Chunks (checkpoint state for interrupted streams)
      batch.execute('''
        CREATE TABLE IF NOT EXISTS resume_chunks (
          transfer_id TEXT NOT NULL,
          file_id TEXT NOT NULL,
          chunk_index INTEGER NOT NULL,
          chunk_offset INTEGER NOT NULL,
          chunk_size INTEGER NOT NULL,
          chunk_sha256 TEXT NOT NULL,
          verified_at TEXT NOT NULL,
          PRIMARY KEY (transfer_id, file_id, chunk_index)
        )
      ''');

      // Settings
      batch.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      batch.insert('schema_migrations', {
        'version': 1,
        'applied_at': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  // --- Device Store ---
  Future<void> upsertDevice(NexoraDevice device, {bool? isTrusted}) async {
    final now = DateTime.now().toIso8601String();
    await db.rawInsert(
      '''
      INSERT INTO devices (device_id, display_name, platform, fingerprint, is_trusted, paired_at, last_seen)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(device_id) DO UPDATE SET
        display_name = excluded.display_name,
        platform = excluded.platform,
        fingerprint = excluded.fingerprint,
        is_trusted = COALESCE(?, devices.is_trusted),
        last_seen = excluded.last_seen
    ''',
      [
        device.deviceId,
        device.displayName,
        device.platform,
        device.fingerprint,
        isTrusted == true ? 1 : 0,
        isTrusted == true ? now : null,
        now,
        isTrusted == null ? null : (isTrusted ? 1 : 0),
      ],
    );
  }

  Future<List<NexoraDevice>> getTrustedDevices() async {
    final rows = await db.query(
      'devices',
      where: 'is_trusted = 1',
      orderBy: 'display_name ASC',
    );
    return rows.map((r) {
      return NexoraDevice(
        deviceId: r['device_id'] as String,
        displayName: r['display_name'] as String,
        platform: r['platform'] as String,
        fingerprint: r['fingerprint'] as String,
        lastSeen: DateTime.parse(r['last_seen'] as String),
      );
    }).toList();
  }

  Future<void> setDeviceTrust(String deviceId, bool isTrusted) async {
    final now = DateTime.now().toIso8601String();
    await db.update(
      'devices',
      {'is_trusted': isTrusted ? 1 : 0, 'paired_at': isTrusted ? now : null},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  // --- Transfer History Store ---
  Future<void> logTransfer(NexoraTransfer transfer) async {
    await db.insert('transfers', {
      'transfer_id': transfer.transferId,
      'direction': transfer.direction == TransferDirection.send
          ? 'send'
          : 'receive',
      'remote_device_id': transfer.remoteDeviceId,
      'remote_device_name': transfer.remoteDeviceName,
      'total_files': transfer.totalFiles,
      'total_bytes': transfer.totalBytes,
      'bytes_transferred': transfer.bytesTransferred,
      'status': transfer.state.name,
      'created_at': transfer.createdAt.toIso8601String(),
      'completed_at': transfer.completedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTransferProgress(
    String transferId,
    int bytesTransferred,
    TransferState state,
  ) async {
    await db.update(
      'transfers',
      {
        'bytes_transferred': bytesTransferred,
        'status': state.name,
        if (state == TransferState.completed)
          'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'transfer_id = ?',
      whereArgs: [transferId],
    );
  }

  Future<List<NexoraTransfer>> getTransferHistory() async {
    final rows = await db.query(
      'transfers',
      orderBy: 'created_at DESC',
      limit: 100,
    );
    return rows.map((r) {
      final dirStr = r['direction'] as String;
      final stateStr = r['status'] as String;
      return NexoraTransfer(
        transferId: r['transfer_id'] as String,
        direction: dirStr == 'send'
            ? TransferDirection.send
            : TransferDirection.receive,
        remoteDeviceId: r['remote_device_id'] as String,
        remoteDeviceName: r['remote_device_name'] as String,
        totalFiles: r['total_files'] as int,
        totalBytes: r['total_bytes'] as int,
        bytesTransferred: r['bytes_transferred'] as int,
        currentFile: '',
        state: TransferState.values.firstWhere(
          (s) => s.name == stateStr,
          orElse: () => TransferState.completed,
        ),
        createdAt: DateTime.parse(r['created_at'] as String),
        completedAt: r['completed_at'] != null
            ? DateTime.parse(r['completed_at'] as String)
            : null,
      );
    }).toList();
  }

  // --- Resume Checkpoint Store ---
  Future<void> recordVerifiedChunk({
    required String transferId,
    required String fileId,
    required int chunkIndex,
    required int chunkOffset,
    required int chunkSize,
    required String chunkSha256,
  }) async {
    await db.insert('resume_chunks', {
      'transfer_id': transferId,
      'file_id': fileId,
      'chunk_index': chunkIndex,
      'chunk_offset': chunkOffset,
      'chunk_size': chunkSize,
      'chunk_sha256': chunkSha256,
      'verified_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getHighestVerifiedOffset(String transferId, String fileId) async {
    final result = await db.rawQuery(
      '''
      SELECT MAX(chunk_offset + chunk_size) as highest_offset
      FROM resume_chunks
      WHERE transfer_id = ? AND file_id = ?
    ''',
      [transferId, fileId],
    );

    if (result.isNotEmpty && result.first['highest_offset'] != null) {
      return result.first['highest_offset'] as int;
    }
    return 0;
  }

  Future<void> clearResumeCheckpoints(String transferId) async {
    await db.delete(
      'resume_chunks',
      where: 'transfer_id = ?',
      whereArgs: [transferId],
    );
  }

  // --- Settings Store ---
  Future<void> setSetting(String key, String value) async {
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['value'] as String?;
    }
    return null;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
