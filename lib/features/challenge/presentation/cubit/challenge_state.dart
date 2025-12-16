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
  final ChallengeEntity? challenge;

  const ChallengeLoaded(this.challenge);

  bool get hasActiveChallenge => challenge != null && challenge!.isActive;
  bool get isChallengeCompleted => challenge != null && challenge!.isCompleted;
}

class ChallengeError extends ChallengeState {
  final String message;

  const ChallengeError(this.message);
}

class ChallengeDayCompleted extends ChallengeState {
  final ChallengeEntity challenge;
  final int pointsEarned;

  const ChallengeDayCompleted(this.challenge, this.pointsEarned);
}

class ChallengeFullyCompleted extends ChallengeState {
  final ChallengeEntity challenge;
  final int totalPointsEarned;

  const ChallengeFullyCompleted(this.challenge, this.totalPointsEarned);
}
