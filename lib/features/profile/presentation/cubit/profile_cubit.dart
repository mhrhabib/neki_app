import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../points/domain/entities/neki_points_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final NekiPointsEntity stats;
  final List<BadgeEntity> badges;
  final bool showOnLeaderboard;
  final int daysActive;

  ProfileLoaded({
    required this.stats,
    required this.badges,
    required this.showOnLeaderboard,
    required this.daysActive,
  });

  @override
  List<Object?> get props => [stats, badges, showOnLeaderboard, daysActive];

  ProfileLoaded copyWith({
    NekiPointsEntity? stats,
    List<BadgeEntity>? badges,
    bool? showOnLeaderboard,
    int? daysActive,
  }) {
    return ProfileLoaded(
      stats: stats ?? this.stats,
      badges: badges ?? this.badges,
      showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
      daysActive: daysActive ?? this.daysActive,
    );
  }
}

class ProfilePhotoUpdated extends ProfileState {
  final String? photoUrl;
  ProfilePhotoUpdated({this.photoUrl});
  @override
  List<Object?> get props => [photoUrl];
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(ProfileInitial());

  Future<void> loadProfile(String userId, {DateTime? createdAt}) async {
    emit(ProfileLoading());
    try {
      final results = await Future.wait([
        _profileRepository.getUserStats(userId),
        _profileRepository.getUserBadges(userId),
        _profileRepository.getLeaderboardVisibility(userId),
      ]);

      final stats = results[0] as NekiPointsEntity;
      final badges = results[1] as List<BadgeEntity>;
      final showOnLeaderboard = results[2] as bool;

      final daysActive = createdAt != null
          ? DateTime.now().difference(createdAt).inDays + 1
          : 1;

      emit(ProfileLoaded(
        stats: stats,
        badges: badges,
        showOnLeaderboard: showOnLeaderboard,
        daysActive: daysActive,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateLeaderboardVisibility(String userId, bool value) async {
    final current = state;
    if (current is ProfileLoaded) {
      emit(current.copyWith(showOnLeaderboard: value));
      try {
        await _profileRepository.updateLeaderboardVisibility(userId, value);
      } catch (e) {
        emit(current.copyWith(showOnLeaderboard: !value));
      }
    }
  }

  Future<void> uploadProfileImage(String userId, File file) async {
    final previousState = state;
    emit(ProfileLoading());
    try {
      final url = await _profileRepository.uploadProfilePicture(userId, file);
      if (url != null) {
        emit(ProfilePhotoUpdated(photoUrl: url));
        // Reload profile to restore full state
        if (previousState is ProfileLoaded) {
          emit(previousState);
        }
      } else {
        emit(ProfileError('Failed to upload image'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
