class SalahEntity {
  final String id;
  final String userId;
  final String salahName; // Fajr, Dhuhr, Asr, Maghrib, Isha
  final DateTime timestamp;
  final bool isCompleted;
  final int pointsEarned;

  SalahEntity({
    required this.id,
    required this.userId,
    required this.salahName,
    required this.timestamp,
    required this.isCompleted,
    this.pointsEarned = 10,
  });
}
