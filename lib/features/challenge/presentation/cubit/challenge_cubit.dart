import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'challenge_state.dart';

class ChallengeCubit extends Cubit<ChallengeState> {
  final ChallengeRepository _challengeRepository;
  final PointsRepository _pointsRepository;

  ChallengeCubit(this._challengeRepository, this._pointsRepository) : super(const ChallengeInitial());

  /// Load the current active challenge
  Future<void> loadChallenge() async {
    try {
      emit(const ChallengeLoading());

      final challenge = await _challengeRepository.getActiveChallenge();

      if (challenge != null && challenge.hasExpired()) {
        // Challenge has expired, mark as failed
        debugPrint('⚠️ [Challenge] Challenge expired, marking as failed');
        await _challengeRepository.clearChallenge();
        emit(const ChallengeLoaded(null));
        return;
      }

      emit(ChallengeLoaded(challenge));
      debugPrint('✅ [Challenge] Loaded challenge: ${challenge?.toString() ?? "None"}');
    } catch (e) {
      debugPrint('❌ [Challenge] Error loading challenge: $e');
      emit(ChallengeError('Failed to load challenge: $e'));
    }
  }

  /// Start a new challenge
  Future<void> startChallenge({required int durationDays, required int rewardPoints, String? challengeType}) async {
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

      await _challengeRepository.saveChallenge(challenge);
      emit(ChallengeLoaded(challenge));

      debugPrint('🎯 [Challenge] Started: $durationDays days, $rewardPoints points');
    } catch (e) {
      debugPrint('❌ [Challenge] Error starting challenge: $e');
      emit(ChallengeError('Failed to start challenge: $e'));
    }
  }

  /// Complete today's challenge task
  Future<void> completeTodayChallenge() async {
    try {
      final currentState = state;
      if (currentState is! ChallengeLoaded || currentState.challenge == null) {
        emit(const ChallengeError('No active challenge found'));
        return;
      }

      final challenge = currentState.challenge!;

      if (!challenge.canCompleteToday()) {
        emit(const ChallengeError('Challenge already completed today'));
        return;
      }

      emit(const ChallengeLoading());

      // Complete the day
      await _challengeRepository.completeTodayChallenge();

      // Reload to get updated challenge
      final updatedChallenge = await _challengeRepository.getActiveChallenge();

      if (updatedChallenge == null) {
        emit(const ChallengeError('Failed to load updated challenge'));
        return;
      }

      // Award points per day completed
      final pointsPerDay = challenge.rewardPoints ~/ challenge.durationDays;
      await _pointsRepository.addPoints(
        userId: 'current_user', // TODO: Get actual user ID
        points: pointsPerDay,
        source: 'challenge_day_${updatedChallenge.completedDays}',
      );

      // Check if challenge is fully completed
      if (updatedChallenge.isCompleted) {
        debugPrint('🎉 [Challenge] COMPLETED! Total points: ${challenge.rewardPoints}');
        emit(ChallengeFullyCompleted(updatedChallenge, challenge.rewardPoints));
      } else {
        debugPrint('✅ [Challenge] Day ${updatedChallenge.completedDays} completed, $pointsPerDay points earned');
        emit(ChallengeDayCompleted(updatedChallenge, pointsPerDay));
      }
    } catch (e) {
      debugPrint('❌ [Challenge] Error completing today: $e');
      emit(ChallengeError('Failed to complete challenge: $e'));
    }
  }

  /// Abandon current challenge
  Future<void> abandonChallenge() async {
    try {
      emit(const ChallengeLoading());
      await _challengeRepository.clearChallenge();
      emit(const ChallengeLoaded(null));
      debugPrint('🗑️ [Challenge] Abandoned');
    } catch (e) {
      debugPrint('❌ [Challenge] Error abandoning challenge: $e');
      emit(ChallengeError('Failed to abandon challenge: $e'));
    }
  }

  /// Reset to loaded state after showing completion message
  void resetToLoaded() {
    if (state is ChallengeFullyCompleted) {
      emit(const ChallengeLoaded(null));
    } else if (state is ChallengeDayCompleted) {
      final completedState = state as ChallengeDayCompleted;
      emit(ChallengeLoaded(completedState.challenge));
    }
  }
}
