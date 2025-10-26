import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Centralized notification helper for scheduling reminders across platforms.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int dailyAyahNotificationId = 1001;
  static const int fridayReminderNotificationId = 1002;

  /// Ensure the notification plugin and timezone data are ready.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final String timeZoneName =
          await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService timezone fallback: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _initialized = true;
  }

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  NotificationDetails get _defaultDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'quran_hadith_reminders',
          'Reminders',
          channelDescription:
              'Daily ayah reminders and Friday reading notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );

  Future<void> scheduleDailyNotification({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
  }) async {
    // zonedSchedule is not supported on Linux and Web
    if (kIsWeb || Platform.isLinux) {
      debugPrint(
          'NotificationService: Scheduled notifications not supported on ${kIsWeb ? 'Web' : 'Linux'}');
      return;
    }

    await initialize();
    final dateTime = _nextInstanceOfTime(time);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      dateTime,
      _defaultDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required TimeOfDay time,
    required int weekday,
    required String title,
    required String body,
    String? payload,
  }) async {
    // zonedSchedule is not supported on Linux and Web
    if (kIsWeb || Platform.isLinux) {
      debugPrint(
          'NotificationService: Scheduled notifications not supported on ${kIsWeb ? 'Web' : 'Linux'}');
      return;
    }

    await initialize();
    final dateTime = _nextInstanceOfTime(time, weekday: weekday);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      dateTime,
      _defaultDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (weekday != null) {
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
