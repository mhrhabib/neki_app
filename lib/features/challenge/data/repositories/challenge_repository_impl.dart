import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../models/challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final SharedPreferences _prefs;
  static const String _activeChalllengeKey = 'active_challenge';

  ChallengeRepositoryImpl(this._prefs);

  @override
  Future<ChallengeEntity?> getActiveChallenge() async {
    try {
      final data = _prefs.getString(_activeChalllengeKey);
      if (data == null) return null;

      final json = jsonDecode(data) as Map<String, dynamic>;
      final challenge = ChallengeModel.fromJson(json);

      debugPrint('📊 [Challenge] Loaded: ${challenge.toString()}');
      return challenge;
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading challenge: $e');
      return null;
    }
  }

  @override
  Future<void> saveChallenge(ChallengeEntity challenge) async {
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

      final data = jsonEncode(model.toJson());
      await _prefs.setString(_activeChalllengeKey, data);

      debugPrint('✅ [Challenge] Saved: ${model.toString()}');
    } catch (e) {
      debugPrint('❌ [Challenge] Error saving challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearChallenge() async {
    try {
      await _prefs.remove(_activeChalllengeKey);
      debugPrint('🗑️ [Challenge] Cleared');
    } catch (e) {
      debugPrint('❌ [Challenge] Error clearing challenge: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeTodayChallenge() async {
    try {
      final challenge = await getActiveChallenge();
      if (challenge == null) {
        throw Exception('No active challenge found');
      }

      if (!challenge.canCompleteToday()) {
        throw Exception('Challenge already completed today');
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

      await saveChallenge(updatedChallenge);
      debugPrint('✅ [Challenge] Day $newCompletedDays completed!');
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing today: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasActiveChallenge() async {
    final challenge = await getActiveChallenge();
    return challenge != null && challenge.status == ChallengeStatus.active;
  }
}
