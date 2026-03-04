import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/neki_points_entity.dart';
import '../../domain/repositories/points_repository.dart';
import '../models/neki_points_model.dart';
import '../../../../features/salah_lock/domain/repositories/salah_lock_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  final FirestoreService _firestoreService;
  final SalahLockRepository _salahLockRepository;
  static const String _collectionPath = 'users_points';

  PointsRepositoryImpl(this._firestoreService, this._salahLockRepository);

  @override
  Future<NekiPointsEntity> getUserPoints(String userId) async {
    final doc = await _firestoreService.getDocument(
      collectionPath: _collectionPath,
      documentId: userId,
    );
    final now = DateTime.now();
    final settings = await _salahLockRepository.getSettings();
    final bool isStreakEnabled = settings.streakTracking;

    if (doc != null && doc.exists) {
      NekiPointsModel model = NekiPointsModel.fromJson(doc.data()!);
      bool needsUpdate = false;

      final lastActive = model.lastActiveDate;
      if (lastActive != null) {
        final lastActiveDate = DateTime(
          lastActive.year,
          lastActive.month,
          lastActive.day,
        );
        final todayDate = DateTime(now.year, now.month, now.day);
        final difference = todayDate.difference(lastActiveDate).inDays;

        if (difference == 1) {
          model = NekiPointsModel(
            userId: model.userId,
            totalPoints: model.totalPoints,
            todayPoints: 0,
            weekPoints: todayDate.weekday == DateTime.monday
                ? 0
                : model.weekPoints,
            monthPoints: todayDate.day == 1 ? 0 : model.monthPoints,
            currentStreak: isStreakEnabled
                ? model.currentStreak + 1
                : model.currentStreak,
            longestStreak:
                (isStreakEnabled &&
                    (model.currentStreak + 1) > model.longestStreak)
                ? (model.currentStreak + 1)
                : model.longestStreak,
            lastActiveDate: now,
          );
          needsUpdate = true;
        } else if (difference > 1) {
          model = NekiPointsModel(
            userId: model.userId,
            totalPoints: model.totalPoints,
            todayPoints: 0,
            weekPoints:
                (difference >= 7 || todayDate.weekday < lastActiveDate.weekday)
                ? 0
                : model.weekPoints,
            monthPoints:
                (difference >= 30 || todayDate.month != lastActiveDate.month)
                ? 0
                : model.monthPoints,
            currentStreak: isStreakEnabled
                ? 1
                : 0, // Reset streak to 1 if enabled, else 0
            longestStreak: model.longestStreak,
            lastActiveDate: now,
          );
          needsUpdate = true;
        } else if (difference == 0 && model.currentStreak == 0) {
          // If they haven't started a streak yet, set it to 1 if enabled
          model = NekiPointsModel(
            userId: model.userId,
            totalPoints: model.totalPoints,
            todayPoints: model.todayPoints,
            weekPoints: model.weekPoints,
            monthPoints: model.monthPoints,
            currentStreak: isStreakEnabled ? 1 : 0,
            longestStreak: (isStreakEnabled && model.longestStreak < 1)
                ? 1
                : model.longestStreak,
            lastActiveDate: now,
          );
          needsUpdate = true;
        }
      } else {
        // Migration case - lastActiveDate is null
        model = NekiPointsModel(
          userId: model.userId,
          totalPoints: model.totalPoints,
          todayPoints: model.todayPoints,
          weekPoints: model.weekPoints,
          monthPoints: model.monthPoints,
          currentStreak: (isStreakEnabled && model.currentStreak < 1)
              ? 1
              : model.currentStreak,
          longestStreak: (isStreakEnabled && model.longestStreak < 1)
              ? 1
              : model.longestStreak,
          lastActiveDate: now,
        );
        needsUpdate = true;
      }

      if (needsUpdate) {
        await _firestoreService.setDocument(
          collectionPath: _collectionPath,
          documentId: userId,
          data: model.toJson(),
        );
      }
      return model;
    } else {
      final defaultPoints = NekiPointsModel(
        userId: userId,
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: isStreakEnabled ? 1 : 0,
        longestStreak: isStreakEnabled ? 1 : 0,
        lastActiveDate: now,
      );
      // Initialize in Firestore
      await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: userId,
        data: defaultPoints.toJson(),
      );
      return defaultPoints;
    }
  }

  @override
  Future<void> addPoints({
    required String userId,
    required int points,
    required String source,
  }) async {
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;

    final updatedPoints = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints + points,
      todayPoints: currentPoints.todayPoints + points,
      weekPoints: currentPoints.weekPoints + points,
      monthPoints: currentPoints.monthPoints + points,
      currentStreak: currentPoints.currentStreak,
      longestStreak: currentPoints.longestStreak,
      lastActiveDate: DateTime.now(), // update last active on activity
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
    // Rely on getUserPoints for logic, just trigger it and update timestamp
    final currentPoints = await getUserPoints(userId) as NekiPointsModel;

    final updatedPoints = NekiPointsModel(
      userId: userId,
      totalPoints: currentPoints.totalPoints,
      todayPoints: currentPoints.todayPoints,
      weekPoints: currentPoints.weekPoints,
      monthPoints: currentPoints.monthPoints,
      currentStreak: currentPoints.currentStreak,
      longestStreak: currentPoints.longestStreak,
      lastActiveDate: DateTime.now(),
    );

    await _firestoreService.setDocument(
      collectionPath: _collectionPath,
      documentId: userId,
      data: updatedPoints.toJson(),
    );
  }
}
