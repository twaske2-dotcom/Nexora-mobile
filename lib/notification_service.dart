import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'api_service.dart';

/// Local reminders from Nexa. Everything is scheduled on the phone itself,
/// so it works even while the backend is asleep.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _prefKey = 'notifications_enabled';
  static const _tipBase = 100; // ids 100..106: daily Nexa tips
  static const _followBase = 1000; // ids 1000+: follow-up reminders

  static const _tips = [
    'Practice one interview answer out loud today. Five minutes is enough.',
    'Fresh jobs matching your resume are live. Open Nexora and apply early.',
    'Try a mock aptitude round today and see where you stand.',
    'Add one measurable result to a project on your resume, like "reduced load time by 40%".',
    'Ask Nexa which skills your target role asks for, and pick one to learn this week.',
    'Check your application tracker and follow up on anything still pending.',
    'Run a mock video interview with Nexa. Confidence comes from practice.',
  ];

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool value, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
    if (value) {
      await refresh(token);
    } else {
      await init();
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
  }

  /// Call when the app opens: asks for permission once, then (re)schedules.
  static Future<void> refresh(String? token) async {
    await init();
    if (!_ready || !await isEnabled()) return;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) return;
    } catch (_) {
      return;
    }

    await _scheduleDailyTips();

    if (token != null && token.isNotEmpty) {
      try {
        final apps = await ApiService.getApplications(token);
        await syncFollowUps(apps);
      } catch (_) {}
    }
  }

  static NotificationDetails _details(String channel, String name) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          name,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      );

  static tz.TZDateTime _at(DateTime local) =>
      tz.TZDateTime.from(local, tz.UTC);

  /// One tip a day at 7 PM for the next 7 days. Re-created at every app open,
  /// so the schedule never runs dry as long as the user opens the app weekly.
  static Future<void> _scheduleDailyTips() async {
    try {
      for (var i = 0; i < _tips.length; i++) {
        await _plugin.cancel(_tipBase + i);
      }
      final now = DateTime.now();
      var first = DateTime(now.year, now.month, now.day, 19);
      if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

      for (var i = 0; i < _tips.length; i++) {
        final when = first.add(Duration(days: i));
        await _plugin.zonedSchedule(
          _tipBase + i,
          'Nexa · Your career mentor',
          _tips[(when.day + i) % _tips.length],
          _at(when),
          _details('nexa_tips', 'Daily tips from Nexa'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {}
  }

  /// A reminder 7 days after the last status change for every application
  /// that is still in the "Applied" stage. Others are cancelled.
  static Future<void> syncFollowUps(List<dynamic> apps) async {
    await init();
    if (!_ready || !await isEnabled()) return;
    try {
      for (final raw in apps) {
        if (raw is! Map) continue;
        final id = raw['id'];
        if (id is! int) continue;
        final notifId = _followBase + id;
        await _plugin.cancel(notifId);

        final status = (raw['status'] ?? 'APPLIED').toString().toUpperCase();
        if (status != 'APPLIED') continue;

        final since = DateTime.tryParse(
          (raw['statusUpdatedAt'] ?? raw['appliedAt'] ?? '').toString(),
        );
        if (since == null) continue;
        var when = since.add(const Duration(days: 7));
        when = DateTime(when.year, when.month, when.day, 10);
        if (!when.isAfter(DateTime.now())) continue;

        final company = (raw['company'] ?? '').toString();
        final title = (raw['title'] ?? 'your application').toString();
        await _plugin.zonedSchedule(
          notifId,
          'Time to follow up',
          company.isEmpty
              ? 'It has been a week since you applied for $title. Send a short follow-up email.'
              : 'It has been a week since you applied to $company. Send a short follow-up email.',
          _at(when),
          _details('nexa_followups', 'Application follow-ups'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {}
  }
}
