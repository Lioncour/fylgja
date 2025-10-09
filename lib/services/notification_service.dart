import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Initializes the flutter_local_notifications plugin
  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Create notification channel for coverage alerts with sound
    final androidChannel = AndroidNotificationChannel(
      'fylgja_coverage_channel',
      'Coverage Alerts',
      description: 'Notifications for when Fylgja finds network coverage.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 2000]),
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      print('NotificationService: Channel created successfully');
      print('NotificationService: Channel ID: fylgja_coverage_channel');
      print('NotificationService: Channel importance: max');
      print('NotificationService: Channel playSound: true');
      print('NotificationService: Channel enableVibration: true');
    } else {
      print('NotificationService: ERROR - Android plugin not available');
    }

    _isInitialized = true;
    print('NotificationService: Initialized with sound and vibration');
    print('NotificationService: Channel created with playSound: true, enableVibration: true');
  }

  /// Shows the persistent notification when coverage is found
  static Future<void> showCoverageNotification() async {
    print('NotificationService: showCoverageNotification called');
    await init();

    final androidDetails = AndroidNotificationDetails(
      'fylgja_coverage_channel',
      'Coverage Alerts',
      channelDescription: 'Notifications for when Fylgja finds network coverage.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 2000]),
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    print('NotificationService: Sending notification with sound and vibration');
    print('NotificationService: Sound file: notification_sound');
    print('NotificationService: Importance: max, Priority: high, playSound: true');
    print('NotificationService: Channel ID: fylgja_channel');
    print('NotificationService: Notification ID: 999');

    await _notifications.show(
      999, // Use a consistent ID for coverage notifications
      'Du har jammen meg dekning!',
      'Trykk her for å pause søkingen',
      notificationDetails,
    );

    print('NotificationService: ✅ Notification sent successfully!');
  }

  /// Dismisses the notification by its ID
  static Future<void> cancelNotification() async {
    print('NotificationService: Cancelling notification');
    await _notifications.cancel(999);
    print('NotificationService: ✅ Notification cancelled');
  }

  /// Test notification to verify the system works
  static Future<void> testNotification() async {
    print('NotificationService: Testing notification system');
    await init();

    final androidDetails = AndroidNotificationDetails(
      'fylgja_coverage_channel',
      'Test Notification',
      channelDescription: 'Test notification to verify sound works',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      998, // Use a different ID for test
      'Test Notification',
      'This is a test to verify sound works',
      notificationDetails,
    );

    print('NotificationService: ✅ Test notification sent');
  }
}
