import '../../domain/entities/challenge_entity.dart';

class ChallengeModel extends ChallengeEntity {
  ChallengeModel({
    required super.durationDays,
    required super.rewardPoints,
    required super.startDate,
    required super.completedDays,
    required super.status,
    super.challengeType,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'durationDays': durationDays,
      'rewardPoints': rewardPoints,
      'startDate': startDate.toIso8601String(),
      'completedDays': completedDays,
      'status': status.name,
      'challengeType': challengeType,
    };
  }

  /// Create from JSON
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      durationDays: json['durationDays'] as int,
      rewardPoints: json['rewardPoints'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      completedDays: json['completedDays'] as int,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.notStarted,
      ),
      challengeType: json['challengeType'] as String?,
    );
  }

  /// Create a copy with updated fields
  ChallengeModel copyWith({
    int? durationDays,
    int? rewardPoints,
    DateTime? startDate,
    int? completedDays,
    ChallengeStatus? status,
    String? challengeType,
  }) {
    return ChallengeModel(
      durationDays: durationDays ?? this.durationDays,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      status: status ?? this.status,
      challengeType: challengeType ?? this.challengeType,
    );
  }

  /// Convert to string for debugging
  @override
  String toString() {
    return 'ChallengeModel(durationDays: $durationDays, completedDays: $completedDays, status: ${status.name})';
  }
}
