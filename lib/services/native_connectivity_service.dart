import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class NativeConnectivityService {
  static const MethodChannel _channel = MethodChannel('fylgja/connectivity');

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Starts native coverage detection, which reports on [NativeEventService]:
  /// on Android the foreground service, the only monitor that keeps working in
  /// deep sleep and standby; on iOS CoverageMonitor, which also keeps the app
  /// running while the screen is locked.
  ///
  /// Returns whether the search keeps running with the screen locked. On iOS
  /// that needs location access; without it the app is suspended as usual.
  static Future<bool> startMonitoring() async {
    if (!isSupported) {
      AppLogger.info('Native connectivity service is not supported here; skipping');
      return false;
    }
    try {
      final keepsRunning = await _channel.invokeMethod<bool>('startMonitoring');
      AppLogger.info('Native connectivity service started');
      // Android returns nothing; its foreground service always keeps running.
      return keepsRunning ?? true;
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
