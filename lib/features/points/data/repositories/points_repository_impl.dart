import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/neki_points_entity.dart';
import '../../domain/repositories/points_repository.dart';
import '../models/neki_points_model.dart';

class PointsRepositoryImpl implements PointsRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'users_points';

  PointsRepositoryImpl(this._firestoreService);

  @override
  Future<NekiPointsEntity> getUserPoints(String userId) async {
    final doc = await _firestoreService.getDocument(collectionPath: _collectionPath, documentId: userId);

    if (doc != null && doc.exists) {
      return NekiPointsModel.fromJson(doc.data()!);
    } else {
      final defaultPoints = NekiPointsModel(
        userId: userId,
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
      // Optional: Initialize in Firestore
      await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: userId,
        data: defaultPoints.toJson(),
      );
      return defaultPoints;
    }
  }

  @override
  Future<void> addPoints({required String userId, required int points, required String source}) async {
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;

    final updatedPoints = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints + points,
      todayPoints: currentPoints.todayPoints + points,
      weekPoints: currentPoints.weekPoints + points,
      monthPoints: currentPoints.monthPoints + points,
      currentStreak: currentPoints.currentStreak,
      longestStreak: currentPoints.longestStreak,
    );

    await _firestoreService.setDocument(
      collectionPath: _collectionPath,
      documentId: userId,
      data: updatedPoints.toJson(),
    );
  }

  @override
  Future<int> getCurrentStreak(String userId) async {
    final points = await getUserPoints(userId);
    return points.currentStreak;
  }

  @override
  Future<void> updateStreak(String userId) async {
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;
    final newStreak = currentPoints.currentStreak + 1;

    final updatedPoints = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints,
      todayPoints: currentPoints.todayPoints,
      weekPoints: currentPoints.weekPoints,
      monthPoints: currentPoints.monthPoints,
      currentStreak: newStreak,
      longestStreak: newStreak > currentPoints.longestStreak ? newStreak : currentPoints.longestStreak,
    );

    await _firestoreService.setDocument(
      collectionPath: _collectionPath,
      documentId: userId,
      data: updatedPoints.toJson(),
    );
  }
}
