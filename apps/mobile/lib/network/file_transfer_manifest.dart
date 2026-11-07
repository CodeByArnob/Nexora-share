import 'dart:io';
import 'package:uuid/uuid.dart';

class ManifestItem {
  final String fileId;
  final String name;
  final String? relativePath;
  final int sizeBytes;
  final String? sha256Hash;
  final String? localPath;

  const ManifestItem({
    required this.fileId,
    required this.name,
    this.relativePath,
    required this.sizeBytes,
    this.sha256Hash,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
        'file_id': fileId,
        'name': name,
        'relative_path': relativePath,
        'size_bytes': sizeBytes,
        'sha256_hash': sha256Hash,
      };

  factory ManifestItem.fromJson(Map<String, dynamic> json) => ManifestItem(
        fileId: json['file_id'] as String,
        name: json['name'] as String,
        relativePath: json['relative_path'] as String?,
        sizeBytes: json['size_bytes'] as int,
        sha256Hash: json['sha256_hash'] as String?,
      );
}

class TransferManifest {
  final String transferId;
  final List<ManifestItem> files;
  final int totalFiles;
  final int totalBytes;

  const TransferManifest({
    required this.transferId,
    required this.files,
    required this.totalFiles,
    required this.totalBytes,
  });

  Map<String, dynamic> toJson() => {
        'transfer_id': transferId,
        'total_files': totalFiles,
        'total_bytes': totalBytes,
        'files': files.map((f) => f.toJson()).toList(),
      };

  factory TransferManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = (json['files'] as List).cast<Map<String, dynamic>>();
    final items = rawFiles.map(ManifestItem.fromJson).toList();
    return TransferManifest(
      transferId: json['transfer_id'] as String,
      files: items,
      totalFiles: json['total_files'] as int? ?? items.length,
      totalBytes: json['total_bytes'] as int? ?? items.fold(0, (acc, f) => acc + f.sizeBytes),
    );
  }

  /// Builds a manifest from a collection of loose files.
  static Future<TransferManifest> fromFiles(List<File> files) async {
    final transferId = const Uuid().v4();
    final items = <ManifestItem>[];
    int totalBytes = 0;

    for (final file in files) {
      if (!await file.exists()) continue;
      final size = await file.length();
      final name = file.path.split(RegExp(r'[\\/]')).last;
      totalBytes += size;
      items.add(ManifestItem(
        fileId: const Uuid().v4(),
        name: name,
        relativePath: null,
        sizeBytes: size,
        localPath: file.path,
      ));
    }

    return TransferManifest(
      transferId: transferId,
      files: items,
      totalFiles: items.length,
      totalBytes: totalBytes,
    );
  }

  /// Recursively scans a directory and builds a manifest preserving relative subfolder hierarchy.
  static Future<TransferManifest> fromDirectory(Directory directory) async {
    final transferId = const Uuid().v4();
    final items = <ManifestItem>[];
    int totalBytes = 0;

    final rootPath = directory.path.replaceAll(r'\', '/');
    final rootFolder = rootPath.split('/').last;

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final filePath = entity.path.replaceAll(r'\', '/');
        // Relative path inside the root folder
        final subPath = filePath.substring(rootPath.length).replaceFirst(RegExp(r'^/'), '');
        final relativePath = '$rootFolder/$subPath';
        final size = await entity.length();
        final name = entity.path.split(RegExp(r'[\\/]')).last;

        totalBytes += size;
        items.add(ManifestItem(
          fileId: const Uuid().v4(),
          name: name,
          relativePath: relativePath,
          sizeBytes: size,
          localPath: entity.path,
        ));
      }
    }

    return TransferManifest(
      transferId: transferId,
      files: items,
      totalFiles: items.length,
      totalBytes: totalBytes,
    );
  }
}

/// Validates and sanitizes received relative paths, preventing path traversal attacks.
class PathSanitizer {
  static const _windowsReserved = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
  };

  /// Sanitizes a filename, removing illegal characters and reserved words.
  static String sanitizeFilename(String filename) {
    var sanitized = filename
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // remove control chars
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')    // replace forbidden chars
        .trim();

    if (sanitized.isEmpty) {
      sanitized = 'unnamed_file';
    }

    final upper = sanitized.toUpperCase();
    final baseName = upper.split('.').first;
    if (_windowsReserved.contains(baseName)) {
      sanitized = '_$sanitized';
    }

    return sanitized;
  }

  /// Resolves the absolute destination file path safely within [destinationBaseDir].
  ///
  /// Rejects directory traversal attempts (`..`, root slashes, Windows drive letters).
  static File resolveSafePath({
    required Directory destinationBaseDir,
    required String filename,
    String? relativePath,
  }) {
    final sanitizedFileName = sanitizeFilename(filename);

    if (relativePath == null || relativePath.trim().isEmpty) {
      return File('${destinationBaseDir.path}${Platform.pathSeparator}$sanitizedFileName');
    }

    // Normalize forward slashes and split path components
    final normalized = relativePath.replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final safeSegments = <String>[];

    for (final seg in segments) {
      final trimmed = seg.trim();
      // Guard against path traversal
      if (trimmed.isEmpty || trimmed == '.' || trimmed == '..' || trimmed.contains(':')) {
        continue;
      }
      safeSegments.add(sanitizeFilename(trimmed));
    }

    if (safeSegments.isEmpty) {
      return File('${destinationBaseDir.path}${Platform.pathSeparator}$sanitizedFileName');
    }

    // Replace final segment with sanitized filename
    safeSegments[safeSegments.length - 1] = sanitizedFileName;

    final subPath = safeSegments.join(Platform.pathSeparator);
    final targetPath = '${destinationBaseDir.path}${Platform.pathSeparator}$subPath';
    return File(targetPath);
  }
}
