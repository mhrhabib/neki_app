abstract class OnboardingRepository {
  Future<void> completeOnboarding();
  Future<bool> hasCompletedOnboarding();
  Future<void> saveChallengeGoal(int days, int targetPoints);
  Future<Map<String, int>?> getChallengeGoal();
}
