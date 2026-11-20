import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/timer_phase.dart';

/// Session-end alerts: a notification (with sound) plus a short vibration
/// pulse. Notifications are only shown for a phase the user just finished;
/// nothing is scheduled in advance, so no exact-alarm permission is needed.
class NotificationService {
  NotificationService();

  static const String _channelId = 'focusforge_sessions';
  static const String _channelName = 'Session alerts';
  static const String _channelDescription =
      'Alerts when a focus or break session ends';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Sets up the notification channel. Safe to call more than once.
  /// Never throws: alerts are best-effort and must not break the app.
  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: settings);
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      _initialized = true;
    } catch (_) {
      // Notifications unavailable (e.g. in tests): the timer still works.
      _initialized = true;
    }
  }

  /// Asks for the runtime notification permission (Android 13+).
  /// Returns true when notifications are allowed (or no runtime
  /// permission is needed on older Android versions). Never throws.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Shows the "session finished" alert for [phase]. Never throws.
  Future<void> showPhaseComplete(
    TimerPhase phase, {
    bool sound = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      await init();
      final title = phase == TimerPhase.focus
          ? 'Focus session complete'
          : 'Break over';
      final body = phase == TimerPhase.focus
          ? 'Nice work. Time for a break.'
          : 'Break finished. Ready to focus again?';
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: sound,
          enableVibration: vibrationEnabled,
        ),
      );
      await _plugin.show(
        id: phase.index,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Alerts are best-effort; a failure here must not break the timer.
    }
  }
}
