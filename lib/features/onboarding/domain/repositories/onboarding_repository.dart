abstract class OnboardingRepository {
  Future<void> completeOnboarding();
  Future<bool> hasCompletedOnboarding();
}
