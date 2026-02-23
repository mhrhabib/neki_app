import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdated extends ProfileState {
  final String? photoUrl;
  ProfileUpdated({this.photoUrl});
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

  Future<void> uploadProfileImage(String userId, File file) async {
    emit(ProfileLoading());
    try {
      final url = await _profileRepository.uploadProfilePicture(userId, file);
      if (url != null) {
        emit(ProfileUpdated(photoUrl: url));
      } else {
        emit(ProfileError('Failed to upload image'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
