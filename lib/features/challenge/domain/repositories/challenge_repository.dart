import '../entities/challenge_entity.dart';

abstract class ChallengeRepository {
  /// Get the current active challenge
  Future<ChallengeEntity?> getActiveChallenge();

  /// Save or update a challenge
  Future<void> saveChallenge(ChallengeEntity challenge);

  /// Clear the current challenge
  Future<void> clearChallenge();

  /// Mark today as completed
  Future<void> completeTodayChallenge();

  /// Check if user has an active challenge
  Future<bool> hasActiveChallenge();
}
