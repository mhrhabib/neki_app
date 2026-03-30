import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback type for when the user taps "I've Prayed" on a notification.
typedef OnPrayedCallback = void Function(String salahName);

class SalahNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Global callback — set by the cubit so notification actions can trigger confirmPrayed.
  static OnPrayedCallback? onPrayedAction;

  // Unique notification IDs per prayer
  static const Map<String, int> _prayerNotificationIds = {
    'Fajr': 101,
    'Dhuhr': 102,
    'Asr': 103,
    'Maghrib': 104,
    'Isha': 105,
  };

  static const String _actionIdPrayed = 'action_prayed';
  static const String _channelId = 'salah_prayer_channel';
  static const String _channelName = 'Salah Prayer Notifications';
  static const String _reminderChannelId = 'salah_lock_channel';
  static const String _reminderChannelName = 'Salah Lock Reminders';

  // Motivational messages per prayer
  static const Map<String, String> _prayerMessages = {
    'Fajr': 'Rise and shine! Start your day with the blessings of Fajr. 🌅',
    'Dhuhr': 'Take a break and reconnect — it\'s Dhuhr time. ☀️',
    'Asr': 'The afternoon prayer awaits. May Allah bless your efforts. 🌤️',
    'Maghrib': 'The sun has set. Pray Maghrib and give thanks. 🌇',
    'Isha': 'End your day beautifully with Isha prayer. 🌙',
  };

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
          ],
        ),
      ],
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handles notification tap and action button responses.
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notification response: action=${response.actionId}, payload=${response.payload}');
    if (response.actionId == _actionIdPrayed && response.payload != null) {
      onPrayedAction?.call(response.payload!);
    } else if (response.actionId == null && response.payload != null) {
      // User tapped the notification body (not an action button)
      // This opens the app — the overlay will handle it
      debugPrint('🔔 Notification tapped for ${response.payload}');
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Background handler — limited capability, but log for debugging
    debugPrint('🔔 Background notification response: action=${response.actionId}, payload=${response.payload}');
  }

  /// Schedule notifications for all 5 prayer times.
  Future<void> scheduleAllPrayerNotifications(PrayerTimes prayerTimes) async {
    // Cancel existing prayer notifications first
    for (final id in _prayerNotificationIds.values) {
      await _notificationsPlugin.cancel(id);
    }

    final now = DateTime.now();

    final prayers = {
      'Fajr': prayerTimes.fajr,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };

    for (final entry in prayers.entries) {
      final name = entry.key;
      final time = entry.value;

      // Only schedule if the prayer time is in the future
      if (time.isAfter(now)) {
        await _schedulePrayerNotification(name, time);
      } else {
        debugPrint('⏭️ Skipping $name notification — time has passed (${time.toLocal()})');
      }
    }
  }

  /// Schedule a single prayer notification at the exact prayer time.
  Future<void> _schedulePrayerNotification(String salahName, DateTime prayerTime) async {
    final id = _prayerNotificationIds[salahName];
    if (id == null) return;

    tz.Location location;
    try {
      location = tz.local;
    } catch (_) {
      location = tz.UTC;
    }

    final scheduledDate = tz.TZDateTime.from(prayerTime, location);
    final message = _prayerMessages[salahName] ?? 'It\'s time for $salahName prayer.';

    debugPrint('🔔 Scheduling $salahName notification at ${scheduledDate.toLocal()}');

    await _notificationsPlugin.zonedSchedule(
      id,
      '🕌 $salahName Time',
      message,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifications when each Salah time begins',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              _actionIdPrayed,
              "I've Prayed ✅",
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: salahName,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('✅ $salahName notification scheduled for ${scheduledDate.toLocal()}');
  }

  /// Schedule a "Remind me later" notification after a delay.
  Future<void> scheduleReminder(String salahName, Duration delay) async {
    tz.Location location;
    try {
      location = tz.local;
    } catch (_) {
      location = tz.UTC;
    }

    await _notificationsPlugin.zonedSchedule(
      0, // Use ID 0 for reminders (separate from prayer IDs)
      'Salah Reminder',
      'It is time for $salahName. Please take a moment to pray.',
      tz.TZDateTime.now(location).add(delay),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: 'Notifications for Salah Lock Mode reminders',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              _actionIdPrayed,
              "I've Prayed ✅",
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'salah_prayer_category',
        ),
      ),
      payload: salahName,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel only prayer-time notifications (not reminders).
  Future<void> cancelPrayerNotifications() async {
    for (final id in _prayerNotificationIds.values) {
      await _notificationsPlugin.cancel(id);
    }
  }
}
