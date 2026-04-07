import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/challenge_model.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'challenge_state.dart';

class ChallengeCubit extends Cubit<ChallengeState> {
  final ChallengeRepository _challengeRepository;
  final PointsRepository _pointsRepository;

  ChallengeCubit(this._challengeRepository, this._pointsRepository)
      : super(const ChallengeInitial());

  // ───────────────────────── helpers ─────────────────────────

  Map<String, ChallengeEntity> get _currentMap {
    if (state is ChallengeLoaded) return (state as ChallengeLoaded).challenges;
    if (state is ChallengeDayCompleted) return (state as ChallengeDayCompleted).allChallenges;
    if (state is ChallengeFullyCompleted) return (state as ChallengeFullyCompleted).allChallenges;
    return {};
  }

  // ───────────────────────── load ─────────────────────────

  /// Load ALL active challenges for this user.
  Future<void> loadChallenge(String userId) async {
    try {
      emit(const ChallengeLoading());

      final all = await _challengeRepository.getAllActiveChallenges(userId);

      // Expire stale challenges
      final map = <String, ChallengeEntity>{};
      for (final c in all) {
        final key = ChallengeModel.typeKey(c.challengeType);
        if (c.hasExpired()) {
          debugPrint('⚠️ [Challenge] $key expired, clearing');
          await _challengeRepository.clearChallenge(userId, typeKey: key);
        } else {
          map[key] = c;
        }
      }

      emit(ChallengeLoaded(map));
      debugPrint('✅ [Challenge] Loaded ${map.length} challenges');
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading challenges: $e');
      emit(ChallengeError('Failed to load challenges: $e'));
    }
  }

  // ───────────────────────── start ─────────────────────────

  /// Start a new challenge. Each type key gets its own Firestore doc.
  Future<void> startChallenge({
    required String userId,
    required int durationDays,
    required int rewardPoints,
    String? challengeType,
  }) async {
    try {
      emit(const ChallengeLoading());

      final challenge = ChallengeEntity(
        durationDays: durationDays,
        rewardPoints: rewardPoints,
        startDate: DateTime.now(),
        completedDays: 0,
        status: ChallengeStatus.active,
        challengeType: challengeType,
      );

      await _challengeRepository.saveChallenge(userId, challenge);

      final key = ChallengeModel.typeKey(challengeType);
      final updated = Map<String, ChallengeEntity>.from(_currentMap);
      updated[key] = challenge;
      emit(ChallengeLoaded(updated));

      debugPrint('🎯 [Challenge] Started $key: $durationDays days, $rewardPoints pts');
    } catch (e) {
      debugPrint('❌ [Challenge] Error starting challenge: $e');
      emit(ChallengeError('Failed to start challenge: $e'));
    }
  }

  // ───────────────────────── complete today ─────────────────────────

  /// Complete today's task for a specific challenge type.
  Future<void> completeTodayChallenge({
    required String userId,
    String? typeKey,
  }) async {
    try {
      final map = Map<String, ChallengeEntity>.from(_currentMap);
      final key = typeKey ?? 'default';
      final challenge = map[key];

      if (challenge == null || !challenge.isActive) {
        emit(const ChallengeError('No active challenge found'));
        return;
      }

      if (!challenge.canCompleteToday()) {
        emit(const ChallengeError('Challenge already completed today'));
        return;
      }

      emit(const ChallengeLoading());

      await _challengeRepository.completeTodayChallenge(userId, typeKey: key);

      final updated = await _challengeRepository.getActiveChallenge(userId, typeKey: key);
      if (updated == null) {
        emit(const ChallengeError('Failed to load updated challenge'));
        return;
      }

      final pointsPerDay = challenge.rewardPoints ~/ challenge.durationDays;
      await _pointsRepository.addPoints(
        userId: userId,
        points: pointsPerDay,
        source: 'challenge_${key}_day_${updated.completedDays}',
      );

      map[key] = updated;

      if (updated.isCompleted) {
        debugPrint('🎉 [Challenge] $key COMPLETED!');
        emit(ChallengeFullyCompleted(updated, challenge.rewardPoints, map));
      } else {
        debugPrint('✅ [Challenge] $key day ${updated.completedDays}, $pointsPerDay pts');
        emit(ChallengeDayCompleted(updated, pointsPerDay, map));
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing today: $e');
      emit(ChallengeError('Failed to complete challenge: $e'));
    }
  }

  // ───────────────────────── abandon ─────────────────────────

  Future<void> abandonChallenge(String userId, {String? typeKey}) async {
    try {
      emit(const ChallengeLoading());
      final key = typeKey ?? 'default';
      await _challengeRepository.clearChallenge(userId, typeKey: key);

      final map = Map<String, ChallengeEntity>.from(_currentMap);
      map.remove(key);
      emit(ChallengeLoaded(map));
      debugPrint('🗑️ [Challenge] Abandoned $key');
    } catch (e) {
      debugPrint('❌ [Challenge] Error abandoning challenge: $e');
      emit(ChallengeError('Failed to abandon challenge: $e'));
    }
  }

  // ───────────────────────── reset ─────────────────────────

  void resetToLoaded() {
    final map = _currentMap;
    emit(ChallengeLoaded(map));
  }
}
