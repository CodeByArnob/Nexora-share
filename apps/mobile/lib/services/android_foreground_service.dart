import 'dart:io';
import 'package:flutter/services.dart';

class AndroidForegroundService {
  static const _channel = MethodChannel(
    'io.github.codebyarnob.nexora/foreground_service',
  );

  /// Starts the Android Foreground Service with an ongoing notification.
  static Future<void> startService({
    required String fileName,
    required bool isSending,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService', {
        'fileName': fileName,
        'isSending': isSending,
      });
    } on PlatformException catch (_) {
      // Ignored if permissions not yet granted
    }
  }

  /// Updates ongoing transfer notification progress and speed.
  static Future<void> updateProgress({
    required String fileName,
    required int progressPercent,
    required String speed,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateProgress', {
        'fileName': fileName,
        'progress': progressPercent,
        'speed': speed,
      });
    } on PlatformException catch (_) {
      // Ignored
    }
  }

  /// Stops the Foreground Service once the transfer completes or is cancelled.
  static Future<void> stopService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (_) {
      // Ignored
    }
  }
}
