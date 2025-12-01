import '../../domain/entities/neki_points_entity.dart';

class NekiPointsModel extends NekiPointsEntity {
  NekiPointsModel({
    required super.userId,
    required super.totalPoints,
    required super.todayPoints,
    required super.weekPoints,
    required super.monthPoints,
    required super.currentStreak,
    required super.longestStreak,
  });

  factory NekiPointsModel.fromJson(Map<String, dynamic> json) {
    return NekiPointsModel(
      userId: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      todayPoints: json['todayPoints'] ?? 0,
      weekPoints: json['weekPoints'] ?? 0,
      monthPoints: json['monthPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'todayPoints': todayPoints,
      'weekPoints': weekPoints,
      'monthPoints': monthPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}
