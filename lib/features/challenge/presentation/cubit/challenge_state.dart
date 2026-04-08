part of 'challenge_cubit.dart';

abstract class ChallengeState {
  const ChallengeState();
}

class ChallengeInitial extends ChallengeState {
  const ChallengeInitial();
}

class ChallengeLoading extends ChallengeState {
  const ChallengeLoading();
}

class ChallengeLoaded extends ChallengeState {
  /// All active challenges keyed by their type key ('beat_satan', 'addiction').
  final Map<String, ChallengeEntity> challenges;

  const ChallengeLoaded(this.challenges);

  /// Backwards-compat: check if any challenge is active.
  bool get hasActiveChallenge => challenges.values.any((c) => c.isActive);

  /// Check if there are any challenges at all (active or expired/completed/etc).
  bool get hasAnyChallenge => challenges.isNotEmpty;

  /// Get a specific challenge by type key.
  ChallengeEntity? operator [](String typeKey) => challenges[typeKey];

  bool hasType(String typeKey) =>
      challenges[typeKey] != null && challenges[typeKey]!.isActive;
}

class ChallengeError extends ChallengeState {
  final String message;

  const ChallengeError(this.message);
}

class ChallengeDayCompleted extends ChallengeState {
  final ChallengeEntity challenge;
  final int pointsEarned;
  /// Keep the full map so we can restore it.
  final Map<String, ChallengeEntity> allChallenges;

  const ChallengeDayCompleted(this.challenge, this.pointsEarned, this.allChallenges);
}

class ChallengeFullyCompleted extends ChallengeState {
  final ChallengeEntity challenge;
  final int totalPointsEarned;
  final Map<String, ChallengeEntity> allChallenges;

  const ChallengeFullyCompleted(this.challenge, this.totalPointsEarned, this.allChallenges);
}
