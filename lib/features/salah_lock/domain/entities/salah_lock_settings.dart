class SalahLockSettings {
  final bool isEnabled;
  final bool streakTracking;
  final int autoUnlockMinutes;
  /// List of prayer names that have lock/notifications enabled (e.g. ['Fajr', 'Isha']).
  /// Limited to 2 for free users.
  final List<String> enabledPrayers;

  SalahLockSettings({
    this.isEnabled = true,
    this.streakTracking = true,
    this.autoUnlockMinutes = 120,
    this.enabledPrayers = const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
  });

  SalahLockSettings copyWith({
    bool? isEnabled,
    bool? streakTracking,
    int? autoUnlockMinutes,
    List<String>? enabledPrayers,
  }) {
    return SalahLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      streakTracking: streakTracking ?? this.streakTracking,
      autoUnlockMinutes: autoUnlockMinutes ?? this.autoUnlockMinutes,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
    );
  }
}
