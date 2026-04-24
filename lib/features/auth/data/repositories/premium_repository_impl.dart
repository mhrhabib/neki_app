import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/premium_repository.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final SharedPreferences _prefs;
  static const String _premiumKey = 'is_premium_user';
  static const String _trialStartKey = 'trial_started_at';
  static const int _trialDurationDays = 7;

  final _premiumController = StreamController<bool>.broadcast();

  PremiumRepositoryImpl(this._prefs) {
    _premiumController.add(isPremiumSync());
  }

  @override
  Future<bool> isPremium() async {
    return isPremiumSync();
  }

  @override
  bool isPremiumSync() {
    return true; // Unlocked for Donation Mode
  }

  @override
  Future<void> setPremium(bool isPremium) async {
    await _prefs.setBool(_premiumKey, isPremium);
    _premiumController.add(isPremiumSync());
  }

  @override
  Stream<bool> get premiumStatusStream => _premiumController.stream;

  // --- Trial Logic ---

  @override
  Future<DateTime?> getTrialStartDate() async {
    final timestamp = _prefs.getInt(_trialStartKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<void> startTrial() async {
    final existing = _prefs.getInt(_trialStartKey);
    if (existing == null) {
      await _prefs.setInt(
        _trialStartKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      _premiumController.add(isPremiumSync());
    }
  }

  @override
  bool isTrialActiveSync() {
    final timestamp = _prefs.getInt(_trialStartKey);
    if (timestamp == null) return false;

    final startDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;

    return difference < _trialDurationDays;
  }

  @override
  int trialDaysRemainingSync() {
    final timestamp = _prefs.getInt(_trialStartKey);
    if (timestamp == null) return 0;

    final startDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;

    final remaining = _trialDurationDays - difference;
    return remaining > 0 ? remaining : 0;
  }
}
