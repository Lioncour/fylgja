import 'package:flutter/services.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('fylgja/notifications');


  /// Shows the coverage notification using native Android code
  /// [showNotification] - if false, only plays sound/vibration without showing notification
  static Future<void> showCoverageNotification({bool showNotification = true}) async {
    try {
      print('NativeNotificationService: showCoverageNotification called, showNotification: $showNotification');
      await _channel.invokeMethod('showCoverageNotification', {'showNotification': showNotification});
      print('NativeNotificationService: ✅ Coverage notification sent successfully!');
    } catch (e) {
      print('NativeNotificationService: ❌ Error showing coverage notification: $e');
    }
  }


  /// Cancels the coverage notification
  static Future<void> cancelNotification() async {
    try {
      print('NativeNotificationService: cancelNotification called');
      await _channel.invokeMethod('cancelNotification');
      print('NativeNotificationService: ✅ Notification cancelled');
    } catch (e) {
      print('NativeNotificationService: ❌ Error cancelling notification: $e');
    }
  }

  /// Stops all sound and vibration (for pause/stop)
  static Future<void> stopSound() async {
    try {
      print('NativeNotificationService: ===== STOP SOUND CALLED =====');
      print('NativeNotificationService: Timestamp: ${DateTime.now().toIso8601String()}');
      print('NativeNotificationService: Invoking method channel: stopSound');
      await _channel.invokeMethod('stopSound');
      print('NativeNotificationService: ✅ Method channel invoke completed');
      print('NativeNotificationService: ===== STOP SOUND COMPLETE =====');
    } catch (e, stackTrace) {
      print('NativeNotificationService: ❌ ERROR stopping sound: $e');
      print('NativeNotificationService: Stack trace: $stackTrace');
    }
  }

}
