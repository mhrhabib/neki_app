import '../entities/challenge_entity.dart';

/// Thrown by [ChallengeRepository.completeTodayChallenge] when the persisted
/// challenge already records today's check-in. Signals the caller to skip
/// awarding points and avoid emitting a success state.
class ChallengeAlreadyCompletedToday implements Exception {
  final ChallengeEntity current;
  ChallengeAlreadyCompletedToday(this.current);
}

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

  /// Mark today as completed for a specific challenge.
  /// Returns the saved [ChallengeEntity] after the increment.
  /// Throws [ChallengeAlreadyCompletedToday] if the active doc already
  /// has today's check-in (e.g., the cubit's in-memory state was stale).
  Future<ChallengeEntity> completeTodayChallenge(
    String userId, {
    String? typeKey,
  });

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

  /// Archive a fully-completed challenge once the 24h celebration window has
  /// elapsed. Writes a permanent record to `completed_challenges` and removes
  /// the active challenge doc, so the home screen frees up and the trophy
  /// shows up as a profile badge instead.
  Future<void> archiveCompletedChallenge(
    String userId,
    ChallengeEntity challenge,
  );

  /// All challenges this user has fully completed, newest first.
  Future<List<ChallengeEntity>> getCompletedChallenges(String userId);
}
