part of 'onboarding_cubit.dart';

abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingNotCompleted extends OnboardingState {}

class OnboardingCompleted extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError({required this.message});
}
