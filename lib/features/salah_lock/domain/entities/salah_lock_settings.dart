class SalahLockSettings {
  final bool isEnabled;
  final bool lockDeviceAndroid;
  final bool autoLockSocialIos;
  final bool streakTracking;
  final int autoUnlockMinutes;

  SalahLockSettings({
    this.isEnabled = false,
    this.lockDeviceAndroid = false,
    this.autoLockSocialIos = false,
    this.streakTracking = false,
    this.autoUnlockMinutes = 120,
  });

  SalahLockSettings copyWith({
    bool? isEnabled,
    bool? lockDeviceAndroid,
    bool? autoLockSocialIos,
    bool? streakTracking,
    int? autoUnlockMinutes,
  }) {
    return SalahLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      lockDeviceAndroid: lockDeviceAndroid ?? this.lockDeviceAndroid,
      autoLockSocialIos: autoLockSocialIos ?? this.autoLockSocialIos,
      streakTracking: streakTracking ?? this.streakTracking,
      autoUnlockMinutes: autoUnlockMinutes ?? this.autoUnlockMinutes,
    );
  }
}
