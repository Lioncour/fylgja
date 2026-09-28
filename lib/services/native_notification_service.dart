import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../utils/logger.dart';
import 'coverage_vibration_pattern.dart';

class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel('fylgja/notifications');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // iOS has no native alert code, so the sound is played from Dart. The app only
  // searches in the foreground there, so no notification is needed.
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
    player.onPlayerComplete.listen((_) => Vibration.cancel());
    _iosPlayer = player;
    return player;
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
      // Follows the sound's loudness and plays once, so it ends with the sound.
      // Uses Core Haptics, so it only works while the app is open.
      await Vibration.vibrate(
        pattern: coverageVibrationPattern,
        intensities: coverageVibrationIntensities,
      );
    } catch (e) {
      AppLogger.error('Error starting vibration (iOS)', e);
    }
  }

  static Future<void> _stopIOSAlert() async {
    try {
      await _iosPlayer?.stop();
    } catch (e) {
      AppLogger.error('Error stopping coverage sound (iOS)', e);
    }
    try {
      await Vibration.cancel();
    } catch (e) {
      AppLogger.error('Error stopping vibration (iOS)', e);
    }
  }

  /// Shows the coverage notification using native Android code.
  /// [showNotification] - if false, only plays sound/vibration without showing notification.
  static Future<void> showCoverageNotification({bool showNotification = true}) async {
    if (_isIOS) {
      await _playIOSAlert();
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
      // No notification on iOS; coverage was lost or the alert dismissed, so end it.
      await _stopIOSAlert();
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
