class SalahLockSettings {
  final bool isEnabled;
  final bool streakTracking;
  final int autoUnlockMinutes;

  SalahLockSettings({
    this.isEnabled = true,
    this.streakTracking = true,
    this.autoUnlockMinutes = 120,
  });

  SalahLockSettings copyWith({
    bool? isEnabled,
    bool? streakTracking,
    int? autoUnlockMinutes,
  }) {
    return SalahLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      streakTracking: streakTracking ?? this.streakTracking,
      autoUnlockMinutes: autoUnlockMinutes ?? this.autoUnlockMinutes,
    );
  }
}
