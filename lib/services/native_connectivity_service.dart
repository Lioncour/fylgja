import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class NativeConnectivityService {
  static const MethodChannel _channel = MethodChannel('fylgja/connectivity');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Start the native Android foreground service for connectivity monitoring.
  /// This is the only monitor that keeps working in deep sleep and standby.
  static Future<void> startMonitoring() async {
    if (!isSupported) {
      AppLogger.info('Native connectivity service is Android-only; skipping');
      return;
    }
    try {
      await _channel.invokeMethod('startMonitoring');
      AppLogger.info('Native connectivity service started');
    } catch (e) {
      AppLogger.error('Error starting native connectivity service', e);
      rethrow;
    }
  }

  /// Stop the native Android foreground service and any active alert.
  static Future<void> stopMonitoring() async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod('stopMonitoring');
      AppLogger.info('Native connectivity service stopped');
    } catch (e) {
      AppLogger.error('Error stopping native connectivity service', e);
      rethrow;
    }
  }
}
