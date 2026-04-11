import '../entities/challenge_entity.dart';

abstract class ChallengeRepository {
  /// Get a specific active challenge by type key ('beat_satan', 'addiction', etc.)
  Future<ChallengeEntity?> getActiveChallenge(String userId, {String? typeKey});

  /// Get ALL active challenges for this user.
  Future<List<ChallengeEntity>> getAllActiveChallenges(String userId);

  /// Save or update a challenge
  Future<void> saveChallenge(String userId, ChallengeEntity challenge);

  /// Clear a specific challenge by type key
  Future<void> clearChallenge(String userId, {String? typeKey});

  /// Mark today as completed for a specific challenge
  Future<void> completeTodayChallenge(String userId, {String? typeKey});

  /// Check if user has an active challenge of a given type
  Future<bool> hasActiveChallenge(String userId, {String? typeKey});
}
