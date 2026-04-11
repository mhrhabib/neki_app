part of 'salah_lock_cubit.dart';

sealed class SalahLockState {
  final SalahLockSettings settings;
  final bool isGuideDismissed;
  SalahLockState(this.settings, {this.isGuideDismissed = false});

  bool get showSetupGuide => !isGuideDismissed && !settings.isEnabled;
}

class SalahLockLoading extends SalahLockState {
  SalahLockLoading(super.settings, {super.isGuideDismissed});
}

class SalahLockIdle extends SalahLockState {
  SalahLockIdle(super.settings, {super.isGuideDismissed});
}

class SalahLockActive extends SalahLockState {
  final String salahName;
  final Map<String, String> verse;

  SalahLockActive({
    required this.salahName,
    required this.verse,
    required SalahLockSettings settings,
    bool isGuideDismissed = false,
  }) : super(settings, isGuideDismissed: isGuideDismissed);
}

class SalahLockUnlocked extends SalahLockState {
  SalahLockUnlocked(super.settings, {super.isGuideDismissed});
}
