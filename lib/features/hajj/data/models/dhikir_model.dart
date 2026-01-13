import '../../domain/entities/dhikir_entity.dart';

class DhikirModel extends DhikirEntity {
  DhikirModel({
    required super.id,
    required super.userId,
    required super.dhikirText,
    required super.targetCount,
    required super.currentCount,
    required super.pointsEarned,
    required super.date,
    required super.isCompleted,
  });

  factory DhikirModel.fromJson(Map<String, dynamic> json) {
    return DhikirModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dhikirText: json['dhikirText'] as String,
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int,
      pointsEarned: json['pointsEarned'] as int,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dhikirText': dhikirText,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'pointsEarned': pointsEarned,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory DhikirModel.fromEntity(DhikirEntity entity) {
    return DhikirModel(
      id: entity.id,
      userId: entity.userId,
      dhikirText: entity.dhikirText,
      targetCount: entity.targetCount,
      currentCount: entity.currentCount,
      pointsEarned: entity.pointsEarned,
      date: entity.date,
      isCompleted: entity.isCompleted,
    );
  }

  DhikirModel copyWith({
    String? id,
    String? userId,
    String? dhikirText,
    int? targetCount,
    int? currentCount,
    int? pointsEarned,
    DateTime? date,
    bool? isCompleted,
  }) {
    return DhikirModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dhikirText: dhikirText ?? this.dhikirText,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}