class BadgeEntity {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int requiredPoints;
  final bool isEarned;
  final DateTime? earnedAt;

  BadgeEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.requiredPoints,
    required this.isEarned,
    this.earnedAt,
  });
}
