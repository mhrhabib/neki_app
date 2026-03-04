abstract class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool isPremium);
  Stream<bool> get premiumStatusStream;
}
