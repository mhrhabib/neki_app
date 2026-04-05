import 'dart:io';
import '../entities/badge_entity.dart';
import '../../../points/domain/entities/neki_points_entity.dart';

abstract class ProfileRepository {
  Future<NekiPointsEntity> getUserStats(String userId);
  Future<List<BadgeEntity>> getUserBadges(String userId);
  Future<void> updateProfile({required String userId, String? name, String? photoUrl});
  Future<String?> uploadProfilePicture(String userId, File file);
  Future<bool> getLeaderboardVisibility(String userId);
  Future<void> updateLeaderboardVisibility(String userId, bool value);
}
