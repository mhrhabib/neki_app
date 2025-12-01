import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/neki_points_entity.dart';
import '../../domain/repositories/points_repository.dart';

part 'points_state.dart';

class PointsCubit extends Cubit<PointsState> {
  final PointsRepository pointsRepository;

  PointsCubit({required this.pointsRepository}) : super(PointsInitial());

  Future<void> loadUserPoints(String userId) async {
    try {
      emit(PointsLoading());
      final points = await pointsRepository.getUserPoints(userId);
      emit(PointsLoaded(points: points));
    } catch (e) {
      emit(PointsError(message: e.toString()));
    }
  }

  Future<void> refreshPoints(String userId) async {
    await loadUserPoints(userId);
  }
}
