import '../../domain/entities/challenge_entity.dart';

class ChallengeModel extends ChallengeEntity {
  ChallengeModel({
    required super.durationDays,
    required super.rewardPoints,
    required super.startDate,
    required super.completedDays,
    required super.status,
    super.challengeType,
    super.userId,
    super.completedAt,
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
      'userId': userId,
      'completedAt': completedAt?.toIso8601String(),
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
      userId: json['userId'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
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
    String? userId,
    DateTime? completedAt,
  }) {
    return ChallengeModel(
      durationDays: durationDays ?? this.durationDays,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      status: status ?? this.status,
      challengeType: challengeType ?? this.challengeType,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Normalised key used as the Firestore document-ID suffix and the
  /// in-memory map key.
  /// - beat_satan → 'beat_satan'
  /// - addiction_porn_7 → 'addiction_porn' (legacy, drops duration suffix)
  /// - addiction_porn → 'addiction_porn'  (new model, no duration)
  ///
  /// Each addiction type is its own key so users can quit smoking AND porn
  /// in parallel without one overwriting the other.
  static String typeKey(String? challengeType) {
    if (challengeType == null) return 'default';
    if (challengeType.startsWith('addiction_')) {
      // Strip any trailing duration suffix from legacy types
      // ("addiction_porn_7" → "addiction_porn").
      final parts = challengeType.split('_');
      if (parts.length >= 2) return 'addiction_${parts[1]}';
      return challengeType;
    }
    return challengeType;
  }

  /// All known addiction sub-types — used by the repository to enumerate
  /// which Firestore docs to look up.
  static const List<String> kAddictionTypes = [
    'addiction_porn',
    'addiction_smoking',
    'addiction_alcohol',
    'addiction_gambling',
  ];

  @override
  String toString() {
    return 'ChallengeModel(type: $challengeType, durationDays: $durationDays, completedDays: $completedDays, status: ${status.name})';
  }
}
