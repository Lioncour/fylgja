import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coverage_event.dart';
import '../utils/logger.dart';

/// Service for managing coverage event history
class CoverageHistoryService {
  static const String _key = 'coverage_history';
  static const int _maxEvents = 100; // Keep last 100 events

  /// Save a coverage event to history
  static Future<void> saveEvent(CoverageEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      history.insert(0, event); // Add to beginning
      
      // Keep only the most recent events
      if (history.length > _maxEvents) {
        history.removeRange(_maxEvents, history.length);
      }
      
      final jsonList = history.map((e) => e.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
      
      AppLogger.info('Coverage event saved to history');
    } catch (e) {
      AppLogger.error('Error saving coverage event', e);
    }
  }

  /// Get all coverage events from history
  static Future<List<CoverageEvent>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => CoverageEvent.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error loading coverage history', e);
      return [];
    }
  }

  /// Clear all coverage history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      AppLogger.info('Coverage history cleared');
    } catch (e) {
      AppLogger.error('Error clearing coverage history', e);
    }
  }

  /// Get statistics from history
  static Future<Map<String, dynamic>> getStatistics() async {
    final history = await getHistory();
    
    if (history.isEmpty) {
      return {
        'totalEvents': 0,
        'averageSearchDuration': Duration.zero,
        'totalSearchTime': Duration.zero,
      };
    }
    
    final totalSearchTime = history.fold<Duration>(
      Duration.zero,
      (sum, event) => sum + event.searchDuration,
    );
    
    final averageSearchDuration = Duration(
      milliseconds: (totalSearchTime.inMilliseconds / history.length).round(),
    );
    
    return {
      'totalEvents': history.length,
      'averageSearchDuration': averageSearchDuration,
      'totalSearchTime': totalSearchTime,
      'lastEvent': history.first.timestamp,
    };
  }
}
