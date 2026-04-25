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
  Future<ChallengeEntity?> getActiveChallenge(String userId, {String? typeKey, bool allowFallback = true}) async {
    try {
      final docId = _docId(userId, typeKey);
      final doc = await _firestoreService.getDocument(
        collectionPath: _collectionPath,
        documentId: docId,
      );

      if (doc != null && doc.exists) {
        final challenge = ChallengeModel.fromJson(doc.data()!);
        return challenge;
      }

      // Fallback: If typeKey was normalized (e.g. 'addiction_porn') but the 
      // doc was saved with an un-normalized ID (e.g. 'userId_addiction_porn_7'),
      // we try to find it by scanning all active challenges.
      // We check allowFallback to prevent infinite recursion when called from getAllActiveChallenges.
      if (typeKey != null && allowFallback) {
        final all = await getAllActiveChallenges(userId);
        for (final c in all) {
          if (ChallengeModel.typeKey(c.challengeType) == typeKey) {
            return c;
          }
        }
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
      final typeKeys = <String>[
        'beat_satan',
        ...ChallengeModel.kAddictionTypes,
        'addiction',
      ];
      final challenges = <ChallengeEntity>[];

      for (final key in typeKeys) {
        // Disable fallback here to avoid recursion. We are just probing.
        final challenge = await getActiveChallenge(userId, typeKey: key, allowFallback: false);
        if (challenge != null) {
          challenges.add(challenge);
        }
      }

      // Also check legacy doc (just userId, no suffix)
      final legacy = await getActiveChallenge(userId, allowFallback: false);
      if (legacy != null) {
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
              userId: userId,
              completedAt: challenge.completedAt,
            );

      // FirestoreService.setDocument swallows errors and returns false. Treat
      // that as a hard failure here — silently dropping a check-in write was
      // the root cause of the "incremented in UI, reverts on reload" bug.
      final ok = await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: docId,
        data: model.toJson(),
      );
      if (!ok) {
        throw Exception('Firestore setDocument returned false for $docId');
      }

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
  Future<ChallengeEntity> completeTodayChallenge(
    String userId, {
    String? typeKey,
  }) async {
    final challenge = await getActiveChallenge(userId, typeKey: typeKey);
    if (challenge == null) {
      throw Exception('No active challenge found');
    }

    // Source of truth: the freshly-fetched Firestore state. If it already
    // shows today's check-in (memory was stale), throw a typed signal so
    // the caller can avoid awarding duplicate points.
    if (!challenge.canCompleteToday()) {
      debugPrint(
        'ℹ️ [Challenge] Firestore already has today\'s check-in — signalling skip',
      );
      throw ChallengeAlreadyCompletedToday(challenge);
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
            userId: userId,
            completedAt: challenge.completedAt,
          );

    final isAddiction = model.challengeType?.startsWith('addiction') ?? false;
    final newCompletedDays = model.completedDays + 1;
    final justCompleted =
        newCompletedDays >= model.durationDays && !isAddiction;
    final newStatus = justCompleted
        ? ChallengeStatus.completed
        : ChallengeStatus.active;

    final updatedChallenge = model.copyWith(
      completedDays: newCompletedDays,
      status: newStatus,
      completedAt: justCompleted ? DateTime.now() : model.completedAt,
    );

    await saveChallenge(userId, updatedChallenge);
    debugPrint(
      '✅ [ChallengeRepo] Day $newCompletedDays committed (status: ${newStatus.name})',
    );
    return updatedChallenge;
  }

  @override
  Future<bool> hasActiveChallenge(String userId, {String? typeKey}) async {
    final challenge = await getActiveChallenge(userId, typeKey: typeKey);
    return challenge != null && challenge.status == ChallengeStatus.active;
  }

  // ────────────────────────── Past attempts ─────────────────────────
  //
  // Stored as a FLAT top-level collection so the existing security rule
  //   match /{collection}/{docId}: allow if docId starts with uid OR
  //                                resource.data.userId == uid
  // applies. Sub-collections aren't reachable under that rule, so a
  // nested layout (e.g. addiction_history/{x}/attempts/{y}) would be
  // permission-denied for end users.
  //
  // Layout:
  //   collection: addiction_history
  //   docId:      {uid}_{typeKey}_{startMs}
  //   fields:     userId, typeKey, startDate, endedAt, daysClean, ...

  String _historyDocId(String userId, String typeKey, DateTime startDate) =>
      '${userId}_${typeKey}_${startDate.millisecondsSinceEpoch}';

  @override
  Future<void> archiveAddictionAttempt(
    String userId,
    ChallengeEntity attempt,
  ) async {
    final typeKey = ChallengeModel.typeKey(attempt.challengeType);
    if (!typeKey.startsWith('addiction')) return; // only archive addictions
    try {
      final model = attempt is ChallengeModel
          ? attempt
          : ChallengeModel(
              durationDays: attempt.durationDays,
              rewardPoints: attempt.rewardPoints,
              startDate: attempt.startDate,
              completedDays: attempt.completedDays,
              status: ChallengeStatus.failed,
              challengeType: attempt.challengeType,
              userId: userId,
            );
      final endedAt = DateTime.now();
      final daysClean = endedAt.difference(model.startDate).inDays;
      await _firestoreService.setDocument(
        collectionPath: 'addiction_history',
        documentId: _historyDocId(userId, typeKey, model.startDate),
        data: {
          ...model.toJson(),
          'userId': userId, // required for security rule + query
          'typeKey': typeKey, // required for query
          'endedAt': endedAt.toIso8601String(),
          'daysClean': daysClean,
        },
      );
      debugPrint('🗂️ [Challenge] Archived attempt ($typeKey, $daysClean days clean)');
    } catch (e) {
      // Non-fatal: archival failure shouldn't block the relapse flow.
      debugPrint('⚠️ [Challenge] Archive failed: $e');
    }
  }

  @override
  Future<List<ChallengeEntity>> getPastAttempts(
    String userId, {
    required String typeKey,
  }) async {
    try {
      final snap = await _firestoreService.getCollection(
        collectionPath: 'addiction_history',
        queryBuilder: (q) => q
            .where('userId', isEqualTo: userId)
            .where('typeKey', isEqualTo: typeKey)
            .orderBy('startDate', descending: true),
      );
      return snap.docs.map((d) => ChallengeModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading past attempts: $e');
      return [];
    }
  }

  // ─────────────────────── Completed-challenge trophies ───────────────────────
  //
  // Layout mirrors `addiction_history` so the same security rule applies
  // (top-level collection, docId starts with userId).
  //
  //   collection: completed_challenges
  //   docId:      {uid}_{typeKey}_{startMs}
  //   fields:     userId, typeKey, startDate, completedAt, durationDays, …

  String _completedDocId(String userId, String typeKey, DateTime startDate) =>
      '${userId}_${typeKey}_${startDate.millisecondsSinceEpoch}';

  @override
  Future<void> archiveCompletedChallenge(
    String userId,
    ChallengeEntity challenge,
  ) async {
    final typeKey = ChallengeModel.typeKey(challenge.challengeType);
    try {
      final model = challenge is ChallengeModel
          ? challenge
          : ChallengeModel(
              durationDays: challenge.durationDays,
              rewardPoints: challenge.rewardPoints,
              startDate: challenge.startDate,
              completedDays: challenge.completedDays,
              status: ChallengeStatus.completed,
              challengeType: challenge.challengeType,
              userId: userId,
              completedAt: challenge.completedAt,
            );

      await _firestoreService.setDocument(
        collectionPath: 'completed_challenges',
        documentId: _completedDocId(userId, typeKey, model.startDate),
        data: {
          ...model.toJson(),
          'userId': userId,
          'typeKey': typeKey,
        },
      );

      // Remove the active challenge doc so home stops rendering it.
      await clearChallenge(userId, typeKey: typeKey);

      debugPrint(
        '🏆 [Challenge] Archived completed $typeKey (${model.durationDays}d)',
      );
    } catch (e) {
      // Non-fatal: a failed archive shouldn't block normal flow. The
      // challenge doc stays in place and we'll retry on next load.
      debugPrint('⚠️ [Challenge] Archive completed failed: $e');
    }
  }

  @override
  Future<List<ChallengeEntity>> getCompletedChallenges(String userId) async {
    try {
      final snap = await _firestoreService.getCollection(
        collectionPath: 'completed_challenges',
        queryBuilder: (q) => q
            .where('userId', isEqualTo: userId)
            .orderBy('completedAt', descending: true),
      );
      return snap.docs.map((d) => ChallengeModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading completed challenges: $e');
      return [];
    }
  }
}
