class GoodDeedEntity {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime timestamp;
  final int pointsEarned;
  final String category; // helping, charity, kindness, etc

  GoodDeedEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.timestamp,
    this.pointsEarned = 20,
    this.category = 'general',
  });
}
