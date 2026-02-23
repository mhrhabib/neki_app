import '../entities/challenge_entity.dart';

abstract class ChallengeRepository {
  /// Get the current active challenge
  Future<ChallengeEntity?> getActiveChallenge(String userId);

  /// Save or update a challenge
  Future<void> saveChallenge(String userId, ChallengeEntity challenge);

  /// Clear the current challenge
  Future<void> clearChallenge(String userId);

  /// Mark today as completed
  Future<void> completeTodayChallenge(String userId);

  /// Check if user has an active challenge
  Future<bool> hasActiveChallenge(String userId);
}
