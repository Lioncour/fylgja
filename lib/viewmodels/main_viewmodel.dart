import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/native_notification_service.dart';
import '../services/native_connectivity_service.dart';
import '../services/background_service.dart';
import '../services/coverage_history_service.dart';
import '../models/search_state.dart';
import '../models/coverage_event.dart';
import '../utils/logger.dart';
import '../utils/haptic_feedback.dart';

class MainViewModel extends ChangeNotifier {
  // State management
  SearchState _state = SearchState.idle;
  int _pauseDuration = 5;
  bool _isProcessing = false;
  DateTime? _searchStartTime;
  DateTime? _pauseStartTime;
  Timer? _pauseTimer;
  Duration? _pauseRemaining;
  
  // Connectivity monitoring
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _connectivityTimer;
  StreamSubscription? _serviceStartedSubscription;
  StreamSubscription? _coverageFoundSubscription;
  StreamSubscription? _coverageLostSubscription;
  StreamSubscription? _serviceStoppedSubscription;
  StreamSubscription? _pauseCompletedSubscription;
  
  // Error handling
  String? _errorMessage;
  
  // Getters
  SearchState get state => _state;
  bool get isSearching => _state == SearchState.searching;
  bool get hasCoverage => _state == SearchState.coverageFound;
  bool get isPaused => _state == SearchState.paused;
  int get pauseDuration => _pauseDuration;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  DateTime? get searchStartTime => _searchStartTime;
  DateTime? get pauseStartTime => _pauseStartTime;
  Duration? get pauseRemaining => _pauseRemaining;
  
  MainViewModel() {
    _loadPauseDuration();
    _setupServiceListener();
    _setupAppLifecycleListener();
    AppLogger.info('MainViewModel initialized');
  }
  
  Future<void> _loadPauseDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pauseDuration = prefs.getInt('pause_duration') ?? 5;
      notifyListeners();
      AppLogger.debug('Pause duration loaded: $_pauseDuration minutes');
    } catch (e) {
      AppLogger.error('Error loading pause duration', e);
      _setError('Kunne ikke laste inn innstillinger');
    }
  }

  void _setupAppLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      AppLogger.debug('App lifecycle state changed: $message');
      
      if (message == AppLifecycleState.resumed.toString()) {
        AppLogger.info('App resumed from background/standby');
        _handleAppResumed();
      }
      
      return null;
    });
  }

  void _handleAppResumed() {
    if (_state == SearchState.searching) {
      AppLogger.info('App resumed while searching - notifying background service');
      try {
        final service = FlutterBackgroundService();
        service.invoke('appResumed');
      } catch (e) {
        AppLogger.error('Error notifying background service', e);
      }
    }
  }

  void _setupServiceListener() {
    try {
      final service = FlutterBackgroundService();
      
      // Listen for service events
      _serviceStartedSubscription = service.on('serviceStarted').listen((event) {
        AppLogger.info('Service started event received');
        _setState(SearchState.searching);
      });
    
      _coverageFoundSubscription = service.on('coverageFound').listen((event) {
        AppLogger.info('Coverage found event received');
        _handleCoverageFound();
      });
    
      _coverageLostSubscription = service.on('coverageLost').listen((event) {
        AppLogger.info('Coverage lost event received');
        if (_state != SearchState.paused) {
          _setState(SearchState.searching);
        }
        NativeNotificationService.cancelNotification();
      });
    
      _serviceStoppedSubscription = service.on('serviceStopped').listen((event) {
        _setState(SearchState.idle);
        _isProcessing = false;
        AppLogger.info('Service stopped');
      });
    
      _pauseCompletedSubscription = service.on('pauseCompleted').listen((event) {
        AppLogger.info('Pause completed event received');
        _resumeFromPause();
      });
    } catch (e) {
      AppLogger.error('Error setting up service listener', e);
      _setError('Kunne ikke koble til bakgrunnstjeneste');
    }
  }
  
  void _setState(SearchState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      
      // Update search start time
      if (newState == SearchState.searching && oldState != SearchState.searching) {
        _searchStartTime = DateTime.now();
      } else if (newState == SearchState.idle) {
        _searchStartTime = null;
      }
      
      notifyListeners();
      AppLogger.debug('State changed: $oldState -> $newState');
    }
  }
  
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
    if (message != null) {
      AppLogger.warning('Error set: $message');
    }
  }
  
  void clearError() {
    _setError(null);
  }
  
  Future<void> startSearch() async {
    AppLogger.info('===== START SEARCH CALLED =====');
    
    // Prevent rapid button presses
    if (_isProcessing) {
      AppLogger.warning('startSearch called but already processing, ignoring');
      return;
    }
    
    if (!_state.canStart) {
      AppLogger.warning('startSearch called but state does not allow starting: $_state');
      return;
    }
    
    _isProcessing = true;
    _setError(null);
    notifyListeners();
    
    try {
      AppLogger.info('Starting search with both background service and direct monitoring');
      
      // Set searching state
      _setState(SearchState.searching);
      _searchStartTime = DateTime.now();
      
      // Start NATIVE Android service for standby mode
      try {
        await NativeConnectivityService.startMonitoring();
        AppLogger.info('Native service started successfully');
      } catch (e) {
        AppLogger.error('Error starting native service', e);
        _setError('Kunne ikke starte overvåking. Sjekk app-tillatelser.');
      }
      
      // Also keep old service for compatibility
      try {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        AppLogger.debug('Flutter background service isRunning: $isRunning');
        
        if (isRunning) {
          service.invoke('startSearch');
          AppLogger.info('Flutter background service invoked');
        }
      } catch (e) {
        AppLogger.error('Error with Flutter background service', e);
      }
      
      // Also start direct connectivity monitoring as fallback
      await _startConnectivityMonitoring();
      AppLogger.info('Search started successfully with both monitoring systems');
      
      // Haptic feedback
      await HapticFeedbackUtil.selectionClick();
      
    } catch (e, stackTrace) {
      AppLogger.error('Error in startSearch', e, stackTrace);
      _setState(SearchState.idle);
      _setError('Kunne ikke starte søk. Prøv igjen.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  Future<void> stopSearch() async {
    AppLogger.info('===== STOP SEARCH CALLED =====');
    AppLogger.info('stopSearch called - state: $_state');
    AppLogger.info('Timestamp: ${DateTime.now().toIso8601String()}');

    if (!_state.canStop) {
      AppLogger.warning('stopSearch called but state does not allow stopping: $_state');
      return;
    }

    AppLogger.info('Setting state to idle immediately to prevent modal reopening');
    _setState(SearchState.idle);
    _isProcessing = true;
    notifyListeners();

    try {
      // Stop background service
      try {
        final service = FlutterBackgroundService();
        service.invoke('stopSearch');
      } catch (e) {
        AppLogger.error('Error stopping background service', e);
      }
      
      // Stop native service
      try {
        await NativeConnectivityService.stopMonitoring();
      } catch (e) {
        AppLogger.error('Error stopping native service', e);
      }
      
      // Stop direct connectivity monitoring
      await _stopConnectivityMonitoring();
      
      // Stop sound and vibration - call multiple times to ensure it stops
      try {
        AppLogger.info('Stopping sound and vibration - calling stopSound multiple times');
        await NativeNotificationService.stopSound();
        await Future.delayed(const Duration(milliseconds: 100));
        await NativeNotificationService.stopSound();
        await NativeNotificationService.cancelNotification();
        await Future.delayed(const Duration(milliseconds: 100));
        await NativeNotificationService.stopSound();
        await Future.delayed(const Duration(milliseconds: 100));
        await NativeNotificationService.cancelNotification(); // Extra cancel to ensure vibration stops
        AppLogger.info('Sound and notification stopped');
      } catch (e) {
        AppLogger.error('Error stopping sound', e);
      }
      
      // Cancel pause timer if active
      _pauseTimer?.cancel();
      _pauseTimer = null;
      _pauseStartTime = null;
      _pauseRemaining = null;
      
      // State already set to idle above, just ensure search time is reset
      _searchStartTime = null;
      AppLogger.info('Search start time reset');
      
      // Haptic feedback
      await HapticFeedbackUtil.lightImpact();
      
    } catch (e) {
      AppLogger.error('Error stopping search', e);
      _setError('Kunne ikke stoppe søk. Prøv igjen.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  Future<void> pauseSearch() async {
    AppLogger.info('pauseSearch called - state: $_state');
    
    if (!_state.canPause) {
      AppLogger.warning('Cannot pause - state does not allow pausing: $_state');
      return;
    }
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Stop connectivity monitoring during pause
      await _stopConnectivityMonitoring();
      
      // Stop sound and vibration
      try {
        await NativeNotificationService.stopSound();
        await NativeNotificationService.cancelNotification();
      } catch (e) {
        AppLogger.error('Error stopping sound', e);
      }
      
      // Set paused state
      AppLogger.info('Setting state to paused');
      _setState(SearchState.paused);
      _pauseStartTime = DateTime.now();
      _pauseRemaining = Duration(minutes: _pauseDuration);
      AppLogger.info('State set to paused, pause duration: $_pauseDuration minutes');
      
      // Set a timer to resume searching after pause duration
      _pauseTimer?.cancel();
      _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pauseStartTime != null && _state == SearchState.paused) {
          final elapsed = DateTime.now().difference(_pauseStartTime!);
          final remaining = Duration(minutes: _pauseDuration) - elapsed;
          
          if (remaining.isNegative || remaining.inSeconds <= 0) {
            timer.cancel();
            _resumeFromPause();
          } else {
            _pauseRemaining = remaining;
            notifyListeners();
          }
        } else {
          timer.cancel();
        }
      });
      
      // Also set a one-time timer as backup
      Timer(Duration(minutes: _pauseDuration), () {
        if (_state == SearchState.paused) {
          _resumeFromPause();
        }
      });
      
      AppLogger.info('Pausing search for $_pauseDuration minutes');
      
      // Haptic feedback
      await HapticFeedbackUtil.mediumImpact();
      
    } catch (e) {
      AppLogger.error('Error pausing search', e);
      _setError('Kunne ikke pause søk. Prøv igjen.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  Future<void> _resumeFromPause() async {
    AppLogger.info('Resuming search after pause');
    
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _pauseStartTime = null;
    _pauseRemaining = null;
    
    _setState(SearchState.searching);
    _searchStartTime = DateTime.now();
    
    // Resume NATIVE service
    try {
      await NativeConnectivityService.startMonitoring();
      AppLogger.info('Native service restarted');
    } catch (e) {
      AppLogger.error('Error restarting native service', e);
      _setError('Kunne ikke gjenoppta overvåking.');
    }
    
    // Resume connectivity monitoring
    await _startConnectivityMonitoring();
    
    // Haptic feedback
    await HapticFeedbackUtil.selectionClick();
  }
  
  void _handleCoverageFound() {
    AppLogger.info('🎉 COVERAGE FOUND! 🎉');
    
    // Calculate search duration
    Duration? searchDuration;
    if (_searchStartTime != null) {
      searchDuration = DateTime.now().difference(_searchStartTime!);
    }
    
    // Determine connection type
    String? connectionType;
    // This would be better determined from the actual connectivity result
    // For now, we'll leave it null
    
    // Save to history
    if (searchDuration != null) {
      final event = CoverageEvent(
        timestamp: DateTime.now(),
        connectionType: connectionType,
        searchDuration: searchDuration,
      );
      CoverageHistoryService.saveEvent(event).catchError((e) {
        AppLogger.error('Error saving coverage event to history', e);
      });
    }
    
    _setState(SearchState.coverageFound);
    _isProcessing = false;
    
    // Check if app is in foreground - only show notification if in background
    final isAppInForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    
    // ALWAYS play sound and vibration when coverage is found, regardless of foreground/background
    if (!isAppInForeground) {
      // Show notification with sound/vibration if app is in background
      NativeNotificationService.showCoverageNotification(showNotification: true);
      AppLogger.info('Coverage found - notification shown with sound/vibration (app in background)');
    } else {
      // App is in foreground - play sound/vibration without showing notification
      // Don't cancel existing notification here - showCoverageNotification will handle it
      AppLogger.info('Coverage found - playing sound/vibration (app in foreground, modal will show)');
      // Play sound/vibration without showing notification
      NativeNotificationService.showCoverageNotification(showNotification: false);
    }
    
    // Haptic feedback
    HapticFeedbackUtil.heavyImpact();
  }
  
  Future<void> _cancelNotificationAsync() async {
    await NativeNotificationService.cancelNotification();
    await Future.delayed(const Duration(milliseconds: 50));
    await NativeNotificationService.cancelNotification(); // Double cancel to be sure
  }
  
  Future<void> setPauseDuration(int duration) async {
    if (duration < 1 || duration > 120) {
      AppLogger.warning('Invalid pause duration: $duration');
      return;
    }
    
    _pauseDuration = duration;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pause_duration', duration);
      AppLogger.info('Pause duration set to $duration minutes');
    } catch (e) {
      AppLogger.error('Error saving pause duration', e);
      _setError('Kunne ikke lagre innstillinger');
    }
  }
  
  // Connectivity monitoring implementation
  Future<void> _startConnectivityMonitoring() async {
    AppLogger.debug('Starting connectivity monitoring');
    
    // Cancel any existing monitoring
    await _stopConnectivityMonitoring();
    
    // Check connectivity immediately
    await _checkConnectivity();
    
    // Set up periodic connectivity checks every 2 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_state == SearchState.searching) {
        await _checkConnectivity();
      } else {
        timer.cancel();
      }
    });
    
    // Also listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (_state == SearchState.searching) {
        _handleConnectivityChange([result]);
      }
    });
  }
  
  Future<void> _stopConnectivityMonitoring() async {
    AppLogger.debug('Stopping connectivity monitoring');
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _handleConnectivityChange([connectivityResult]);
    } catch (e) {
      AppLogger.error('Error checking connectivity', e);
    }
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.any((result) => result != ConnectivityResult.none);
    AppLogger.debug('Connectivity change detected - Connected: $isConnected, Results: $results');
    
    if (isConnected && _state == SearchState.searching) {
      _handleCoverageFound();
    } else if (!isConnected && _state == SearchState.coverageFound) {
      AppLogger.info('Coverage lost - resuming search');
      _setState(SearchState.searching);
      NativeNotificationService.cancelNotification();
    }
  }
  
  @override
  void dispose() {
    AppLogger.info('Disposing MainViewModel');
    
    // Cancel all timers
    _connectivityTimer?.cancel();
    _pauseTimer?.cancel();
    
    // Cancel all subscriptions
    _connectivitySubscription?.cancel();
    _serviceStartedSubscription?.cancel();
    _coverageFoundSubscription?.cancel();
    _coverageLostSubscription?.cancel();
    _serviceStoppedSubscription?.cancel();
    _pauseCompletedSubscription?.cancel();
    
    // Stop monitoring
    _stopConnectivityMonitoring();
    
    super.dispose();
  }
}
