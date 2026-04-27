part of 'dhikir_cubit.dart';

abstract class DhikirState {}

class DhikirInitial extends DhikirState {}

class DhikirLoading extends DhikirState {}

class DhikirSessionActive extends DhikirState {
  final String sessionId;
  final String dhikirText;
  final int targetCount;
  final int currentCount;
  final int pointsEarned;
  final bool isCompleted;

  DhikirSessionActive({
    required this.sessionId,
    required this.dhikirText,
    required this.targetCount,
    required this.currentCount,
    required this.pointsEarned,
    required this.isCompleted,
  });
}

class DhikirSessionCompleted extends DhikirState {
  final String sessionId;
  final String dhikirText;
  final int targetCount;
  final int currentCount;
  final int pointsEarned;
  final bool isCompleted;

  DhikirSessionCompleted({
    required this.sessionId,
    required this.dhikirText,
    required this.targetCount,
    required this.currentCount,
    required this.pointsEarned,
    this.isCompleted = true,
  });
}

class DhikirHistoryLoaded extends DhikirState {
  final List<Map<String, dynamic>> sessions;
  DhikirHistoryLoaded({required this.sessions});
}

class DhikirInsightsLoaded extends DhikirState {
  final Map<String, int> dailyCounts;
  DhikirInsightsLoaded({required this.dailyCounts});
}

class DhikirError extends DhikirState {
  final String message;
  DhikirError({required this.message});
}