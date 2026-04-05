import 'dart:io';
import '../../../../core/services/firebase_storage_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../points/data/models/neki_points_model.dart';
import '../../../points/domain/entities/neki_points_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreService _firestoreService;
  final FirebaseStorageService _storageService;

  ProfileRepositoryImpl(this._firestoreService, this._storageService);

  static const _badgeDefinitions = [
    _BadgeDef(
      id: 'first_prayer',
      name: 'First Prayer',
      description: 'Complete your first salah',
      icon: '🌟',
      requiredPoints: 0,
    ),
    _BadgeDef(
      id: '7_day_streak',
      name: '7 Day Streak',
      description: 'Maintain a 7-day streak',
      icon: '🔥',
      requiredPoints: 0,
    ),
    _BadgeDef(
      id: '100_neki',
      name: '100 Neki',
      description: 'Earn 100 total Neki points',
      icon: '💯',
      requiredPoints: 100,
    ),
    _BadgeDef(
      id: 'dhikr_master',
      name: 'Dhikr Master',
      description: 'Complete 100 dhikr sessions',
      icon: '📿',
      requiredPoints: 0,
    ),
    _BadgeDef(
      id: 'top_10',
      name: 'Top 10',
      description: 'Reach top 10 on the leaderboard',
      icon: '🏆',
      requiredPoints: 0,
    ),
    _BadgeDef(
      id: '30_day_streak',
      name: '30 Day Streak',
      description: 'Maintain a 30-day streak',
      icon: '⭐',
      requiredPoints: 0,
    ),
  ];

  @override
  Future<NekiPointsEntity> getUserStats(String userId) async {
    final doc = await _firestoreService.getDocument(
      collectionPath: 'users_points',
      documentId: userId,
    );

    if (doc != null && doc.exists) {
      return NekiPointsModel.fromJson(doc.data()!);
    } else {
      return NekiPointsModel(
        userId: userId,
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
  }

  @override
  Future<List<BadgeEntity>> getUserBadges(String userId) async {
    final stats = await getUserStats(userId);

    // Count salah records for this user
    final salahSnapshot = await _firestoreService.getCollection(
      collectionPath: 'users_salahs',
      queryBuilder: (q) => q.where('userId', isEqualTo: userId).limit(1),
    );
    final hasAnySalah = salahSnapshot.docs.isNotEmpty;

    // Count dhikr sessions - only need to know if >= 100
    final dhikrSnapshot = await _firestoreService.getCollection(
      collectionPath: 'dhikir_sessions',
      queryBuilder: (q) => q.where('userId', isEqualTo: userId).limit(101),
    );
    final dhikrCount = dhikrSnapshot.docs.length;

    // Check rank for top 10 - only need to check how many people are above
    final higherPointsSnapshot = await _firestoreService.getCollection(
      collectionPath: 'users_points',
      queryBuilder: (q) => q.where('totalPoints', isGreaterThan: stats.totalPoints).limit(11),
    );
    final peopleAbove = higherPointsSnapshot.docs.length;
    final rank = peopleAbove + 1;

    final badges = <BadgeEntity>[];

    for (final def in _badgeDefinitions) {
      bool isEarned = false;

      switch (def.id) {
        case 'first_prayer':
          isEarned = hasAnySalah;
          break;
        case '7_day_streak':
          isEarned = stats.currentStreak >= 7 || stats.longestStreak >= 7;
          break;
        case '100_neki':
          isEarned = stats.totalPoints >= 100;
          break;
        case 'dhikr_master':
          isEarned = dhikrCount >= 100;
          break;
        case 'top_10':
          isEarned = rank <= 10;
          break;
        case '30_day_streak':
          isEarned = stats.currentStreak >= 30 || stats.longestStreak >= 30;
          break;
      }

      badges.add(BadgeEntity(
        id: def.id,
        name: def.name,
        description: def.description,
        iconUrl: def.icon,
        requiredPoints: def.requiredPoints,
        isEarned: isEarned,
      ));
    }

    return badges;
  }

  @override
  Future<bool> getLeaderboardVisibility(String userId) async {
    final doc = await _firestoreService.getDocument(
      collectionPath: 'users',
      documentId: userId,
    );

    if (doc != null && doc.exists) {
      final data = doc.data()!;
      return data['showOnLeaderboard'] ?? true;
    }
    return true;
  }

  @override
  Future<void> updateLeaderboardVisibility(String userId, bool value) async {
    await _firestoreService.updateDocument(
      collectionPath: 'users',
      documentId: userId,
      data: {'showOnLeaderboard': value},
    );
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestoreService.setDocument(
        collectionPath: 'users',
        documentId: userId,
        data: updates,
      );

      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (name != null) await user.updateDisplayName(name);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();
      }
    }
  }

  @override
  Future<String?> uploadProfilePicture(String userId, File file) async {
    final path = 'profiles/$userId/profile_pic.jpg';
    final downloadUrl = await _storageService.uploadFile(file: file, path: path);

    if (downloadUrl != null) {
      await updateProfile(userId: userId, photoUrl: downloadUrl);
    }

    return downloadUrl;
  }
}

class _BadgeDef {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredPoints;

  const _BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredPoints,
  });
}
