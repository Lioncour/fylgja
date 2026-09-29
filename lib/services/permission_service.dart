import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// Asks for the permissions a search needs. Called when the user leaves the
/// onboarding page that explains them, rather than at launch, so the questions
/// come after the explanation.
class PermissionService {
  static Future<void> requestSearchPermissions() async {
    await requestLocationPermission();
    await requestNotificationPermission();
  }

  /// Location keeps the search running with the screen locked on iOS, and
  /// gives the coordinates stored when coverage is found.
  static Future<void> requestLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        AppLogger.info('Location services are disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      AppLogger.info('Location permission: $permission');
    } catch (e) {
      AppLogger.error('Error requesting location permission', e);
    }
  }

  /// iOS shows a notification when coverage is found in the background.
  /// Android's alerts are native and not covered here. Asking again once the
  /// user has answered does nothing, so this is safe to call before every search.
  static Future<void> requestNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await NotificationService.requestPermission();
    } catch (e) {
      AppLogger.error('Error requesting notification permission', e);
    }
  }
}
