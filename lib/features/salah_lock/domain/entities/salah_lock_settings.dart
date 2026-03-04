class SalahLockSettings {
  final bool isEnabled;
  final bool lockDeviceAndroid;
  final bool autoLockSocialIos;
  final bool streakTracking;
  final List<String> blockedApps;
  final bool lockAllApps;
  final int autoUnlockMinutes;

  SalahLockSettings({
    this.isEnabled = true,
    this.lockDeviceAndroid = false,
    this.autoLockSocialIos = false,
    this.streakTracking = true,
    this.blockedApps = const [],
    this.lockAllApps = false,
    this.autoUnlockMinutes = 120,
  });

  SalahLockSettings copyWith({
    bool? isEnabled,
    bool? lockDeviceAndroid,
    bool? autoLockSocialIos,
    bool? streakTracking,
    List<String>? blockedApps,
    bool? lockAllApps,
    int? autoUnlockMinutes,
  }) {
    return SalahLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      lockDeviceAndroid: lockDeviceAndroid ?? this.lockDeviceAndroid,
      autoLockSocialIos: autoLockSocialIos ?? this.autoLockSocialIos,
      streakTracking: streakTracking ?? this.streakTracking,
      blockedApps: blockedApps ?? this.blockedApps,
      lockAllApps: lockAllApps ?? this.lockAllApps,
      autoUnlockMinutes: autoUnlockMinutes ?? this.autoUnlockMinutes,
    );
  }
}
