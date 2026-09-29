import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';
import '../utils/logger.dart';
import 'coverage_vibration_pattern.dart';
import 'notification_service.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('fylgja/notifications');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // iOS has no native alert code, so the sound is played from Dart. The app is
  // kept running by BackgroundKeepAlive (or the screen is kept on), so the
  // sound can play directly; in the background a notification says why and
  // opens the app to pause or stop.
  static AudioPlayer? _iosPlayer;

  static Future<AudioPlayer> _getIOSPlayer() async {
    final existing = _iosPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer();
    // Play on top of other apps' audio instead of pausing it.
    await player.setAudioContext(AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build());
    // Keep the sound loaded after it finishes, so it can be replayed.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource('audio/notification_sound.mp3'));
    // The vibration is timed to the sound; end it with the sound in case they drift.
    player.onPlayerComplete.listen((_) => _cancelIOSVibration());
    _iosPlayer = player;
    return player;
  }

  /// Loads the iOS alert sound ahead of time. Setting up the audio session is
  /// safest in the foreground; the alert may later start with the screen locked.
  static Future<void> prepare() async {
    if (!_isIOS) return;
    try {
      await _getIOSPlayer();
    } catch (e) {
      AppLogger.error('Error preparing coverage sound (iOS)', e);
    }
  }

  static Future<void> _playIOSAlert() async {
    try {
      final player = await _getIOSPlayer();
      await player.seek(Duration.zero);
      await player.resume();
      AppLogger.info('Coverage sound played (iOS)');
    } catch (e) {
      AppLogger.error('Error playing coverage sound (iOS)', e);
    }
    try {
      final inForeground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (inForeground) {
        // Follows the sound's loudness and plays once, so it ends with the sound.
        // Uses Core Haptics, so it only works while the app is open.
        await Vibration.vibrate(
          pattern: coverageVibrationPattern,
          intensities: coverageVibrationIntensities,
        );
      } else {
        // AlertVibration pulses the system vibration, which works in the background.
        await _channel.invokeMethod('startVibration', {
          'durationMs': coverageVibrationPattern.fold<int>(0, (sum, ms) => sum + ms),
        });
      }
    } catch (e) {
      AppLogger.error('Error starting vibration (iOS)', e);
    }
  }

  static Future<void> _cancelIOSVibration() async {
    try {
      await Vibration.cancel();
      await _channel.invokeMethod('stopVibration');
    } catch (e) {
      AppLogger.error('Error stopping vibration (iOS)', e);
    }
  }

  static Future<void> _stopIOSAlert() async {
    try {
      await _iosPlayer?.stop();
    } catch (e) {
      AppLogger.error('Error stopping coverage sound (iOS)', e);
    }
    await _cancelIOSVibration();
  }

  /// Shows the coverage notification using native Android code.
  /// [showNotification] - if false, only plays sound/vibration without showing notification.
  static Future<void> showCoverageNotification({bool showNotification = true}) async {
    if (_isIOS) {
      await _playIOSAlert();
      if (showNotification) {
        try {
          await NotificationService.showCoverageNotification();
        } catch (e) {
          AppLogger.error('Error showing coverage notification (iOS)', e);
        }
      }
      return;
    }
    if (!isSupported) {
      AppLogger.info('Native coverage notification is Android-only; skipping');
      return;
    }
    try {
      await _channel.invokeMethod('showCoverageNotification', {
        'showNotification': showNotification,
      });
      AppLogger.info('Coverage notification sent');
    } catch (e) {
      AppLogger.error('Error showing coverage notification', e);
    }
  }

  static Future<void> cancelNotification() async {
    if (_isIOS) {
      // Coverage was lost or the alert dismissed, so end it.
      await _stopIOSAlert();
      try {
        await NotificationService.cancelNotification();
      } catch (e) {
        AppLogger.error('Error cancelling coverage notification (iOS)', e);
      }
      return;
    }
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod('cancelNotification');
      AppLogger.info('Coverage notification cancelled');
    } catch (e) {
      AppLogger.error('Error cancelling notification', e);
    }
  }

  static Future<void> stopSound() async {
    if (_isIOS) {
      await _stopIOSAlert();
      return;
    }
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod('stopSound');
      AppLogger.info('Coverage sound stopped');
    } catch (e) {
      AppLogger.error('Error stopping sound', e);
    }
  }
}
