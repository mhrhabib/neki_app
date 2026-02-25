import '../entities/salah_lock_settings.dart';

abstract class SalahLockRepository {
  Future<SalahLockSettings> getSettings();
  Future<void> saveSettings(SalahLockSettings settings);
  Future<bool> isSalahCompletedLocally(String salahName);
  Future<void> markSalahCompletedLocally(String salahName);
  Future<void> clearDailyCompletions();
}
