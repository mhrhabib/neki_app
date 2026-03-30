class LeaderboardEntryEntity {
  final int rank;
  final String userId;
  final String userName;
  final String? photoUrl;
  final int totalPoints;
  final String? country;

  LeaderboardEntryEntity({
    required this.rank,
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.totalPoints,
    this.country,
  });
}
