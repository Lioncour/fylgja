import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class NativeConnectivityService {
  static const MethodChannel _channel = MethodChannel('fylgja/connectivity');

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// On Android, starts the native foreground service for connectivity
  /// monitoring, the only monitor that keeps working in deep sleep and standby.
  /// On iOS, starts BackgroundKeepAlive, which keeps the app (and so the Dart
  /// monitoring) running while the screen is locked.
  static Future<void> startMonitoring() async {
    if (!isSupported) {
      AppLogger.info('Native connectivity service is not supported here; skipping');
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

  /// Stop the native monitoring (and on Android any active alert).
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
