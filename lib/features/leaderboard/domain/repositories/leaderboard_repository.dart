import '../entities/leaderboard_entry_entity.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard({int page = 1, int limit = 50});
  Future<List<LeaderboardEntryEntity>> getCountryLeaderboard({required String country, int page = 1, int limit = 50});
  Future<LeaderboardEntryEntity?> getUserRank(String userId);
}
