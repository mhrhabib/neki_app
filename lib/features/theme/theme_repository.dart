import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeRepository {
  bool getIsDarkMode();
  Future<void> setIsDarkMode(bool isDark);
  Future<void> loadTheme();
}

class ThemeRepositoryImpl implements ThemeRepository {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  bool _isLoaded = false;

  @override
  bool getIsDarkMode() {
    return _isDarkMode;
  }

  @override
  Future<void> setIsDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  @override
  Future<void> loadTheme() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _isLoaded = true;
  }
}
