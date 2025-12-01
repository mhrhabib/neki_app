class RozaEntity {
  final String id;
  final String userId;
  final DateTime date;
  final bool isFasted;
  final int pointsEarned;
  final String? notes;

  RozaEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.isFasted,
    this.pointsEarned = 50,
    this.notes,
  });
}
