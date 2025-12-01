class ZakatEntity {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String recipient;
  final int pointsEarned;
  final String? notes;

  ZakatEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.recipient,
    this.pointsEarned = 100,
    this.notes,
  });
}
