part of 'salah_lock_cubit.dart';

sealed class SalahLockState {
  final SalahLockSettings settings;
  SalahLockState(this.settings);
}

class SalahLockLoading extends SalahLockState {
  SalahLockLoading(super.settings);
}

class SalahLockIdle extends SalahLockState {
  SalahLockIdle(super.settings);
}

class SalahLockActive extends SalahLockState {
  final String salahName;
  final Map<String, String> verse;

  SalahLockActive({required this.salahName, required this.verse, required SalahLockSettings settings})
    : super(settings);
}

class SalahLockUnlocked extends SalahLockState {
  SalahLockUnlocked(super.settings);
}
