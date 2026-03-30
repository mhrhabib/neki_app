part of 'leaderboard_cubit.dart';

abstract class LeaderboardState {}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntryEntity> globalEntries;
  final LeaderboardEntryEntity? currentUserRank;
  final String currentUserId;

  LeaderboardLoaded({
    required this.globalEntries,
    required this.currentUserId,
    this.currentUserRank,
  });
}

class LeaderboardError extends LeaderboardState {
  final String message;
  LeaderboardError(this.message);
}
