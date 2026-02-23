part of 'roza_cubit.dart';

abstract class RozaState {}

class RozaInitial extends RozaState {}

class RozaLoading extends RozaState {}

class RozaLoaded extends RozaState {
  final List<DateTime> selectedDates;
  final List<DateTime> brokenFastDates;
  final int currentMonthFastCount;

  RozaLoaded({required this.selectedDates, required this.brokenFastDates, required this.currentMonthFastCount});
}

class RozaError extends RozaState {
  final String message;
  RozaError({required this.message});
}
