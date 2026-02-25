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

  @override
  Future<NekiPointsEntity> getUserStats(String userId) async {
    final doc = await _firestoreService.getDocument(collectionPath: 'users_points', documentId: userId);

    if (doc != null && doc.exists) {
      return NekiPointsModel.fromJson(doc.data()!);
    } else {
      // Return default points if not found in Firestore
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
    // For now, returning mock data or fetching from a 'badges' subcollection if exists
    // In a real app, this would be a collection group or subcollection
    return [];
  }

  @override
  Future<void> updateProfile({required String userId, String? name, String? photoUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      // Update in Firestore
      await _firestoreService.setDocument(collectionPath: 'users', documentId: userId, data: updates);

      // Also update Firebase Auth display name/photo if applicable
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (name != null) await user.updateDisplayName(name);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();
      }
    }
  }

  /// Helper method to upload profile picture and update profile
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
