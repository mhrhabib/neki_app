import '../../domain/entities/neki_points_entity.dart';
import '../../domain/repositories/points_repository.dart';
import '../models/neki_points_model.dart';

class PointsRepositoryImpl implements PointsRepository {
  final Map<String, NekiPointsModel> _userPoints = {};

  @override
  Future<NekiPointsEntity> getUserPoints(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!_userPoints.containsKey(userId)) {
      _userPoints[userId] = NekiPointsModel(
        userId: userId,
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
    
    return _userPoints[userId]!;
  }

  @override
  Future<void> addPoints({required String userId, required int points, required String source}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;
    
    _userPoints[userId] = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints + points,
      todayPoints: currentPoints.todayPoints + points,
      weekPoints: currentPoints.weekPoints + points,
      monthPoints: currentPoints.monthPoints + points,
      currentStreak: currentPoints.currentStreak,
      longestStreak: currentPoints.longestStreak,
    );
  }

  @override
  Future<int> getCurrentStreak(String userId) async {
    final points = await getUserPoints(userId);
    return points.currentStreak;
  }

  @override
  Future<void> updateStreak(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;
    final newStreak = currentPoints.currentStreak + 1;
    
    _userPoints[userId] = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints,
      todayPoints: currentPoints.todayPoints,
      weekPoints: currentPoints.weekPoints,
      monthPoints: currentPoints.monthPoints,
      currentStreak: newStreak,
      longestStreak: newStreak > currentPoints.longestStreak ? newStreak : currentPoints.longestStreak,
    );
  }
}
