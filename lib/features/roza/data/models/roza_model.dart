import '../../domain/entities/roza_entity.dart';

class RozaModel extends RozaEntity {
  RozaModel({
    required super.id,
    required super.userId,
    required super.date,
    required super.isFasted,
    super.pointsEarned = 100, // Updated to 100 points as requested
    super.notes,
  });

  factory RozaModel.fromJson(Map<String, dynamic> json) {
    return RozaModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      isFasted: json['isFasted'] as bool,
      pointsEarned: json['pointsEarned'] as int? ?? 100,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'isFasted': isFasted,
      'pointsEarned': pointsEarned,
      'notes': notes,
    };
  }

  factory RozaModel.fromEntity(RozaEntity entity) {
    return RozaModel(
      id: entity.id,
      userId: entity.userId,
      date: entity.date,
      isFasted: entity.isFasted,
      pointsEarned: entity.pointsEarned,
      notes: entity.notes,
    );
  }
}
