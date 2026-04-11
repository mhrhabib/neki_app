import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/premium_repository.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final SharedPreferences _prefs;
  static const String _premiumKey = 'is_premium_user';

  final _premiumController = StreamController<bool>.broadcast();

  PremiumRepositoryImpl(this._prefs) {
    _premiumController.add(isPremiumSync());
  }

  @override
  Future<bool> isPremium() async {
    return _prefs.getBool(_premiumKey) ?? false;
  }

  bool isPremiumSync() {
    return _prefs.getBool(_premiumKey) ?? false;
  }

  @override
  Future<void> setPremium(bool isPremium) async {
    await _prefs.setBool(_premiumKey, isPremium);
    _premiumController.add(isPremium);
  }

  @override
  Stream<bool> get premiumStatusStream => _premiumController.stream;
}
