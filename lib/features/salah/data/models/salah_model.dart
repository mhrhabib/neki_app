import '../../domain/entities/salah_entity.dart';

class SalahModel extends SalahEntity {
  SalahModel({
    required super.id,
    required super.userId,
    required super.salahName,
    required super.timestamp,
    required super.isCompleted,
    super.pointsEarned,
  });

  factory SalahModel.fromJson(Map<String, dynamic> json) {
    return SalahModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      salahName: json['salahName'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      pointsEarned: json['pointsEarned'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'salahName': salahName,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
      'pointsEarned': pointsEarned,
    };
  }
}
