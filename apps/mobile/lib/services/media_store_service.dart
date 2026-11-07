import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel(
    'io.github.codebyarnob.nexora/media_store',
  );

  /// Resolves the public Nexora download directory where received files should be stored.
  /// On Android, returns /storage/emulated/0/Download/Nexora so files are user-accessible.
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final String? path = await _channel.invokeMethod<String>(
          'getPublicDownloadDirectory',
        );
        if (path != null && path.isNotEmpty) {
          final dir = Directory(path);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (_) {}

      // Fallback: check standard external storage download path
      final standardDownload = Directory(
        '/storage/emulated/0/Download/Nexora',
      );
      try {
        if (!await standardDownload.exists()) {
          await standardDownload.create(recursive: true);
        }
        return standardDownload;
      } catch (_) {}
    }

    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final nexoraDir = Directory('${ext.path}/Nexora');
        if (!await nexoraDir.exists()) {
          await nexoraDir.create(recursive: true);
        }
        return nexoraDir;
      }
    } catch (_) {}

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final nexoraDir = Directory('${docDir.path}/Nexora');
      if (!await nexoraDir.exists()) {
        await nexoraDir.create(recursive: true);
      }
      return nexoraDir;
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Tells the Android MediaStore to scan the newly downloaded file so it immediately
  /// appears in Google Photos, Gallery, and Video Players.
  static Future<void> scanFile(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      final ext = filePath.split('.').last.toLowerCase();
      String? mimeType;
      if (['jpg', 'jpeg'].contains(ext)) {
        mimeType = 'image/jpeg';
      } else if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'gif') {
        mimeType = 'image/gif';
      } else if (ext == 'mp4') {
        mimeType = 'video/mp4';
      } else if (ext == 'mkv') {
        mimeType = 'video/x-matroska';
      } else if (ext == 'mov') {
        mimeType = 'video/quicktime';
      } else if (ext == '3gp') {
        mimeType = 'video/3gpp';
      } else if (ext == 'avi') {
        mimeType = 'video/x-msvideo';
      } else if (ext == 'mp3') {
        mimeType = 'audio/mpeg';
      } else if (ext == 'wav') {
        mimeType = 'audio/wav';
      } else if (ext == 'pdf') {
        mimeType = 'application/pdf';
      }

      await _channel.invokeMethod('scanFile', {
        'path': filePath,
        'mimeType': mimeType,
      });
    } catch (_) {}
  }
}
