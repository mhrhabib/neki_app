import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/salah_entity.dart';
import '../../domain/repositories/salah_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'salah_state.dart';

class SalahCubit extends Cubit<SalahState> {
  final SalahRepository salahRepository;
  final PointsRepository pointsRepository;

  SalahCubit({required this.salahRepository, required this.pointsRepository}) : super(SalahInitial());

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

      // Add points
      await pointsRepository.addPoints(userId: userId, points: salah.pointsEarned, source: 'salah_$salahName');

      // Reload salahs
      await loadTodaysSalahs(userId);
    } catch (e) {
      emit(SalahError(message: e.toString()));
    }
  }
}
