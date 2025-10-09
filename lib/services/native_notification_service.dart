import 'package:flutter/services.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('fylgja/notifications');


  /// Shows the coverage notification using native Android code
  static Future<void> showCoverageNotification() async {
    try {
      print('NativeNotificationService: showCoverageNotification called');
      await _channel.invokeMethod('showCoverageNotification');
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

}
