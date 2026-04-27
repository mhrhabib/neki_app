abstract class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool isPremium);
  Stream<bool> get premiumStatusStream;

  // Trial Logic
  Future<DateTime?> getTrialStartDate();
  Future<void> startTrial();
  bool isPremiumSync();
  bool isTrialActiveSync();
  int trialDaysRemainingSync();
}
