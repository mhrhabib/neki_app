part of 'points_cubit.dart';

abstract class PointsState {}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsLoaded extends PointsState {
  final NekiPointsEntity points;
  PointsLoaded({required this.points});
}

class PointsError extends PointsState {
  final String message;
  PointsError({required this.message});
}
