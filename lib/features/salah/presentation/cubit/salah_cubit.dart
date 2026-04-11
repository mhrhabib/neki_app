import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/salah_entity.dart';
import '../../domain/repositories/salah_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';
import '../../../challenge/domain/repositories/challenge_repository.dart';

part 'salah_state.dart';

class SalahCubit extends Cubit<SalahState> {
  final SalahRepository salahRepository;
  final PointsRepository pointsRepository;
  final ChallengeRepository challengeRepository;

  SalahCubit({required this.salahRepository, required this.pointsRepository, required this.challengeRepository})
    : super(SalahInitial());

  Future<void> loadTodaysSalahs(String userId) async {
    if (userId.isEmpty) return;
    try {
      emit(SalahLoading());
      final salahs = await salahRepository.getTodaysSalahs(userId);
      emit(SalahLoaded(salahs: salahs));
    } catch (e) {
      emit(SalahError(message: e.toString()));
    }
  }

  Future<void> markSalahComplete({required String userId, required String salahName}) async {
    try {
      // ── Idempotency guard ──
      // Multiple code paths can call this: the overlay, the Salah screen, a
      // notification action, and the reconciliation loop in SalahLockCubit.
      // If the current loaded state already shows this prayer as completed,
      // skip the write + points so we don't double-credit the user.
      final currentState = state;
      if (currentState is SalahLoaded) {
        final already = currentState.salahs.any(
          (s) => s.salahName == salahName && s.isCompleted,
        );
        if (already) {
          debugPrint('ℹ️ [Salah] $salahName already complete — skipping duplicate write');
          return;
        }
      } else {
        // If state isn't loaded yet, fetch to be sure before writing.
        try {
          final existing = await salahRepository.getTodaysSalahs(userId);
          final already = existing.any(
            (s) => s.salahName == salahName && s.isCompleted,
          );
          if (already) {
            debugPrint('ℹ️ [Salah] $salahName already complete in Firestore — skipping');
            emit(SalahLoaded(salahs: existing));
            return;
          }
        } catch (_) {
          // If the pre-check fails, fall through and let the write attempt run.
        }
      }

      final salah = await salahRepository.markSalahComplete(userId: userId, salahName: salahName);

      // Add points for salah
      await pointsRepository.addPoints(userId: userId, points: salah.pointsEarned, source: 'salah_$salahName');

      // Check if user has an active challenge and complete today's challenge progress
      final activeChallenge = await challengeRepository.getActiveChallenge(userId);
      if (activeChallenge != null && activeChallenge.isActive && activeChallenge.canCompleteToday()) {
        try {
          await challengeRepository.completeTodayChallenge(userId);
          debugPrint('✅ [Challenge] Daily progress updated from prayer completion');
        } catch (e) {
          debugPrint('⚠️ [Challenge] Completion skipped: $e');
        }
      }

      // Reload salahs
      await loadTodaysSalahs(userId);
    } catch (e) {
      emit(SalahError(message: e.toString()));
    }
  }

  void clear() {
    emit(SalahInitial());
  }
}
