class DhikirEntity {
  final String id;
  final String userId;
  final String dhikirText;
  final int targetCount;
  final int currentCount;
  final int pointsEarned;
  final DateTime date;
  final bool isCompleted;

  DhikirEntity({
    required this.id,
    required this.userId,
    required this.dhikirText,
    required this.targetCount,
    required this.currentCount,
    required this.pointsEarned,
    required this.date,
    required this.isCompleted,
  });

  int get pointsPerDhikir => 5; // 5 points per dhikir completion
  int get totalPossiblePoints => targetCount * pointsPerDhikir;
}