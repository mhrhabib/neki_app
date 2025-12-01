abstract class ThemeRepository {
  bool getIsDarkMode();
  Future<void> setIsDarkMode(bool isDark);
}

class ThemeRepositoryImpl implements ThemeRepository {
  @override
  bool getIsDarkMode() {
    // Placeholder: implement with storage
    return false;
  }

  @override
  Future<void> setIsDarkMode(bool isDark) async {
    // Placeholder: implement with storage
  }
}
