import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/onboarding_repository.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingRepository onboardingRepository;

  OnboardingCubit({required this.onboardingRepository}) : super(OnboardingInitial());

  Future<void> checkOnboarding() async {
    try {
      final completed = await onboardingRepository.hasCompletedOnboarding();
      if (completed) {
        emit(OnboardingCompleted());
      } else {
        emit(OnboardingNotCompleted());
      }
    } catch (e) {
      emit(OnboardingError(message: e.toString()));
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await onboardingRepository.completeOnboarding();
      emit(OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError(message: e.toString()));
    }
  }

  Future<void> saveGoal(int days, int points) async {
    try {
      await onboardingRepository.saveChallengeGoal(days, points);
    } catch (e) {
      emit(OnboardingError(message: e.toString()));
    }
  }

  void clear() {
    emit(OnboardingInitial());
  }
}
