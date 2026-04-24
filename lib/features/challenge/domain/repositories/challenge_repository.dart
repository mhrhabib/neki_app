import '../entities/challenge_entity.dart';

abstract class ChallengeRepository {
  /// Get a specific active challenge by type key ('beat_satan',
  /// 'addiction_porn', 'addiction_smoking', etc.)
  Future<ChallengeEntity?> getActiveChallenge(String userId, {String? typeKey, bool allowFallback = true});

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

  /// Archive a finished addiction streak (called on relapse) so the user can
  /// see their longest streak and past attempts.
  Future<void> archiveAddictionAttempt(
    String userId,
    ChallengeEntity attempt,
  );

  /// Past attempts for a given addiction type, newest first.
  Future<List<ChallengeEntity>> getPastAttempts(
    String userId, {
    required String typeKey,
  });
}
