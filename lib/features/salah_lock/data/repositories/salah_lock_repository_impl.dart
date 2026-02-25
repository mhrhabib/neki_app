import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/salah_lock_settings.dart';
import '../../domain/repositories/salah_lock_repository.dart';

class SalahLockRepositoryImpl implements SalahLockRepository {
  final SharedPreferences prefs;

  static const String _keyEnabled = 'salah_lock_enabled';
  static const String _keyLockAndroid = 'salah_lock_android';
  static const String _keyAutoLockSocialIos = 'salah_lock_social_ios';
  static const String _keyStreakTracking = 'salah_lock_streak_tracking';
  static const String _keyAutoUnlockMins = 'salah_lock_auto_unlock_mins';
  static const String _keyCompletionsPrefix = 'salah_lock_done_';

  SalahLockRepositoryImpl(this.prefs);

  @override
  Future<SalahLockSettings> getSettings() async {
    return SalahLockSettings(
      isEnabled: prefs.getBool(_keyEnabled) ?? false,
      lockDeviceAndroid: prefs.getBool(_keyLockAndroid) ?? false,
      autoLockSocialIos: prefs.getBool(_keyAutoLockSocialIos) ?? false,
      streakTracking: prefs.getBool(_keyStreakTracking) ?? false,
      autoUnlockMinutes: prefs.getInt(_keyAutoUnlockMins) ?? 120,
    );
  }

  @override
  Future<void> saveSettings(SalahLockSettings settings) async {
    await prefs.setBool(_keyEnabled, settings.isEnabled);
    await prefs.setBool(_keyLockAndroid, settings.lockDeviceAndroid);
    await prefs.setBool(_keyAutoLockSocialIos, settings.autoLockSocialIos);
    await prefs.setBool(_keyStreakTracking, settings.streakTracking);
    await prefs.setInt(_keyAutoUnlockMins, settings.autoUnlockMinutes);
  }

  @override
  Future<bool> isSalahCompletedLocally(String salahName) async {
    final today = _getTodayKey();
    return prefs.getBool('$_keyCompletionsPrefix${salahName}_$today') ?? false;
  }

  @override
  Future<void> markSalahCompletedLocally(String salahName) async {
    final today = _getTodayKey();
    await prefs.setBool('$_keyCompletionsPrefix${salahName}_$today', true);
  }

  @override
  Future<void> clearDailyCompletions() async {
    // SharedPreferences doesn't have a prefix clear, but we only call this
    // if we want to reset. Actually, using the date in the key handles expiry.
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
