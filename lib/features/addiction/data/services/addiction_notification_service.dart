import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/addiction_milestones.dart';

/// Schedules celebratory local notifications for addiction milestones.
///
/// Notification IDs live in the 4000-4999 range so they never collide with
/// prayer reminders (100-509) or other features. Each addiction type gets
/// its own 100-id slot starting at:
///   addiction_porn      → 4000
///   addiction_smoking   → 4100
///   addiction_alcohol   → 4200
///   addiction_gambling  → 4300
class AddictionNotificationService {
  AddictionNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'addiction_milestones';
  static const String _channelName = 'Recovery Milestones';
  static const String _channelDescription =
      'Celebrates milestones in your sobriety journey.';

  static const Map<String, int> _typeBaseIds = {
    'addiction_porn': 4000,
    'addiction_smoking': 4100,
    'addiction_alcohol': 4200,
    'addiction_gambling': 4300,
  };

  int? _baseId(String typeKey) => _typeBaseIds[typeKey];

  /// Schedule a notification at 9 AM local time on each milestone day, so
  /// the user wakes up to a celebration. Caller is responsible for cancelling
  /// first when the streak resets.
  ///
  /// Defensive: this method swallows ALL exceptions internally so a misconfigured
  /// device (no exact-alarm permission, missing channel, etc.) never crashes
  /// the calling cubit / UI.
  Future<void> scheduleAllForStreak({
    required String typeKey,
    required DateTime startDate,
  }) async {
    try {
      final base = _baseId(typeKey);
      if (base == null) {
        debugPrint('⚠️ [AddictionNotif] unknown typeKey=$typeKey, skipping');
        return;
      }
      await cancelAllForStreak(typeKey: typeKey);

      // Choose alarm mode based on Android exact-alarm permission. On a
      // device that hasn't granted SCHEDULE_EXACT_ALARM, calling
      // exactAllowWhileIdle throws a PlatformException and Android logs
      // SecurityException natively — both are slow when repeated 9 times.
      final scheduleMode = await _resolveAndroidScheduleMode();

      final location = _safeLocation();
      final now = tz.TZDateTime.now(location);

      for (var i = 0; i < kAddictionMilestones.length; i++) {
        final m = kAddictionMilestones[i];
        final fireDay = startDate.add(Duration(days: m.days));
        final fireAt = tz.TZDateTime(
          location,
          fireDay.year,
          fireDay.month,
          fireDay.day,
          9,
        );
        if (!fireAt.isAfter(now)) continue; // milestone already past

        final humanType = _humanType(typeKey);
        try {
          await _plugin.zonedSchedule(
            base + i,
            '🎉 ${m.title} — ${m.points} Neki points',
            'You\'ve been clean of $humanType for ${m.days} day${m.days == 1 ? '' : 's'}. Keep going.',
            fireAt,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDescription,
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBanner: true,
                presentSound: true,
              ),
            ),
            payload: 'milestone_${typeKey}_${m.days}',
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('🔔 [AddictionNotif] scheduled $typeKey ${m.days}d at $fireAt');
        } catch (e) {
          debugPrint('⚠️ [AddictionNotif] schedule failed for ${m.days}d: $e');
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ [AddictionNotif] scheduleAllForStreak failed: $e\n$st');
    }
  }

  /// Falls back to inexact alarms when SCHEDULE_EXACT_ALARM isn't granted
  /// (Android 12+). Inexact still fires within ~15 min of the intended time,
  /// which is fine for milestone celebrations. Always exact on iOS / pre-12.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;
      final canExact = await android.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Returns `tz.local` if it's been initialized, else falls back to UTC.
  /// Constructing a TZDateTime against an uninitialized timezone DB throws,
  /// so we never pass a bad location into the plugin.
  tz.Location _safeLocation() {
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }

  /// Cancel all scheduled milestone notifications for a given addiction.
  /// Safe to call repeatedly — no-op if nothing is scheduled.
  Future<void> cancelAllForStreak({required String typeKey}) async {
    final base = _baseId(typeKey);
    if (base == null) return;
    for (var i = 0; i < kAddictionMilestones.length; i++) {
      try {
        await _plugin.cancel(base + i);
      } catch (_) {
        // Ignore — cancelling a non-existent id is fine on both platforms.
      }
    }
  }

  String _humanType(String typeKey) {
    switch (typeKey) {
      case 'addiction_porn':
        return 'pornography';
      case 'addiction_smoking':
        return 'smoking';
      case 'addiction_alcohol':
        return 'alcohol';
      case 'addiction_gambling':
        return 'gambling';
      default:
        return 'this addiction';
    }
  }
}
