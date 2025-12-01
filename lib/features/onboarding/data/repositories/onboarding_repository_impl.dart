import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  bool _completed = false;

  @override
  Future<void> completeOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _completed = true;
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _completed;
  }
}
