class AuthService {
  // Placeholder auth service. Implement network/auth logic later.
  bool get isSignedIn => false;

  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement actual sign in
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
