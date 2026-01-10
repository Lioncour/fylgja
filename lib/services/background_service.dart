import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static bool _wasConnected = false;
  static bool _isPaused = false;
  static bool _coverageAlreadyFound = false;
  static bool _isFirstSearch = true;
  static Timer? _pauseTimer;
  static Timer? _monitoringTimer;
  static Timer? _initialCheckTimer;
  static DateTime? _pauseStartTime;
  static int _pauseDurationMinutes = 0;
  
  static FlutterBackgroundService? _serviceInstance;
  
  static Future<void> initializeService() async {
    _serviceInstance = FlutterBackgroundService();
    
    await _serviceInstance!.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
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
    
    AppLogger.info('Background service configuration complete');
    AppLogger.info('Background service will start when invoked');
  }
  
  static Future<void> startBackgroundService() async {
    if (_serviceInstance != null) {
      AppLogger.info('Attempting to start background service...');
      try {
        // Try to start the service by sending an event
        // The service will auto-start if not already running
        _serviceInstance!.invoke('startService');
        AppLogger.info('startService event sent');
      } catch (e) {
        AppLogger.error('Error starting background service', e);
      }
    } else {
      AppLogger.error('Background service not initialized');
    }
  }
  
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }
  
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Reset coverage flag when service starts/restarts
    _coverageAlreadyFound = false;
    _wasConnected = false;
    _isPaused = false;
    AppLogger.info('Background service started - reset coverage flags');
    
    service.on('startService').listen((event) {
      _startMonitoring(service);
    });
    
    service.on('startSearch').listen((event) {
      print('Background service: startSearch event received');
      _startMonitoring(service);
    });
    
    service.on('stopService').listen((event) {
      print('Background service: stopService event received');
      _stopMonitoring();
      // Force stop any ongoing sound and vibration
      print('Background service: Requesting immediate sound stop');
    });
    
    service.on('stopSearch').listen((event) {
      print('Background service: stopSearch event received');
      _stopMonitoring();
      // Force stop any ongoing sound and vibration
      print('Background service: Requesting immediate sound stop');
    });
    
    service.on('pauseService').listen((event) {
      final duration = event?['duration'] ?? 5;
      _pauseService(duration, service);
    });
    
    // Handle app resume from standby - restart monitoring if it was active
    service.on('appResumed').listen((event) {
      print('Background service: App resumed from standby');
      if (_monitoringTimer?.isActive == true) {
        print('Background service: Monitoring was active, ensuring it continues');
        // Force a connectivity check immediately when app resumes
        _checkConnectivity(service);
      } else if (_isPaused) {
        print('Background service: App resumed while paused - checking if pause should be complete');
        // Check if pause should be complete (fallback mechanism)
        _checkPauseStatus(service);
      }
    });
    
    // Start monitoring timer immediately for background operation
    print('Background service: onStart complete - starting background monitoring');
    _startBackgroundMonitoring(service);
    
    print('Background service: ===== SERVICE FULLY INITIALIZED =====');
    print('Background service: Will now monitor for connectivity every 3 seconds');
    print('Background service: This works even in standby/folded/doze mode');
  }
  
  static void _startBackgroundMonitoring(ServiceInstance service) {
    print('Background service: ===== STARTING BACKGROUND MONITORING =====');
    print('Background service: This timer runs independently of UI lifecycle');
    print('Background service: Checking connectivity every 3 seconds...');
    
    // Check connectivity every 3 seconds in background for better standby mode detection
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      print('Background service: ⏰ Timer tick - checking connectivity...');
      
      if (_isPaused) {
        print('Background service: ⏸️ Monitoring paused, skipping check');
        return;
      }
      
      await _checkConnectivity(service);
    });
    
    // Initial check after a short delay
    print('Background service: Scheduling initial check in 1 second...');
    Timer(const Duration(milliseconds: 1000), () {
      print('Background service: 🔍 Initial background connectivity check...');
      _checkConnectivity(service);
    });
    
    print('Background service: ✅ Background monitoring started');
  }
  
  static void _startMonitoring(ServiceInstance service) {
    print('Background service: _startMonitoring called - _monitoringTimer active: ${_monitoringTimer?.isActive}');
    
    // Cancel any existing background monitoring
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    
    _wasConnected = false;
    _isPaused = false;
    _coverageAlreadyFound = false; // Reset coverage found flag for new search
    
    // Notify that service started
    service.invoke('serviceStarted');
    print('Background service: serviceStarted event sent');
    
    print('Background service: Starting search - _wasConnected set to false to detect new connections');
    print('Background service: Is first search: $_isFirstSearch');
    
    // Check connectivity every 2 seconds for more responsive detection
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      print('Background service: Timer tick - checking connectivity...');
      
      if (_isPaused) {
        print('Background service: Monitoring paused');
        return;
      }
      
      await _checkConnectivity(service);
    });
    
    // IMMEDIATE connectivity check for first search
    print('Background service: Immediate connectivity check for first search...');
    _checkConnectivity(service);
    
    // Force trigger for first search after a short delay
    if (_isFirstSearch) {
      Timer(const Duration(milliseconds: 2000), () {
        print('Background service: Force trigger for first search...');
        if (!_coverageAlreadyFound) {
          print('Background service: First search force trigger - checking connectivity again');
          _checkConnectivity(service);
        }
      });
      _isFirstSearch = false;
    }
    
    // More aggressive initial checks for first search
    _initialCheckTimer = Timer(const Duration(milliseconds: 500), () {
      print('Background service: Initial connectivity check after delay...');
      _checkConnectivity(service);
    });
    
    // Additional checks to catch any missed connections
    Timer(const Duration(milliseconds: 1000), () {
      print('Background service: Secondary connectivity check...');
      _checkConnectivity(service);
    });
    
    Timer(const Duration(milliseconds: 1500), () {
      print('Background service: Third connectivity check...');
      _checkConnectivity(service);
    });
    
    Timer(const Duration(milliseconds: 2000), () {
      print('Background service: Fourth connectivity check...');
      _checkConnectivity(service);
    });
    
    Timer(const Duration(milliseconds: 2500), () {
      print('Background service: Fifth connectivity check...');
      _checkConnectivity(service);
    });
    
    print('Background service: Timer created and started - will check connectivity every 2 seconds');
  }
  
  static Future<void> _checkConnectivity(ServiceInstance service) async {
    try {
      print('Background service: ===== CONNECTIVITY CHECK START =====');
      print('Background service: Timestamp: ${DateTime.now().toIso8601String()}');
      print('Background service: Monitoring timer active: ${_monitoringTimer?.isActive ?? false}');
      print('Background service: Was connected: $_wasConnected, Coverage already found: $_coverageAlreadyFound');
      print('Background service: Is paused: $_isPaused');
      
      // Check if monitoring is still active before proceeding
      if (_monitoringTimer == null || !_monitoringTimer!.isActive) {
        print('Background service: Monitoring stopped, skipping connectivity check');
        return;
      }
      
      if (_isPaused) {
        print('Background service: Service is paused, skipping connectivity check');
        return;
      }
      
      print('Background service: Starting connectivity check...');
      print('Background service: This check runs every 2-3 seconds in background');
      print('Background service: This is critical for Doze Mode and App Standby bypass');
      
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      
      print('Background service: Connectivity check completed');
      print('Background service: Connected: $isConnected');
      print('Background service: WasConnected: $_wasConnected');
      print('Background service: Result: $connectivityResult');
      print('Background service: Coverage already found: $_coverageAlreadyFound');
      
      // ALWAYS trigger coverage if we're connected, but only once per search session
      if (isConnected && !_coverageAlreadyFound) {
        print('Background service: 🎉🎉🎉 CONNECTED! Triggering coverage...');
        print('Background service: This means WiFi or mobile data is available');
        print('Background service: Updating foreground notification with ALERT...');
        
        _wasConnected = true;
        _coverageAlreadyFound = true; // Prevent duplicate events
        
        // CRITICAL: Trigger notification via platform channel
        // This should work even in standby because the service sends the broadcast
        print('Background service: ===== COVERAGE DETECTED - ATTEMPTING TO ALERT =====');
        print('Background service: Timestamp: ${DateTime.now().toIso8601String()}');
        print('Background service: Status - wasConnected: $_wasConnected, coverageAlreadyFound: $_coverageAlreadyFound');
        
        // METHOD 1: Try platform channel (won't work in deep sleep)
        print('Background service: METHOD 1 - Trying MethodChannel...');
        try {
          const platform = MethodChannel('fylgja/notifications');
          await platform.invokeMethod('sendCoverageAlert');
          print('Background service: ✅ SUCCESS: MethodChannel worked');
        } catch (e) {
          print('Background service: ❌ FAILED: MethodChannel error: $e');
          print('Background service: This is expected in deep sleep mode');
        }
        
        // METHOD 2: Always send to UI (will trigger when UI wakes up)
        print('Background service: METHOD 2 - Sending event to UI...');
        try {
          service.invoke('coverageFound');
          print('Background service: ✅ coverageFound event sent to UI');
        } catch (e) {
          print('Background service: ❌ Error sending event to UI: $e');
        }
        
        print('Background service: ===== ALERT ATTEMPT COMPLETE =====');
        return;
        
      } else if (isConnected && _coverageAlreadyFound) {
        print('Background service: Already connected and coverage already found - no duplicate event');
        print('Background service: This prevents multiple notifications for the same coverage');
        return;
        
      } else {
        print('Background service: Not connected - result: $connectivityResult');
        print('Background service: Continuing to monitor for connectivity...');
        
        if (_wasConnected) {
          print('Background service: Was connected but now disconnected - sending coverage lost event');
          _wasConnected = false;
          _coverageAlreadyFound = false; // Reset for next search
          service.invoke('coverageLost');
          print('Background service: Coverage lost event sent to UI');
        }
      }
      
      print('Background service: ===== CONNECTIVITY CHECK END =====');
      
    } catch (e) {
      print('Background service: ❌ ERROR in connectivity check: $e');
      print('Background service: Stack trace: ${StackTrace.current}');
      print('Background service: This error might indicate Doze Mode interference');
      
      // If there's an error, try to reset state and continue
      print('Background service: Attempting to recover from error...');
      _wasConnected = false;
      _coverageAlreadyFound = false;
      print('Background service: State reset - will continue monitoring');
    }
  }
  
  static void _stopMonitoring() {
    _wasConnected = false;
    _isPaused = false;
    _coverageAlreadyFound = false; // Reset coverage found flag
    _isFirstSearch = true; // Reset first search flag
    _pauseStartTime = null;
    _pauseDurationMinutes = 0;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    print('Background service: Monitoring stopped and timers cancelled');
    // Note: NativeNotificationService can't be called from background isolate
    // The UI will handle the notification when it receives the 'stopService' event
  }
  
  
  static void _pauseService(int duration, ServiceInstance service) {
    print('Background service: Pausing service for $duration minutes');
    _isPaused = true;
    _pauseStartTime = DateTime.now();
    _pauseDurationMinutes = duration;
    
    // Cancel the monitoring timer to stop checking connectivity
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    print('Background service: Monitoring timer cancelled');
    
    // Stop any ongoing sound and vibration when pausing
    print('Background service: Stopping sound and vibration for pause');
    // Note: We can't call native methods directly from background service
    // The UI will handle stopping sound when it receives the pause event
    
    // Set timer to resume monitoring after pause duration
    _pauseTimer?.cancel();
    _pauseTimer = Timer(Duration(minutes: duration), () {
      print('Background service: Pause timer completed - resuming monitoring');
      _isPaused = false;
      _pauseStartTime = null;
      _pauseDurationMinutes = 0;
      // Reset connection state so we can detect new coverage
      _wasConnected = false;
      _coverageAlreadyFound = false;
      print('Background service: Resumed from pause, reset connection state');
      
      // Restart monitoring with background monitoring
      _startBackgroundMonitoring(service);
      
      // Notify UI that pause is complete
      service.invoke('pauseCompleted');
    });
    
    print('Background service: Pause timer set for $duration minutes');
  }
  
  static void _checkPauseStatus(ServiceInstance service) {
    if (!_isPaused || _pauseStartTime == null) {
      print('Background service: Not paused or no pause start time');
      return;
    }
    
    final now = DateTime.now();
    final pauseElapsed = now.difference(_pauseStartTime!);
    final pauseElapsedMinutes = pauseElapsed.inMinutes;
    
    print('Background service: Pause elapsed: $pauseElapsedMinutes minutes, Duration: $_pauseDurationMinutes minutes');
    
    if (pauseElapsedMinutes >= _pauseDurationMinutes) {
      print('Background service: Pause should be complete - resuming monitoring');
      _isPaused = false;
      _pauseStartTime = null;
      _pauseDurationMinutes = 0;
      
      // Cancel any existing pause timer
      _pauseTimer?.cancel();
      _pauseTimer = null;
      
      // Reset connection state
      _wasConnected = false;
      _coverageAlreadyFound = false;
      
      // Restart monitoring
      _startBackgroundMonitoring(service);
      
      // Notify UI that pause is complete
      service.invoke('pauseCompleted');
    } else {
      print('Background service: Pause still active - ${_pauseDurationMinutes - pauseElapsedMinutes} minutes remaining');
    }
  }
  
}

