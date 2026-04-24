import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            name: FirebaseAuth.instance.currentUser?.displayName,
            photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
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
            name: FirebaseAuth.instance.currentUser?.displayName,
            photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
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
            name: FirebaseAuth.instance.currentUser?.displayName,
            photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
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
          name: FirebaseAuth.instance.currentUser?.displayName,
          photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
        );
        needsUpdate = true;
      }

      // Sync metadata (name/photo/privacy) if changed or missing
      final currentUser = FirebaseAuth.instance.currentUser;
      
      // Fetch privacy flag from 'users' collection
      final userDoc = await _firestoreService.getDocument(
        collectionPath: 'users',
        documentId: userId,
      );
      final bool showOnLeaderboard = userDoc?.data()?['showOnLeaderboard'] ?? true;

      if (model.name != currentUser?.displayName ||
          model.photoUrl != currentUser?.photoURL ||
          model.showOnLeaderboard != showOnLeaderboard) {
        model = NekiPointsModel(
          userId: model.userId,
          totalPoints: model.totalPoints,
          todayPoints: model.todayPoints,
          weekPoints: model.weekPoints,
          monthPoints: model.monthPoints,
          currentStreak: model.currentStreak,
          longestStreak: model.longestStreak,
          lastActiveDate: model.lastActiveDate,
          name: currentUser?.displayName,
          photoUrl: currentUser?.photoURL,
          showOnLeaderboard: showOnLeaderboard,
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
    } else if (doc == null) {
      // doc is null only when getDocument() caught an exception (network error,
      // permission denied, etc.). We must NOT create a new document here because
      // that would OVERWRITE the real Firestore data with 0 points.
      // Instead, throw so the Cubit shows an error state without destroying data.
      throw Exception('Failed to load points: Firestore returned null. Check network and auth state.');
    } else {
      // doc.exists == false: the document genuinely doesn't exist yet (new user).
      // This is the ONLY safe time to create a default document.
      final defaultPoints = NekiPointsModel(
        userId: userId,
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: isStreakEnabled ? 1 : 0,
        longestStreak: isStreakEnabled ? 1 : 0,
        lastActiveDate: now,
        name: FirebaseAuth.instance.currentUser?.displayName,
        photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
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
    // Make sure the doc exists with default values + correct streak rollover
    // before issuing the atomic increment. getUserPoints handles both.
    await getUserPoints(userId);

    final docRef = _firestoreService.instance
        .collection(_collectionPath)
        .doc(userId);

    final user = FirebaseAuth.instance.currentUser;
    final updates = <String, dynamic>{
      'totalPoints': FieldValue.increment(points),
      'todayPoints': FieldValue.increment(points),
      'weekPoints': FieldValue.increment(points),
      'monthPoints': FieldValue.increment(points),
      'lastActiveDate': DateTime.now().toIso8601String(),
      if (user?.displayName != null) 'name': user!.displayName,
      if (user?.photoURL != null) 'photoUrl': user!.photoURL,
    };

    await docRef.update(updates);
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
      name: FirebaseAuth.instance.currentUser?.displayName,
      photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
    );

    await _firestoreService.setDocument(
      collectionPath: _collectionPath,
      documentId: userId,
      data: updatedPoints.toJson(),
    );
  }
}
