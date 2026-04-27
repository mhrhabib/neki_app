import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback type for when the user taps "I've prayed" on a notification.
typedef OnPrayedCallback = void Function(String salahName);

/// Callback type for when the user taps "Not praying" on a notification.
typedef OnSkipCallback = void Function(String salahName);

// ⚠️ iOS action title guidance: keep titles short, no leading/trailing
// whitespace, ideally no emoji. iOS truncates heavily and action rows
// with padded titles have been observed to render blank on some devices.
const String _kPrayedTitle = "I've prayed";
const String _kSkipTitle = 'Not praying';

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

  // How many notifications to schedule per prayer (initial + follow-ups).
  // ⚠️ Keep this small. Android's `exactAllowWhileIdle` queues every past-due
  // alarm and fires them all at boot, so a phone that was powered off will
  // dump every pending reminder into the user's tray at once. Capping at 2
  // means the worst-case flood is 5 prayers × 2 = 10, not 50.
  static const int _maxReminders = 2;
  static const Duration _interval = Duration(minutes: 15);

  static const String _actionIdPrayed = 'action_prayed';
  static const String _actionIdSkip = 'action_skip';
  static const String _channelId = 'salah_prayer_channel';
  static const String _channelName = 'Salah Prayer Notifications';
  static const String _reminderChannelId = 'salah_lock_channel';
  static const String _reminderChannelName = 'Salah Lock Reminders';

  static const Map<String, List<String>> _prayerMessages = {
    'Fajr': [
      'Rise and shine! Start your day with the blessings of Fajr. 🌅',
      'Fajr time is here. A beautiful start to a blessed day. ✨',
      'The world is quiet. Reconnect with your Creator in Fajr. 🕯️',
    ],
    'Dhuhr': [
      'Take a break and reconnect — it\'s Dhuhr time. ☀️',
      'Pause your worldly work for Dhuhr. Success comes from Him. 💼',
      'Dhuhr time. Refresh your soul and continue your day with Barakah. ⛅',
    ],
    'Asr': [
      'The afternoon prayer awaits. May Allah bless your efforts. 🌤️',
      'Asr time is here. Don\'t let the day slip away without prayer. ⏳',
      'Pause for Asr. Protect your afternoon with remembrance. 🕌',
    ],
    'Maghrib': [
      'The sun has set. Pray Maghrib and give thanks. 🌇',
      'Maghrib time. End the daylight with gratitude and prayer. ✨',
      'A moment of peace as the day ends. It\'s Maghrib time. 🌃',
    ],
    'Isha': [
      'End your day beautifully with Isha prayer. 🌙',
      'Isha time. Find rest in the words of your Lord before sleep. 🕯️',
      'Isha call. Prepare for a peaceful night with your final prayer. ✨',
    ],
  };

  static const Map<String, List<String>> _reminderMessages = {
    'Fajr': [
      'Fajr time is passing — don\'t miss your morning prayer! 🌅',
      'Still in bed? Fajr is the best start for your productivity. 🚀',
      'Fajr reminder: The time is short. Pray now and win the day. ⏳',
    ],
    'Dhuhr': [
      'Dhuhr is still waiting for you. Take a moment to pray. ☀️',
      'Don\'t forget Dhuhr! A 5-minute break for a lifetime of rewards. ✨',
      'Work can wait, Dhuhr cannot. Reconnect now. 💼',
    ],
    'Asr': [
      'Asr reminder — the time is running. Please pray. 🌤️',
      'Asr is passing soon. Secure your afternoon prayer now. ⏳',
      'Mid-day rush? Don\'t let it cost you your Asr. 🕌',
    ],
    'Maghrib': [
      'Maghrib reminder — pray before the time passes! 🌇',
      'The Maghrib window is short. Pray now to keep your streak. 🔥',
      'Maghrib time is flying. Reconnect with Allah right now. ✨',
    ],
    'Isha': [
      'Isha reminder — end your night with prayer. 🌙',
      'Reflect on your day through Isha. It\'s not too late. 🕯️',
      'Isha is still waiting. Sleep better knowing you prayed. ✨',
    ],
  };

  // Behavior-aware nudges
  static const Map<String, String> _motivationNudges = {
    'miss_streak': 'You\'ve missed a few recently. Let\'s make today different! 💪',
    'perfect_streak': 'You are on a roll! Keep that perfect streak alive. 🔥',
    'morning_miss': 'Morning prayers give you the most Barakah. Try your best today! 🌅',
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

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings
    iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'salah_prayer_category',
          actions: [
            DarwinNotificationAction.plain(
              _actionIdPrayed,
              _kPrayedTitle,
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              _actionIdSkip,
              _kSkipTitle,
              // Note: do NOT combine .destructive with .foreground — some
              // iOS versions refuse to render the action when both are set.
              // Keep it destructive (red text) and handle the tap in the
              // background handler so the user isn't forced to open the app.
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
          options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
        ),
      ],
    );

    await _notificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Note: we intentionally DO NOT request user-facing permissions here.
    // [initialize] runs during DI setup before the app's first frame, and
    // triggering a system permission dialog at that moment is jarring and
    // often gets auto-dismissed. Callers should invoke
    // [requestPermissions] once the UI is ready (e.g. after login or from
    // the onboarding location page).
  }

  /// Ensures the app is allowed to post notifications. Safe to call repeatedly
  /// — the OS only shows the dialog once per install. Returns true if the
  /// user granted (or previously granted) notification permission.
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission() ?? false;
      debugPrint('🔔 Android POST_NOTIFICATIONS granted=$granted');
      return granted;
    }
    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios == null) return false;
      final granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: false,
          ) ??
          false;
      debugPrint('🔔 iOS notification permission granted=$granted');
      return granted;
    }
    return true;
  }

  /// Returns true if the OS currently allows the app to post notifications.
  /// Does NOT show a dialog. Use this to decide whether to show an in-app
  /// "please enable notifications" prompt.
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled() ?? false;
      return enabled;
    }
    if (Platform.isIOS) {
      final ios = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }

  /// Prints how many pending notifications the OS currently holds for this
  /// app. Useful for diagnosing "I never get reminders" bug reports.
  Future<int> debugLogPending() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('🔔 Pending notifications: ${pending.length}');
    for (final p in pending) {
      debugPrint('   id=${p.id} title=${p.title} payload=${p.payload}');
    }
    return pending.length;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '🔔 Notification: action=${response.actionId}, payload=${response.payload}',
    );
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
  static Future<void> _onBackgroundNotificationResponse(
    NotificationResponse response,
  ) async {
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
      final dateKey =
          '${logicalNow.year}-${logicalNow.month}-${logicalNow.day}';
      await prefs.setBool('salah_lock_done_${payload}_$dateKey', true);

      // 2. Cancel all remaining reminder slots for this prayer so they stop firing.
      final base = _prayerBaseIds[payload];
      if (base != null) {
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/launcher_icon'),
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
            AndroidNotificationAction(
              _actionIdPrayed,
              _kPrayedTitle,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              _actionIdSkip,
              _kSkipTitle,
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
    final scheduled = tz.TZDateTime.now(
      location,
    ).add(Duration(seconds: seconds));
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
            AndroidNotificationAction(
              _actionIdPrayed,
              _kPrayedTitle,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              _actionIdSkip,
              _kSkipTitle,
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
    int missedCount = 0,
    bool isPerfectStreak = false,
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

    debugPrint(
      '🕐 Scheduling prayers: TZ=${location.name}, now=$now, mode=$scheduleMode',
    );

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

      // If this prayer time has fully passed and it's Fajr, schedule tomorrow's Fajr instead.
      // Fajr's valid window ends at sunrise, not at Dhuhr — the gap between sunrise and
      // Dhuhr is a forbidden-prayer period, so reminders must not fire there.
      final tz.TZDateTime windowEnd = name == 'Fajr'
          ? tz.TZDateTime.from(prayerTimes.sunrise, location)
          : p + 1 < orderedPrayers.length
              ? tz.TZDateTime.from(orderedPrayers[p + 1].$2, location)
              : tz.TZDateTime(
                  location,
                  tzPrayerTime.year,
                  tzPrayerTime.month,
                  tzPrayerTime.day,
                  23,
                  59,
                );

      if (!windowEnd.isAfter(now) &&
          name == 'Fajr' &&
          tomorrowPrayerTimes != null) {
        // Today's Fajr window is over — schedule tomorrow's Fajr
        try {
          final tomorrowFajr = tz.TZDateTime.from(
            tomorrowPrayerTimes.fajr,
            location,
          );
          final tomorrowDhuhr = tz.TZDateTime.from(
            tomorrowPrayerTimes.dhuhr,
            location,
          );

          int slot = 0;
          tz.TZDateTime fireAt = tomorrowFajr;
          while (slot < _maxReminders &&
              fireAt.isBefore(tomorrowDhuhr) &&
              (Platform.isAndroid || totalScheduled < iosMaxPending)) {
            final isFirst = slot == 0;
            await _notificationsPlugin.zonedSchedule(
              base + slot,
              '🕌 $name Time',
              _getRotatingMessage(
                name,
                slot,
                isFirst: isFirst,
                missedCount: missedCount,
                isPerfectStreak: isPerfectStreak,
              ),
              fireAt,
              _notificationDetails(name),
              payload: name,
              androidScheduleMode: scheduleMode,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            totalScheduled++;
            debugPrint(
              '🔔 $name [slot $slot] scheduled TOMORROW at ${fireAt.toLocal()} (total: $totalScheduled)',
            );
            slot++;
            fireAt = tomorrowFajr.add(_interval * slot);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to schedule tomorrow Fajr: $e');
        }
        continue;
      }

      // Anchor for the first slot. If the prayer time is in the past but
      // the window is still open (user opened the app mid-prayer), anchor
      // to "now + 3s" so we still schedule reminders across the remainder
      // of the window — otherwise a user who opens the app 45+ min after
      // the adhan would never hear a single reminder for that prayer.
      final tz.TZDateTime anchor = tzPrayerTime.isBefore(now)
          ? now.add(const Duration(seconds: 3))
          : tzPrayerTime;

      int slot = 0;
      tz.TZDateTime fireAt = anchor;

      while (slot < _maxReminders &&
          fireAt.isBefore(windowEnd) &&
          (Platform.isAndroid || totalScheduled < iosMaxPending)) {
        // By construction fireAt >= now, so no past-time guard needed.
        final isFirst = slot == 0;
        await _notificationsPlugin.zonedSchedule(
          base + slot,
          '🕌 $name Time',
          _getRotatingMessage(
            name,
            slot,
            isFirst: isFirst,
            missedCount: missedCount,
            isPerfectStreak: isPerfectStreak,
          ),
          fireAt,
          _notificationDetails(name),
          payload: name,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        totalScheduled++;
        debugPrint(
          '🔔 $name [slot $slot] scheduled at ${fireAt.toLocal()} (total: $totalScheduled)',
        );
        slot++;
        fireAt = anchor.add(_interval * slot);
      }

      if (slot == 0) {
        debugPrint('⏭️ $name — window fully passed, skipping');
      }
    }

    debugPrint(
      '📊 Total notifications scheduled: $totalScheduled (iOS limit: $iosMaxPending)',
    );
  }

  String _getRotatingMessage(
    String name,
    int slot, {
    bool isFirst = false,
    int missedCount = 0,
    bool isPerfectStreak = false,
  }) {
    // 1. Check for behavior nudges first (only on first notification)
    if (isFirst) {
      if (missedCount >= 3) return _motivationNudges['miss_streak']!;
      if (isPerfectStreak) return _motivationNudges['perfect_streak']!;
    }

    // 2. Pick from rotating list
    final list = isFirst ? _prayerMessages[name] : _reminderMessages[name];
    if (list == null || list.isEmpty) return 'Time for $name prayer.';

    // Use slot to rotate so reminders change over the window
    return list[slot % list.length];
  }

  /// Returns true if the device supports and has granted exact alarm permission.
  Future<bool> _canUseExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final plugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
            "   I've prayed ✅   ",
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            _actionIdSkip,
            "   not praying ✕   ",
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
        // Note: InterruptionLevel.timeSensitive requires the
        // `com.apple.developer.usernotifications.time-sensitive` entitlement
        // — without it, iOS silently downgrades the notification and on some
        // devices fails to render the action row entirely. Stick to the
        // default interruption level until/unless the entitlement is added.
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
              _kPrayedTitle,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              _actionIdSkip,
              _kSkipTitle,
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


  /// Schedule daily recurring Dhikr notifications.
  Future<void> scheduleDhikrReminders() async {
    final location = _tzLocation();
    final now = tz.TZDateTime.now(location);
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final morningTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 8, 0);
    final eveningTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 16, 0);

    // Morning Dhikr
    await _notificationsPlugin.zonedSchedule(
      800,
      'Time for Morning Dhikr 🌅',
      'Start your day with remembrance of Allah.',
      morningTime.isBefore(now)
          ? morningTime.add(const Duration(days: 1))
          : morningTime,
      _dhikrNotificationDetails(),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Evening Dhikr
    await _notificationsPlugin.zonedSchedule(
      801,
      'Time for Evening Dhikr 🌇',
      'End your day with peace and gratitude.',
      eveningTime.isBefore(now)
          ? eveningTime.add(const Duration(days: 1))
          : eveningTime,
      _dhikrNotificationDetails(),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('🔔 Dhikr reminders scheduled: 08:00 and 16:00 daily');
  }

  NotificationDetails _dhikrNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'dhikr_reminder_channel',
        'Dhikr Reminders',
        channelDescription: 'Daily Morning and Evening Dhikr reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
  }

  /// Schedule daily recurring Quran notifications.
  Future<void> scheduleQuranReminders() async {
    final location = _tzLocation();
    final now = tz.TZDateTime.now(location);
    final scheduleMode = await _canUseExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final morningTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 10, 0);
    final eveningTime =
        tz.TZDateTime(location, now.year, now.month, now.day, 20, 0);

    // Morning Quran
    await _notificationsPlugin.zonedSchedule(
      802,
      'Time for Quran Recitation 📖',
      'Illuminate your day with the words of Allah.',
      morningTime.isBefore(now)
          ? morningTime.add(const Duration(days: 1))
          : morningTime,
      _quranNotificationDetails(),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Evening Quran
    await _notificationsPlugin.zonedSchedule(
      803,
      'Time for Quran Recitation 📖',
      'Find peace and reflection in the Quran tonight.',
      eveningTime.isBefore(now)
          ? eveningTime.add(const Duration(days: 1))
          : eveningTime,
      _quranNotificationDetails(),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('🔔 Quran reminders scheduled: 10:00 and 20:00 daily');
  }

  NotificationDetails _quranNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'quran_reminder_channel',
        'Quran Reminders',
        channelDescription: 'Daily Morning and Evening Quran reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );
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
