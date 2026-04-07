import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../models/challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'challenges';

  ChallengeRepositoryImpl(this._firestoreService);

  /// Builds the Firestore document ID: `{userId}_{typeKey}`.
  /// Legacy docs (no type) use just `{userId}` for backwards compat.
  String _docId(String userId, String? typeKey) {
    if (typeKey == null || typeKey == 'default') return userId;
    return '${userId}_$typeKey';
  }

  @override
  Future<ChallengeEntity?> getActiveChallenge(String userId, {String? typeKey}) async {
    try {
      final docId = _docId(userId, typeKey);
      final doc = await _firestoreService.getDocument(
        collectionPath: _collectionPath,
        documentId: docId,
      );

      if (doc != null && doc.exists) {
        final challenge = ChallengeModel.fromJson(doc.data()!);
        debugPrint('📊 [Challenge] Loaded ($docId): $challenge');
        return challenge;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading challenge: $e');
      return null;
    }
  }

  @override
  Future<List<ChallengeEntity>> getAllActiveChallenges(String userId) async {
    try {
      // Check known type keys
      final typeKeys = ['beat_satan', 'addiction'];
      final challenges = <ChallengeEntity>[];

      for (final key in typeKeys) {
        final challenge = await getActiveChallenge(userId, typeKey: key);
        if (challenge != null && challenge.isActive) {
          challenges.add(challenge);
        }
      }

      // Also check legacy doc (just userId, no suffix)
      final legacy = await getActiveChallenge(userId);
      if (legacy != null && legacy.isActive) {
        // Only add if not a duplicate of a typed challenge
        final legacyKey = ChallengeModel.typeKey(legacy.challengeType);
        if (!challenges.any((c) => ChallengeModel.typeKey(c.challengeType) == legacyKey)) {
          challenges.add(legacy);
        }
      }

      debugPrint('📊 [Challenge] Loaded ${challenges.length} active challenges for $userId');
      return challenges;
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading all challenges: $e');
      return [];
    }
  }

  @override
  Future<void> saveChallenge(String userId, ChallengeEntity challenge) async {
    try {
      final typeKey = ChallengeModel.typeKey(challenge.challengeType);
      final docId = _docId(userId, typeKey);

      final model = challenge is ChallengeModel
          ? challenge
          : ChallengeModel(
              durationDays: challenge.durationDays,
              rewardPoints: challenge.rewardPoints,
              startDate: challenge.startDate,
              completedDays: challenge.completedDays,
              status: challenge.status,
              challengeType: challenge.challengeType,
            );

      await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: docId,
        data: model.toJson(),
      );

      debugPrint('✅ [Challenge] Saved ($docId): $model');
    } catch (e) {
      debugPrint('❌ [Challenge] Error saving challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearChallenge(String userId, {String? typeKey}) async {
    try {
      final docId = _docId(userId, typeKey);
      await _firestoreService.deleteDocument(
        collectionPath: _collectionPath,
        documentId: docId,
      );
      debugPrint('🗑️ [Challenge] Cleared ($docId)');
    } catch (e) {
      debugPrint('❌ [Challenge] Error clearing challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeTodayChallenge(String userId, {String? typeKey}) async {
    try {
      final challenge = await getActiveChallenge(userId, typeKey: typeKey);
      if (challenge == null) {
        throw Exception('No active challenge found');
      }

      if (!challenge.canCompleteToday()) {
        debugPrint('ℹ️ [Challenge] Already completed for today, skipping update.');
        return;
      }

      final model = challenge is ChallengeModel
          ? challenge
          : ChallengeModel(
              durationDays: challenge.durationDays,
              rewardPoints: challenge.rewardPoints,
              startDate: challenge.startDate,
              completedDays: challenge.completedDays,
              status: challenge.status,
              challengeType: challenge.challengeType,
            );

      final newCompletedDays = model.completedDays + 1;
      final newStatus = newCompletedDays >= model.durationDays
          ? ChallengeStatus.completed
          : ChallengeStatus.active;

      final updatedChallenge = model.copyWith(
        completedDays: newCompletedDays,
        status: newStatus,
      );

      await saveChallenge(userId, updatedChallenge);
      debugPrint('✅ [Challenge] Day $newCompletedDays completed!');
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing today: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasActiveChallenge(String userId, {String? typeKey}) async {
    final challenge = await getActiveChallenge(userId, typeKey: typeKey);
    return challenge != null && challenge.status == ChallengeStatus.active;
  }
}
