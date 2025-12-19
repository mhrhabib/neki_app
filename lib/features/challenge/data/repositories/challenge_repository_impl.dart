import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../models/challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'challenges';

  ChallengeRepositoryImpl(this._firestoreService);

  @override
  Future<ChallengeEntity?> getActiveChallenge(String userId) async {
    try {
      final doc = await _firestoreService.getDocument(collectionPath: _collectionPath, documentId: userId);

      if (doc != null && doc.exists) {
        final challenge = ChallengeModel.fromJson(doc.data()!);
        debugPrint('📊 [Challenge] Loaded from Firestore: ${challenge.toString()}');
        return challenge;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading challenge: $e');
      return null;
    }
  }

  @override
  Future<void> saveChallenge(String userId, ChallengeEntity challenge) async {
    try {
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

      await _firestoreService.setDocument(collectionPath: _collectionPath, documentId: userId, data: model.toJson());

      debugPrint('✅ [Challenge] Saved to Firestore: ${model.toString()}');
    } catch (e) {
      debugPrint('❌ [Challenge] Error saving challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearChallenge(String userId) async {
    try {
      await _firestoreService.deleteDocument(collectionPath: _collectionPath, documentId: userId);
      debugPrint('🗑️ [Challenge] Cleared from Firestore');
    } catch (e) {
      debugPrint('❌ [Challenge] Error clearing challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeTodayChallenge(String userId) async {
    try {
      final challenge = await getActiveChallenge(userId);
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
      final newStatus = newCompletedDays >= model.durationDays ? ChallengeStatus.completed : ChallengeStatus.active;

      final updatedChallenge = model.copyWith(completedDays: newCompletedDays, status: newStatus);

      await saveChallenge(userId, updatedChallenge);
      debugPrint('✅ [Challenge] Day $newCompletedDays completed!');
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing today: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasActiveChallenge(String userId) async {
    final challenge = await getActiveChallenge(userId);
    return challenge != null && challenge.status == ChallengeStatus.active;
  }
}
