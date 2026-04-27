import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({required String email, required String password, required String name});
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> logout();
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();

  /// Overwrites the current user's `country` field (ISO-2) in Firestore
  /// using a value derived from GPS. No-op when not signed in or when the
  /// stored country already matches.
  Future<void> syncCountry(String countryCode);
}
