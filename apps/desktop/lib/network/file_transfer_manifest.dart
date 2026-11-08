import 'dart:io';
import 'package:uuid/uuid.dart';

/// Resolves the MIME type of a file based on its extension without reading file contents.
String resolveMimeType(String fileName) {
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'svg':
      return 'image/svg+xml';
    case 'mp4':
      return 'video/mp4';
    case 'mkv':
      return 'video/x-matroska';
    case 'webm':
      return 'video/webm';
    case 'avi':
      return 'video/x-msvideo';
    case 'mov':
      return 'video/quicktime';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'flac':
      return 'audio/flac';
    case 'aac':
      return 'audio/aac';
    case 'm4a':
      return 'audio/mp4';
    case 'pdf':
      return 'application/pdf';
    case 'zip':
      return 'application/zip';
    case 'tar':
      return 'application/x-tar';
    case 'gz':
      return 'application/gzip';
    case '7z':
      return 'application/x-7z-compressed';
    case 'apk':
      return 'application/vnd.android.package-archive';
    case 'exe':
      return 'application/x-msdownload';
    case 'txt':
      return 'text/plain';
    case 'json':
      return 'application/json';
    case 'doc':
    case 'docx':
      return 'application/msword';
    default:
      return 'application/octet-stream';
  }
}

class ManifestItem {
  final String fileId;
  final String name;
  final String? relativePath;
  final int sizeBytes;
  final String? mimeType;
  final String? sha256Hash;
  final String? localPath;

  const ManifestItem({
    required this.fileId,
    required this.name,
    this.relativePath,
    required this.sizeBytes,
    this.mimeType,
    this.sha256Hash,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'file_id': fileId,
    'name': name,
    'relative_path': relativePath,
    'size_bytes': sizeBytes,
    'mime_type': mimeType ?? resolveMimeType(name),
    'sha256_hash': sha256Hash,
  };

  factory ManifestItem.fromJson(Map<String, dynamic> json) => ManifestItem(
    fileId: json['file_id'] as String,
    name: json['name'] as String,
    relativePath: json['relative_path'] as String?,
    sizeBytes: json['size_bytes'] as int,
    mimeType:
        json['mime_type'] as String? ??
        resolveMimeType(json['name'] as String? ?? ''),
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
      totalBytes:
          json['total_bytes'] as int? ??
          items.fold(0, (acc, f) => acc + f.sizeBytes),
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
      items.add(
        ManifestItem(
          fileId: const Uuid().v4(),
          name: name,
          relativePath: null,
          sizeBytes: size,
          mimeType: resolveMimeType(name),
          sha256Hash: null,
          localPath: file.path,
        ),
      );
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

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        final filePath = entity.path.replaceAll(r'\', '/');
        // Relative path inside the root folder
        final subPath = filePath
            .substring(rootPath.length)
            .replaceFirst(RegExp(r'^/'), '');
        final relativePath = '$rootFolder/$subPath';
        final size = await entity.length();
        final name = entity.path.split(RegExp(r'[\\/]')).last;

        totalBytes += size;
        items.add(
          ManifestItem(
            fileId: const Uuid().v4(),
            name: name,
            relativePath: relativePath,
            sizeBytes: size,
            mimeType: resolveMimeType(name),
            sha256Hash: null,
            localPath: entity.path,
          ),
        );
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
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  /// Sanitizes a filename, removing illegal characters and reserved words.
  static String sanitizeFilename(String filename) {
    var sanitized = filename
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // remove control chars
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // replace forbidden chars
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
      return File(
        '${destinationBaseDir.path}${Platform.pathSeparator}$sanitizedFileName',
      );
    }

    // Normalize forward slashes and split path components
    final normalized = relativePath.replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final safeSegments = <String>[];

    for (final seg in segments) {
      final trimmed = seg.trim();
      // Guard against path traversal
      if (trimmed.isEmpty ||
          trimmed == '.' ||
          trimmed == '..' ||
          trimmed.contains(':')) {
        continue;
      }
      safeSegments.add(sanitizeFilename(trimmed));
    }

    if (safeSegments.isEmpty) {
      return File(
        '${destinationBaseDir.path}${Platform.pathSeparator}$sanitizedFileName',
      );
    }

    // Replace final segment with sanitized filename
    safeSegments[safeSegments.length - 1] = sanitizedFileName;

    final subPath = safeSegments.join(Platform.pathSeparator);
    final targetPath =
        '${destinationBaseDir.path}${Platform.pathSeparator}$subPath';
    return File(targetPath);
  }
}
