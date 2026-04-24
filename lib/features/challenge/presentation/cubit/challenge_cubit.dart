import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neki_app/features/auth/presentation/cubit/support_cubit.dart';
import '../../data/models/challenge_model.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../../addiction/data/services/addiction_notification_service.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'challenge_state.dart';

class ChallengeCubit extends Cubit<ChallengeState> {
  final ChallengeRepository _challengeRepository;
  final PointsRepository _pointsRepository;
  final AddictionNotificationService _addictionNotifier;
  final SupportCubit _supportCubit;

  ChallengeCubit(
    this._challengeRepository,
    this._pointsRepository,
    this._addictionNotifier,
    this._supportCubit,
  ) : super(const ChallengeInitial());

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
    if (userId.isEmpty) return;
    try {
      emit(const ChallengeLoading());

      final all = await _challengeRepository.getAllActiveChallenges(userId);

      final map = <String, ChallengeEntity>{};
      for (final c in all) {
        final key = ChallengeModel.typeKey(c.challengeType);
        if (c.hasExpired()) {
          debugPrint('⚠️ [Challenge] $key expired — keeping to show missed streak');
          map[key] = c;
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
      final previousMap = Map<String, ChallengeEntity>.from(_currentMap);
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
      final updated = Map<String, ChallengeEntity>.from(previousMap);
      updated[key] = challenge;
      emit(ChallengeLoaded(updated));

      // Schedule milestone celebration notifications for addiction streaks
      // (1d, 3d, 7d, 14d, 30d, …). Fire-and-forget — failure is non-fatal.
      if (key.startsWith('addiction')) {
        _addictionNotifier
            .scheduleAllForStreak(typeKey: key, startDate: challenge.startDate)
            .catchError((e) => debugPrint('⚠️ milestone schedule failed: $e'));
      }

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
      final key = ChallengeModel.typeKey(typeKey);
      final challenge = map[key];

      if (challenge == null || !challenge.isActive) {
        emit(const ChallengeError('No active challenge found'));
        return;
      }
 
      if (!challenge.isCheckInWindowOpen) {
        emit(const ChallengeError('Check-in window opens after 8 PM'));
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

      // For normal challenges: points per day = total / days.
      // For addiction (durationDays=0): no daily point bonus, only milestones count.
      final pointsPerDay = challenge.durationDays > 0
          ? challenge.rewardPoints ~/ challenge.durationDays
          : 0;
      if (pointsPerDay > 0) {
        await _pointsRepository.addPoints(
          userId: userId,
          points: pointsPerDay,
          source: 'challenge_${key}_day_${updated.completedDays}',
        );
      }

      map[key] = updated;

      // Check for support/donation milestone if it's an addiction challenge.
      // For addictions the user-visible streak is the calendar `daysClean`,
      // not the manual `completedDays` check-in counter — the donation
      // prompt should follow the calendar streak.
      if (key.startsWith('addiction')) {
        _supportCubit.checkAddictionMilestone(updated.daysClean);
      }

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
      final previousMap = Map<String, ChallengeEntity>.from(_currentMap);
      emit(const ChallengeLoading());
      final key = ChallengeModel.typeKey(typeKey);

      // For addiction types, archive the attempt so the user keeps their
      // longest-streak history and can see past attempts. For other
      // challenge types, just clear.
      final existing = previousMap[key];
      if (existing != null && key.startsWith('addiction')) {
        await _challengeRepository.archiveAddictionAttempt(userId, existing);
        // Cancel the soon-to-be-meaningless milestone notifications.
        await _addictionNotifier.cancelAllForStreak(typeKey: key);
      }

      await _challengeRepository.clearChallenge(userId, typeKey: key);

      final map = Map<String, ChallengeEntity>.from(previousMap);
      map.remove(key);
      emit(ChallengeLoaded(map));
      debugPrint('🗑️ [Challenge] Abandoned $key');
    } catch (e) {
      debugPrint('❌ [Challenge] Error abandoning challenge: $e');
      emit(ChallengeError('Failed to abandon challenge: $e'));
    }
  }

  /// Past attempts for an addiction type (newest first). Used by the
  /// tracker screen to render "Longest streak" + history list.
  Future<List<ChallengeEntity>> getPastAttempts(
    String userId, {
    required String typeKey,
  }) {
    return _challengeRepository.getPastAttempts(userId, typeKey: typeKey);
  }

  // ───────────────────────── reset ─────────────────────────

  void resetToLoaded() {
    final map = _currentMap;
    emit(ChallengeLoaded(map));
  }

  void clear() {
    emit(const ChallengeInitial());
  }
}
