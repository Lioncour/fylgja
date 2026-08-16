import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('fylgja/notifications');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Shows the coverage notification using native Android code.
  /// [showNotification] - if false, only plays sound/vibration without showing notification.
  static Future<void> showCoverageNotification({bool showNotification = true}) async {
    if (!isSupported) {
      AppLogger.info('Native coverage notification is Android-only; skipping');
      return;
    }
    try {
      await _channel.invokeMethod('showCoverageNotification', {
        'showNotification': showNotification,
      });
      AppLogger.info('Coverage notification sent');
    } catch (e) {
      AppLogger.error('Error showing coverage notification', e);
    }
  }

  static Future<void> cancelNotification() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod('cancelNotification');
      AppLogger.info('Coverage notification cancelled');
    } catch (e) {
      AppLogger.error('Error cancelling notification', e);
    }
  }

  static Future<void> stopSound() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod('stopSound');
      AppLogger.info('Coverage sound stopped');
    } catch (e) {
      AppLogger.error('Error stopping sound', e);
    }
  }
}
