import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback type for when the user taps "I've Prayed" on a notification.
typedef OnPrayedCallback = void Function(String salahName);

/// Callback type for when the user taps "Not Praying" on a notification.
typedef OnSkipCallback = void Function(String salahName);

class SalahNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the cubit so notification actions work from any app state.
  static OnPrayedCallback? onPrayedAction;
  static OnSkipCallback? onSkipAction;

  // Each prayer has a base ID. We schedule up to _maxReminders notifications
  // per prayer (every 5 min), using IDs: base, base+1, base+2 ...
  static const Map<String, int> _prayerBaseIds = {
    'Fajr': 100,
    'Dhuhr': 200,
    'Asr': 300,
    'Maghrib': 400,
    'Isha': 500,
  };

  // How many 5-minute-interval notifications to schedule per prayer.
  // 24 × 5 min = 2 hours of reminders max.
  static const int _maxReminders = 24;
  static const Duration _interval = Duration(minutes: 5);

  static const String _actionIdPrayed = 'action_prayed';
  static const String _actionIdSkip = 'action_skip';
  static const String _channelId = 'salah_prayer_channel';
  static const String _channelName = 'Salah Prayer Notifications';
  static const String _reminderChannelId = 'salah_lock_channel';
  static const String _reminderChannelName = 'Salah Lock Reminders';

  static const Map<String, String> _prayerMessages = {
    'Fajr': 'Rise and shine! Start your day with the blessings of Fajr. 🌅',
    'Dhuhr': 'Take a break and reconnect — it\'s Dhuhr time. ☀️',
    'Asr': 'The afternoon prayer awaits. May Allah bless your efforts. 🌤️',
    'Maghrib': 'The sun has set. Pray Maghrib and give thanks. 🌇',
    'Isha': 'End your day beautifully with Isha prayer. 🌙',
  };

  static const Map<String, String> _reminderMessages = {
    'Fajr': 'Fajr time is passing — don\'t miss your morning prayer! 🌅',
    'Dhuhr': 'Dhuhr is still waiting for you. Take a moment to pray. ☀️',
    'Asr': 'Asr reminder — the time is running. Please pray. 🌤️',
    'Maghrib': 'Maghrib reminder — pray before the time passes! 🌇',
    'Isha': 'Isha reminder — end your night with prayer. 🌙',
  };

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'salah_prayer_category',
          actions: [
            DarwinNotificationAction.plain(
              _actionIdPrayed,
              "I've Prayed ✅",
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              _actionIdSkip,
              "Not Praying ✕",
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    await _notificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
        '🔔 Notification: action=${response.actionId}, payload=${response.payload}');
    final payload = response.payload;
    if (payload == null) return;

    if (response.actionId == _actionIdPrayed) {
      onPrayedAction?.call(payload);
    } else if (response.actionId == _actionIdSkip) {
      onSkipAction?.call(payload);
    }
    // Tapping the body opens the app — the salah lock overlay handles it.
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    if (response.actionId == _actionIdPrayed) {
      onPrayedAction?.call(payload);
    } else if (response.actionId == _actionIdSkip) {
      onSkipAction?.call(payload);
    }
  }

  // ─── Scheduling ────────────────────────────────────────────────────────────

  /// Schedule repeating 5-minute notifications for all 5 prayers today.
  /// Each prayer gets up to [_maxReminders] notifications starting at prayer
  /// time, spaced [_interval] apart, stopping at the next prayer time.
  Future<void> scheduleAllPrayerNotifications(PrayerTimes prayerTimes) async {
    await cancelPrayerNotifications();

    final now = DateTime.now();
    final tz.Location location = _tzLocation();
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final orderedPrayers = [
      ('Fajr', prayerTimes.fajr),
      ('Dhuhr', prayerTimes.dhuhr),
      ('Asr', prayerTimes.asr),
      ('Maghrib', prayerTimes.maghrib),
      ('Isha', prayerTimes.isha),
    ];

    for (int p = 0; p < orderedPrayers.length; p++) {
      final (name, prayerTime) = orderedPrayers[p];
      final base = _prayerBaseIds[name]!;

      // The window ends at the next prayer time (or midnight for Isha)
      final DateTime windowEnd = p + 1 < orderedPrayers.length
          ? orderedPrayers[p + 1].$2
          : DateTime(prayerTime.year, prayerTime.month, prayerTime.day, 23, 59);

      int slot = 0;
      DateTime fireAt = prayerTime;

      while (slot < _maxReminders && fireAt.isBefore(windowEnd)) {
        if (fireAt.isAfter(now)) {
          final scheduled = tz.TZDateTime.from(fireAt, location);
          final isFirst = slot == 0;
          await _notificationsPlugin.zonedSchedule(
            base + slot,
            '🕌 $name Time',
            isFirst
                ? (_prayerMessages[name] ?? 'Time for $name prayer.')
                : (_reminderMessages[name] ?? 'Reminder: $name prayer.'),
            scheduled,
            _notificationDetails(name),
            payload: name,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('🔔 $name [slot $slot] scheduled at ${scheduled.toLocal()}');
        }
        slot++;
        fireAt = prayerTime.add(_interval * slot);
      }

      if (slot == 0) {
        debugPrint('⏭️ $name — all times passed, skipping');
      }
    }
  }

  /// Returns true if the device supports and has granted exact alarm permission.
  Future<bool> _canUseExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final plugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return false;
    return await plugin.canScheduleExactNotifications() ?? false;
  }

  NotificationDetails _notificationDetails(String salahName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Salah prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        actions: const [
          AndroidNotificationAction(
            _actionIdPrayed,
            "I've Prayed ✅",
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionIdSkip,
            "Not Praying ✕",
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'salah_prayer_category',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Schedule a one-off snooze reminder (used by "Remind Later" in-app button).
  Future<void> scheduleReminder(String salahName, Duration delay) async {
    final location = _tzLocation();
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _notificationsPlugin.zonedSchedule(
      0,
      'Salah Reminder',
      'It is time for $salahName. Please take a moment to pray.',
      tz.TZDateTime.now(location).add(delay),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Salah Lock Mode reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(
              _actionIdPrayed,
              "I've Prayed ✅",
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              _actionIdSkip,
              "Not Praying ✕",
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: salahName,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Cancellation ──────────────────────────────────────────────────────────

  /// Cancel all prayer notifications for a specific prayer (all 24 slots).
  Future<void> cancelPrayerByName(String salahName) async {
    final base = _prayerBaseIds[salahName];
    if (base == null) return;
    for (int i = 0; i < _maxReminders; i++) {
      await _notificationsPlugin.cancel(base + i);
    }
  }

  /// Cancel all prayer notifications for all prayers.
  Future<void> cancelPrayerNotifications() async {
    for (final base in _prayerBaseIds.values) {
      for (int i = 0; i < _maxReminders; i++) {
        await _notificationsPlugin.cancel(base + i);
      }
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  tz.Location _tzLocation() {
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }
}
