import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/spendwise_features.dart';

/// Schedules local, inexact reminders without Internet or a backend.
/// User permission and OS battery policy determine whether notifications fire.
class ExpenseNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _details = NotificationDetails(
      android: AndroidNotificationDetails(
          'spendwise_expenses', 'Expense reminders',
          channelDescription: 'Personal spending reminders',
          importance: Importance.defaultImportance,
          visibility: NotificationVisibility.private));

  static Future<void> initialize() async {
    if (_ready || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    tzdata.initializeTimeZones();
    final current = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(current.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await initialize();
    if (!_ready) return false;
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  static int _stableId(String value) {
    var h = 2166136261;
    for (final ch in value.codeUnits) {
      h = ((h ^ ch) * 16777619) & 0x7fffffff;
    }
    return h;
  }

  static Future<void> sync(List<ExpenseReminder> reminders) async {
    await initialize();
    if (!_ready) return;
    // Other app notifications use separate IDs/channels; only these are
    // scheduled by this feature. IDs are stable after app restarts.
    for (final r in reminders) {
      final id = _stableId('reminder-${r.id}');
      await _plugin.cancel(id: id);
      if (!r.enabled || !r.when.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: id,
        title: 'SpendWise reminder',
        body: r.title,
        scheduledDate: tz.TZDateTime.from(r.when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelAll(List<ExpenseReminder> reminders) async {
    await initialize();
    if (!_ready) return;
    for (final r in reminders) {
      await _plugin.cancel(id: _stableId('reminder-${r.id}'));
    }
  }
}
