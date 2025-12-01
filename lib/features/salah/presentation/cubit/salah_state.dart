part of 'salah_cubit.dart';

abstract class SalahState {}

class SalahInitial extends SalahState {}

class SalahLoading extends SalahState {}

class SalahLoaded extends SalahState {
  final List<SalahEntity> salahs;
  SalahLoaded({required this.salahs});
}

class SalahError extends SalahState {
  final String message;
  SalahError({required this.message});
}
