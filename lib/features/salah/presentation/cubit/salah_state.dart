part of 'salah_cubit.dart';

abstract class SalahState {}

class SalahInitial extends SalahState {}

class SalahLoading extends SalahState {}

class SalahLoaded extends SalahState {
  final List<SalahEntity> salahs;
  final List<SalahEntity>? history;
  SalahLoaded({required this.salahs, this.history});
}

class SalahError extends SalahState {
  final String message;
  SalahError({required this.message});
}
