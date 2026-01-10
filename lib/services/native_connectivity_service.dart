import 'package:flutter/services.dart';

class NativeConnectivityService {
  static const MethodChannel _channel = MethodChannel('fylgja/connectivity');
  
  /// Start the native Android foreground service for connectivity monitoring
  static Future<void> startMonitoring() async {
    try {
      print('NativeConnectivityService: ===== STARTING NATIVE SERVICE =====');
      print('NativeConnectivityService: This works in deep sleep/standby/folded mode!');
      await _channel.invokeMethod('startMonitoring');
      print('NativeConnectivityService: ✅ Service started - works in all states');
    } catch (e) {
      print('NativeConnectivityService: ❌ Error: $e');
      rethrow;
    }
  }
  
  /// Stop the native Android foreground service
  static Future<void> stopMonitoring() async {
    try {
      print('NativeConnectivityService: ===== STOPPING NATIVE SERVICE =====');
      print('NativeConnectivityService: This will stop all alerts and vibration');
      await _channel.invokeMethod('stopMonitoring');
      print('NativeConnectivityService: ✅ Service stopped - all alerts disabled');
    } catch (e) {
      print('NativeConnectivityService: ❌ Error: $e');
      rethrow;
    }
  }
}

