import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _completedKey = 'onboarding_completed';
  static const String _challengeDaysKey = 'challenge_days';
  static const String _challengeTargetKey = 'challenge_target';

  @override
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> saveChallengeGoal(int days, int targetPoints) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_challengeDaysKey, days),
      prefs.setInt(_challengeTargetKey, targetPoints),
    ]);
  }
}
