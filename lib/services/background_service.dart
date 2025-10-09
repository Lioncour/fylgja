import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static bool _wasConnected = false;
  static bool _isPaused = false;
  static bool _coverageAlreadyFound = false;
  static Timer? _pauseTimer;
  static Timer? _monitoringTimer;
  static Timer? _initialCheckTimer;
  
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'fylgja_channel',
        initialNotificationTitle: 'Fylgja ser etter dekning',
        initialNotificationContent: 'Appen kjører i bakgrunnen og overvåker nettverksdekning',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
  
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }
  
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    service.on('startService').listen((event) {
      _startMonitoring(service);
    });
    
    service.on('stopService').listen((event) {
      _stopMonitoring();
    });
    
  service.on('pauseService').listen((event) {
    final duration = event?['duration'] ?? 5;
    _pauseService(duration, service);
  });
    
  }
  
  static void _startMonitoring(ServiceInstance service) {
    print('Background service: _startMonitoring called - _monitoringTimer active: ${_monitoringTimer?.isActive}');
    
    // Prevent multiple monitoring instances
    if (_monitoringTimer?.isActive == true) {
      print('Background service: Monitoring already active, skipping duplicate start');
      return;
    }
    
    _wasConnected = false;
    _isPaused = false;
    
    // Notify that service started
    service.invoke('serviceStarted');
    print('Background service: serviceStarted event sent');
    
    // Always start with _wasConnected = false to detect new connections
    // This ensures we always trigger coverage when starting the search
    _wasConnected = false;
    _coverageAlreadyFound = false; // Reset coverage found flag for new search
    print('Background service: Starting search - _wasConnected set to false to detect new connections');
    
    // Check connectivity every 3 seconds for more responsive detection
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      print('Background service: Timer tick - checking connectivity...');
      
      if (_isPaused) {
        print('Background service: Monitoring paused');
        return;
      }
      
      await _checkConnectivity(service);
    });
    
    // Wait a bit longer for service to be fully ready before first check
    _initialCheckTimer = Timer(const Duration(milliseconds: 1000), () {
      print('Background service: Initial connectivity check after delay...');
      _checkConnectivity(service);
    });
    
    // Additional check after a longer delay to catch any missed connections
    Timer(const Duration(milliseconds: 2000), () {
      print('Background service: Secondary connectivity check...');
      _checkConnectivity(service);
    });
    
    // Third check after even longer delay
    Timer(const Duration(milliseconds: 3000), () {
      print('Background service: Tertiary connectivity check...');
      _checkConnectivity(service);
    });
    
    print('Background service: Timer created and started - will check connectivity every 3 seconds');
  }
  
  static Future<void> _checkConnectivity(ServiceInstance service) async {
    try {
      print('Background service: ===== CONNECTIVITY CHECK START =====');
      print('Background service: Monitoring timer active: ${_monitoringTimer?.isActive ?? false}');
      print('Background service: Was connected: $_wasConnected, Coverage already found: $_coverageAlreadyFound');
      
      // Check if monitoring is still active before proceeding
      if (_monitoringTimer == null || !_monitoringTimer!.isActive) {
        print('Background service: Monitoring stopped, skipping connectivity check');
        return;
      }
      
      print('Background service: Starting connectivity check...');
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      
      print('Background service: Connectivity check - Connected: $isConnected, WasConnected: $_wasConnected, Result: $connectivityResult');
      print('Background service: Detailed result: ${connectivityResult.toString()}');
      
      // ALWAYS trigger coverage if we're connected, but only once per search session
      if (isConnected && !_coverageAlreadyFound) {
        print('Background service: 🎉 CONNECTED! Triggering coverage...');
        _wasConnected = true;
        _coverageAlreadyFound = true; // Prevent duplicate events
        service.invoke('coverageFound');
        print('Background service: Coverage found event sent to UI');
        return;
      } else if (isConnected && _coverageAlreadyFound) {
        print('Background service: Already connected and coverage already found - no duplicate event');
        return;
      } else {
        print('Background service: Not connected - result: $connectivityResult');
        if (_wasConnected) {
          _wasConnected = false;
          _coverageAlreadyFound = false; // Reset for next search
          service.invoke('coverageLost');
          print('Background service: Coverage lost event sent to UI');
        }
      }
      
      print('Background service: ===== CONNECTIVITY CHECK END =====');
    } catch (e) {
      print('Background service: ERROR in connectivity check: $e');
      print('Background service: Stack trace: ${StackTrace.current}');
      
      // If there's an error, try to reset state and continue
      print('Background service: Attempting to recover from error...');
      _wasConnected = false;
      _coverageAlreadyFound = false;
    }
  }
  
  static void _stopMonitoring() {
    _wasConnected = false;
    _isPaused = false;
    _coverageAlreadyFound = false; // Reset coverage found flag
    _monitoringTimer?.cancel();
    _pauseTimer?.cancel();
    _initialCheckTimer?.cancel();
    print('Background service: Monitoring stopped and timers cancelled');
    // Note: NativeNotificationService can't be called from background isolate
    // The UI will handle the notification when it receives the 'stopService' event
  }
  
  static void _pauseService(int duration, ServiceInstance service) {
    print('Background service: Pausing service for $duration minutes');
    _isPaused = true;
    // Note: NativeNotificationService can't be called from background isolate
    // The UI will handle the notification when it receives the 'pauseService' event
    
    // Cancel the monitoring timer to stop checking connectivity
    _monitoringTimer?.cancel();
    print('Background service: Monitoring timer cancelled');
    
    // Set timer to resume monitoring after pause duration
    _pauseTimer?.cancel();
    _pauseTimer = Timer(Duration(minutes: duration), () {
      _isPaused = false;
      // Reset connection state so we can detect new coverage
      _wasConnected = false;
      print('Background service: Resumed from pause, reset connection state');
      
      // Restart monitoring
      _startMonitoring(service);
    });
  }
  
}
