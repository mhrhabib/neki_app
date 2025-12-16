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
      final salah = await salahRepository.markSalahComplete(userId: userId, salahName: salahName);

      // Add points for salah
      await pointsRepository.addPoints(userId: userId, points: salah.pointsEarned, source: 'salah_$salahName');

      // Check if user has an active challenge and complete today's challenge
      final hasChallenge = await challengeRepository.hasActiveChallenge();
      if (hasChallenge) {
        try {
          await challengeRepository.completeTodayChallenge();
        } catch (e) {
          // Challenge already completed today or other error, ignore
          print('Challenge completion skipped: $e');
        }
      }

      // Reload salahs
      await loadTodaysSalahs(userId);
    } catch (e) {
      emit(SalahError(message: e.toString()));
    }
  }
}
