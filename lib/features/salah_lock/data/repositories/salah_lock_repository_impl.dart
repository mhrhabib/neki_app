import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/salah_lock_settings.dart';
import '../../domain/repositories/salah_lock_repository.dart';

class SalahLockRepositoryImpl implements SalahLockRepository {
  final SharedPreferences prefs;

  static const String _keyEnabled = 'salah_lock_enabled';
  static const String _keyStreakTracking = 'salah_lock_streak_tracking';
  static const String _keyAutoUnlockMins = 'salah_lock_auto_unlock_mins';
  static const String _keyCompletionsPrefix = 'salah_lock_done_';
  static const String _keyGuideDismissed = 'salah_lock_guide_dismissed';
  static const String _keyLastNotificationDate = 'salah_lock_last_notif_date';

  SalahLockRepositoryImpl(this.prefs);

  @override
  Future<SalahLockSettings> getSettings() async {
    return SalahLockSettings(
      isEnabled: prefs.getBool(_keyEnabled) ?? true,
      streakTracking: prefs.getBool(_keyStreakTracking) ?? true,
      autoUnlockMinutes: prefs.getInt(_keyAutoUnlockMins) ?? 120,
    );
  }

  @override
  Future<void> saveSettings(SalahLockSettings settings) async {
    await prefs.setBool(_keyEnabled, settings.isEnabled);
    await prefs.setBool(_keyStreakTracking, settings.streakTracking);
    await prefs.setInt(_keyAutoUnlockMins, settings.autoUnlockMinutes);
  }

  @override
  Future<bool> isSalahCompletedLocally(String salahName) async {
    return prefs.getBool('$_keyCompletionsPrefix${salahName}_${_getTodayKey()}') ?? false;
  }

  @override
  Future<void> markSalahCompletedLocally(String salahName) async {
    await prefs.setBool('$_keyCompletionsPrefix${salahName}_${_getTodayKey()}', true);
  }

  @override
  Future<void> clearDailyCompletions() async {}

  @override
  Future<bool> isGuideDismissed() async {
    return prefs.getBool(_keyGuideDismissed) ?? false;
  }

  @override
  Future<void> setGuideDismissed(bool dismissed) async {
    await prefs.setBool(_keyGuideDismissed, dismissed);
  }

  @override
  Future<String?> getLastNotificationDate() async {
    return prefs.getString(_keyLastNotificationDate);
  }

  @override
  Future<void> saveLastNotificationDate(String dateKey) async {
    await prefs.setString(_keyLastNotificationDate, dateKey);
  }

  String _getTodayKey() {
    // Shift logical day by 4 hours backwards to match SalahRepositoryImpl
    final logicalNow = DateTime.now().subtract(const Duration(hours: 4));
    return '${logicalNow.year}-${logicalNow.month}-${logicalNow.day}';
  }
}
