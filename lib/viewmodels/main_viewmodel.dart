import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/native_notification_service.dart';

class MainViewModel extends ChangeNotifier {
  bool _isSearching = false;
  bool _hasCoverage = false;
  bool _isPaused = false;
  int _pauseDuration = 5; // Default pause duration in minutes
  
  bool get isSearching => _isSearching;
  bool get hasCoverage => _hasCoverage;
  bool get isPaused => _isPaused;
  int get pauseDuration => _pauseDuration;
  
  MainViewModel() {
    _loadPauseDuration();
    _setupServiceListener();
  }
  
  Future<void> _loadPauseDuration() async {
    final prefs = await SharedPreferences.getInstance();
    _pauseDuration = prefs.getInt('pause_duration') ?? 5;
    notifyListeners();
  }
  
  void _setupServiceListener() {
    final service = FlutterBackgroundService();
    
    // Listen for service events
    service.on('serviceStarted').listen((event) {
      print('UI: Service started event received');
      _isSearching = true;
      _hasCoverage = false;
      notifyListeners();
      print('UI: Service started - isSearching: $_isSearching, hasCoverage: $_hasCoverage');
    });
    
    service.on('coverageFound').listen((event) {
      print('UI: Coverage found event received');
      _hasCoverage = true;
      _isSearching = false;
      notifyListeners();
      print('UI: Coverage found - isSearching: $_isSearching, hasCoverage: $_hasCoverage');
      
      // Trigger the EXTREME notification (sound + vibration)
      NativeNotificationService.showCoverageNotification();
    });
    
    service.on('coverageLost').listen((event) {
      print('UI: Coverage lost event received');
      _hasCoverage = false;
      _isSearching = true;
      notifyListeners();
      print('UI: Coverage lost - isSearching: $_isSearching, hasCoverage: $_hasCoverage');
      
      // Cancel any ongoing notifications
      NativeNotificationService.cancelNotification();
    });
    
    service.on('serviceStopped').listen((event) {
      _isSearching = false;
      _hasCoverage = false;
      notifyListeners();
      print('Service stopped');
    });
  }
  
  Future<void> startSearch() async {
    print('UI: ===== START SEARCH CALLED =====');
    print('UI: Current state - isSearching: $_isSearching, hasCoverage: $_hasCoverage');
    
    if (_isSearching) {
      print('UI: startSearch called but already searching, ignoring');
      return;
    }
    
    print('UI: startSearch called - checking background service');
    
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    print('UI: Background service isRunning: $isRunning');
    
    if (isRunning) {
      print('UI: Service already running, invoking startService');
      service.invoke('startService');
    } else {
      print('UI: Service not running, starting service');
      await service.startService();
    }
    
    // Set searching state immediately to prevent double starts
    _isSearching = true;
    _hasCoverage = false; // Reset coverage state for new search
    notifyListeners();
    print('UI: Starting search - state set to searching - isSearching: $_isSearching, hasCoverage: $_hasCoverage');
    print('UI: ===== START SEARCH COMPLETE =====');
  }
  
  Future<void> stopSearch() async {
    print('stopSearch called - isSearching: $_isSearching, hasCoverage: $_hasCoverage, isPaused: $_isPaused');

    if (!_isSearching && !_hasCoverage && !_isPaused) {
      print('stopSearch called but nothing to stop, ignoring');
      return;
    }

    final service = FlutterBackgroundService();
    service.invoke('stopService');

    // Stop notifications immediately
    await NativeNotificationService.cancelNotification();

    // Reset UI state immediately
    _isSearching = false;
    _hasCoverage = false;
    _isPaused = false;
    notifyListeners();

    print('Stopping search - state reset');
  }
  
  Future<void> pauseSearch() async {
    print('pauseSearch called - hasCoverage: $_hasCoverage, isSearching: $_isSearching, isPaused: $_isPaused');
    
    // Allow pausing if we have coverage OR if we're currently searching
    if (!_hasCoverage && !_isSearching) {
      print('Cannot pause - no coverage and not searching');
      return;
    }
    
    // Cancel any ongoing notifications and vibration immediately
    NativeNotificationService.cancelNotification();
    
    final service = FlutterBackgroundService();
    service.invoke('pauseService', {'duration': _pauseDuration});
    
    // Set paused state
    _hasCoverage = false;
    _isSearching = false;
    _isPaused = true;
    print('Setting paused state - hasCoverage: $_hasCoverage, isSearching: $_isSearching, isPaused: $_isPaused');
    notifyListeners();
    print('Paused state set - isPaused: $_isPaused');
    
    // Set a timer to resume searching after pause duration
    Timer(Duration(minutes: _pauseDuration), () {
      if (_isPaused) {
        _isPaused = false;
        _isSearching = true;
        notifyListeners();
        
        // Actually restart the background service
        final service = FlutterBackgroundService();
        service.invoke('startService');
        
        print('Resuming search after pause');
      }
    });
    
    print('Pausing search for $_pauseDuration minutes');
  }
  
  Future<void> setPauseDuration(int duration) async {
    _pauseDuration = duration;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pause_duration', duration);
    
    print('Pause duration set to $duration minutes');
  }
  
}
