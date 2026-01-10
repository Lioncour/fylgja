import 'package:flutter/services.dart';

/// Utility class for haptic feedback
class HapticFeedbackUtil {
  /// Light haptic feedback for button presses
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback for important actions
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback for critical events (coverage found)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for UI interactions
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate feedback for notifications
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
