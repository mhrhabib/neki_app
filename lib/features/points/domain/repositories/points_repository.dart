import '../entities/neki_points_entity.dart';

abstract class PointsRepository {
  Future<NekiPointsEntity> getUserPoints(String userId);
  Future<void> addPoints({required String userId, required int points, required String source});
  Future<int> getCurrentStreak(String userId);
  Future<void> updateStreak(String userId);
}
