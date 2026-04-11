class NekiPointsEntity {
  final String userId;
  final int totalPoints;
  final int todayPoints;
  final int weekPoints;
  final int monthPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final String? name;
  final String? photoUrl;
  final bool showOnLeaderboard;

  NekiPointsEntity({
    required this.userId,
    required this.totalPoints,
    required this.todayPoints,
    required this.weekPoints,
    required this.monthPoints,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
    this.name,
    this.photoUrl,
    this.showOnLeaderboard = true,
  });
}
