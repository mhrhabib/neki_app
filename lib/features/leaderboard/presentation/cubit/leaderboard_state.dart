part of 'leaderboard_cubit.dart';

abstract class LeaderboardState {}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntryEntity> globalEntries;
  final List<LeaderboardEntryEntity> countryEntries;
  final LeaderboardEntryEntity? currentUserRank;
  final String currentUserId;
  final String? userCountry; // 2-letter ISO code e.g. 'BD', 'US'

  LeaderboardLoaded({
    required this.globalEntries,
    required this.countryEntries,
    required this.currentUserId,
    this.currentUserRank,
    this.userCountry,
  });
}

class LeaderboardError extends LeaderboardState {
  final String message;
  LeaderboardError(this.message);
}
