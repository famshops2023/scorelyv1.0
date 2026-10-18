import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize local notifications
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
      debugPrint('NotificationService: Initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  /// Request permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return granted ?? iosGranted ?? true;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions error: $e');
      return false;
    }
  }

  /// Send test notification when enabled in Settings
  Future<void> showTestNotification() async {
    await _show(
      id: 100,
      title: 'Scorely Notifications Enabled 🏏',
      body: 'You will receive live match milestones, innings breaks, and results.',
      ignorePreference: true,
    );
  }

  /// Innings complete notification
  Future<void> showInningsBreakNotification({
    required String battingTeam,
    required int runs,
    required int wickets,
    required String overs,
    required String chasingTeam,
    required int target,
  }) async {
    await _show(
      id: 201,
      title: 'Innings Break: $battingTeam finished! 🏏',
      body: 'Score: $runs/$wickets in $overs ov. Target for $chasingTeam: $target runs.',
    );
  }

  /// Match complete notification
  Future<void> showMatchCompleteNotification({
    required String matchTitle,
    required String resultSummary,
  }) async {
    await _show(
      id: 202,
      title: '🏆 Match Finished: $matchTitle',
      body: resultSummary,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    bool ignorePreference = false,
  }) async {
    try {
      if (!ignorePreference) {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('settings_notifications') ?? true;
        if (!enabled) return;
      }

      if (!_isInitialized) {
        await init();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'scorely_match_alerts',
        'Match Alerts',
        channelDescription:
            'Notifications for cricket matches, innings breaks, and results',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint('NotificationService._show error: $e');
    }
  }
}
