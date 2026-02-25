part of 'salah_lock_cubit.dart';

sealed class SalahLockState {}

class SalahLockIdle extends SalahLockState {}

class SalahLockActive extends SalahLockState {
  final String salahName;
  final Map<String, String> verse;

  SalahLockActive({required this.salahName, required this.verse});
}

class SalahLockUnlocked extends SalahLockState {}
