import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback type for when the user taps "I've Prayed" on a notification.
typedef OnPrayedCallback = void Function(String salahName);

/// Callback type for when the user taps "Not Praying" on a notification.
typedef OnSkipCallback = void Function(String salahName);

class SalahNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Set by the cubit so notification actions work from any app state.
  static OnPrayedCallback? onPrayedAction;
  static OnSkipCallback? onSkipAction;

  // Each prayer has a base ID. We schedule up to _maxReminders notifications
  // per prayer (every 5 min), using IDs: base, base+1, base+2 ...
  static const Map<String, int> _prayerBaseIds = {'Fajr': 100, 'Dhuhr': 200, 'Asr': 300, 'Maghrib': 400, 'Isha': 500};

  // How many 5-minute-interval notifications to schedule per prayer.
  // 10 × 5 min = 50 minutes of reminders max.
  // ⚠️ iOS has a hard limit of 64 pending local notifications per app.
  // 5 prayers × 10 slots = 50 total, safely under the 64 limit.
  static const int _maxReminders = 10;
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
    // Set the local timezone from the device so scheduled times are correct.
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      debugPrint('🕐 Timezone set to: $tzInfo');
    } catch (e) {
      debugPrint('⚠️ Could not set timezone: $e');
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
              options: {DarwinNotificationActionOption.destructive, DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    await _notificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Explicitly request iOS notification permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notification: action=${response.actionId}, payload=${response.payload}');
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
  static Future<void> _onBackgroundNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    final bool isPrayed = response.actionId == _actionIdPrayed;
    final bool isSkip = response.actionId == _actionIdSkip;
    if (!isPrayed && !isSkip) return;

    // This runs in a background isolate on Android (static fields are null here).
    // We must do all work directly via SharedPreferences + the plugin.
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Persist completion so the next checkPrayerLock call sees it as done.
      final prefs = await SharedPreferences.getInstance();
      final logicalNow = DateTime.now().subtract(const Duration(hours: 4));
      final dateKey = '${logicalNow.year}-${logicalNow.month}-${logicalNow.day}';
      await prefs.setBool('salah_lock_done_${payload}_$dateKey', true);

      // 2. Cancel all remaining reminder slots for this prayer so they stop firing.
      final base = _prayerBaseIds[payload];
      if (base != null) {
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
        );
        for (int i = 0; i < _maxReminders; i++) {
          await plugin.cancel(base + i);
        }
      }
    } catch (e) {
      // Non-fatal: the app will reconcile state on next open via checkPrayerLock.
      debugPrint('⚠️ Background notification handler error: $e');
    }
  }

  // ─── Test ──────────────────────────────────────────────────────────────────

  /// Shows a notification immediately (for testing — no scheduling required).
  Future<void> showTestNotificationNow() async {
    debugPrint('🧪 Showing test notification immediately...');
    await _notificationsPlugin.show(
      999,
      '🕌 TEST — Fajr Time',
      'This is a test notification. If you see this, notifications work!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Salah Lock Mode reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          actions: const [
            AndroidNotificationAction(_actionIdPrayed, "I've Prayed ✅", showsUserInterface: true),
            AndroidNotificationAction(
              _actionIdSkip,
              "Not Praying ✕",
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: 'Fajr',
    );
    debugPrint('🧪 Test notification shown.');
  }

  /// Schedules a test notification in [seconds] seconds.
  Future<void> scheduleTestNotification({int seconds = 10}) async {
    final location = _tzLocation();

    // ✅ Use TZDateTime.now instead of mixing DateTime types
    final scheduled = tz.TZDateTime.now(location).add(Duration(seconds: seconds));
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('🧪 Scheduling test notification at ${scheduled.toLocal()}');
    debugPrint('🧪 Current TZ time: ${tz.TZDateTime.now(location).toLocal()}');
    debugPrint('🧪 Schedule mode: $scheduleMode');

    await _notificationsPlugin.zonedSchedule(
      998,
      '🕌 TEST — Asr Reminder',
      'Scheduled test fired! Notifications + timezone are working correctly.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Salah Lock Mode reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          actions: const [
            AndroidNotificationAction(_actionIdPrayed, "I've Prayed ✅", showsUserInterface: true),
            AndroidNotificationAction(
              _actionIdSkip,
              "Not Praying ✕",
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: 'Asr',
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('🧪 Test notification scheduled.');
  }
  // ─── Scheduling ────────────────────────────────────────────────────────────

  /// Schedule repeating 5-minute notifications for all 5 prayers today.
  /// Each prayer gets up to [_maxReminders] notifications starting at prayer
  /// time, spaced [_interval] apart, stopping at the next prayer time.
  Future<void> scheduleAllPrayerNotifications(
    PrayerTimes prayerTimes, {
    PrayerTimes? tomorrowPrayerTimes,
    Set<String> completedPrayers = const {},
  }) async {
    await cancelPrayerNotifications();

    final tz.Location location = _tzLocation();
    final now = tz.TZDateTime.now(location);
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Track total scheduled count to respect iOS 64-notification limit
    int totalScheduled = 0;
    const int iosMaxPending = 64;

    debugPrint('🕐 Scheduling prayers: TZ=${location.name}, now=$now, mode=$scheduleMode');

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

      // Skip prayers the user already responded to today
      if (completedPrayers.contains(name)) {
        debugPrint('⏭️ $name — already completed, skipping notifications');
        continue;
      }

      // Convert prayer time to timezone-aware for consistent comparisons
      var tzPrayerTime = tz.TZDateTime.from(prayerTime, location);

      // If this prayer time has fully passed and it's Fajr, schedule tomorrow's Fajr instead
      final tz.TZDateTime windowEnd = p + 1 < orderedPrayers.length
          ? tz.TZDateTime.from(orderedPrayers[p + 1].$2, location)
          : tz.TZDateTime(location, tzPrayerTime.year, tzPrayerTime.month, tzPrayerTime.day, 23, 59);

      if (!windowEnd.isAfter(now) && name == 'Fajr' && tomorrowPrayerTimes != null) {
        // Today's Fajr window is over — schedule tomorrow's Fajr
        try {
          final tomorrowFajr = tz.TZDateTime.from(tomorrowPrayerTimes.fajr, location);
          final tomorrowDhuhr = tz.TZDateTime.from(tomorrowPrayerTimes.dhuhr, location);

          int slot = 0;
          tz.TZDateTime fireAt = tomorrowFajr;
          while (slot < _maxReminders && fireAt.isBefore(tomorrowDhuhr) && (Platform.isAndroid || totalScheduled < iosMaxPending)) {
            final isFirst = slot == 0;
            await _notificationsPlugin.zonedSchedule(
              base + slot,
              '🕌 $name Time',
              isFirst
                  ? (_prayerMessages[name] ?? 'Time for $name prayer.')
                  : (_reminderMessages[name] ?? 'Reminder: $name prayer.'),
              fireAt,
              _notificationDetails(name),
              payload: name,
              androidScheduleMode: scheduleMode,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
            totalScheduled++;
            debugPrint('🔔 $name [slot $slot] scheduled TOMORROW at ${fireAt.toLocal()} (total: $totalScheduled)');
            slot++;
            fireAt = tomorrowFajr.add(_interval * slot);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to schedule tomorrow Fajr: $e');
        }
        continue;
      }

      int slot = 0;
      tz.TZDateTime fireAt = tzPrayerTime;

      while (slot < _maxReminders && fireAt.isBefore(windowEnd) && (Platform.isAndroid || totalScheduled < iosMaxPending)) {
        if (fireAt.isAfter(now)) {
          final scheduled = fireAt;
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
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
          totalScheduled++;
          debugPrint('🔔 $name [slot $slot] scheduled at ${scheduled.toLocal()} (total: $totalScheduled)');
        }
        slot++;
        fireAt = tzPrayerTime.add(_interval * slot);
      }

      if (slot == 0) {
        debugPrint('⏭️ $name — all times passed, skipping');
      }
    }

    debugPrint('📊 Total notifications scheduled: $totalScheduled (iOS limit: $iosMaxPending)');
  }

  /// Returns true if the device supports and has granted exact alarm permission.
  Future<bool> _canUseExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
          AndroidNotificationAction(_actionIdPrayed, "I've Prayed ✅", showsUserInterface: true),
          AndroidNotificationAction(
            _actionIdSkip,
            "Not Praying ✕",
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
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
            AndroidNotificationAction(_actionIdPrayed, "I've Prayed ✅", showsUserInterface: true),
            AndroidNotificationAction(
              _actionIdSkip,
              "Not Praying ✕",
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: salahName,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
