import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Firebase-backed implementation of [AuthRepository].
///
/// Notes:
/// - Requires `Firebase.initializeApp()` to be called before using this class.
class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '327642350514-4lcqmvbq71fa8ojuilcd8uklm2lua0q8.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  UserModel? _mapFirebaseUser(fb_auth.User? user) {
    if (user == null) return null;
    final createdAt = user.metadata.creationTime ?? DateTime.now();
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
      createdAt: createdAt,
    );
  }

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    final mapped = _mapFirebaseUser(user);
    if (mapped == null) throw Exception('Failed to sign in');
    return mapped;
  }

  @override
  Future<UserEntity> register({required String email, required String password, required String name}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;

    if (user == null) throw Exception('Failed to create user');

    // Update display name
    await user.updateDisplayName(name);
    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    final mapped = _mapFirebaseUser(refreshed);
    if (mapped == null) throw Exception('Failed to map created user');
    return mapped;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      debugPrint('🔵 [GoogleSignIn] Starting sign-in flow...');

      // First, try to sign out to clear any cached state
      await _googleSignIn.signOut();
      debugPrint('🔵 [GoogleSignIn] Signed out previous session');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('🔵 [GoogleSignIn] User account: ${googleUser?.email ?? "null"}');

      if (googleUser == null) {
        debugPrint('⚠️ [GoogleSignIn] User cancelled sign-in');
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      debugPrint('🔵 [GoogleSignIn] Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('🔵 [GoogleSignIn] Access Token: ${googleAuth.accessToken?.substring(0, 20)}...');
      debugPrint('🔵 [GoogleSignIn] ID Token: ${googleAuth.idToken?.substring(0, 20)}...');

      // Create a new credential
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('🔵 [GoogleSignIn] Credential created, signing in to Firebase...');

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('✅ [GoogleSignIn] Firebase sign-in successful!');

      final user = userCredential.user;
      final mapped = _mapFirebaseUser(user);
      if (mapped == null) throw Exception('Failed to sign in with Google');

      debugPrint('✅ [GoogleSignIn] User mapped: ${mapped.email}');
      return mapped;
    } catch (e, stackTrace) {
      debugPrint('❌ [GoogleSignIn] ERROR: $e');
      debugPrint('❌ [GoogleSignIn] Stack trace: $stackTrace');
      throw Exception('Google sign-in failed: $e');
    }
  }

  @override
  Future<UserEntity> signInWithFacebook() async {
    try {
      debugPrint('🔵 [FacebookAuth] Starting login flow...');

      // Trigger the Facebook Sign-In flow
      final LoginResult result = await _facebookAuth.login();
      debugPrint('🔵 [FacebookAuth] Login status: ${result.status}');

      if (result.status != LoginStatus.success) {
        debugPrint('⚠️ [FacebookAuth] Login failed or cancelled: ${result.status}');
        throw Exception('Facebook sign-in was cancelled or failed');
      }

      // Get the access token
      final accessToken = result.accessToken;
      if (accessToken == null) {
        debugPrint('❌ [FacebookAuth] Access token is null');
        throw Exception('Failed to get Facebook access token');
      }
      debugPrint('🔵 [FacebookAuth] Access token: ${accessToken.token.substring(0, 20)}...');

      // Create a credential from the access token
      final credential = fb_auth.FacebookAuthProvider.credential(accessToken.token);
      debugPrint('🔵 [FacebookAuth] Credential created, signing in to Firebase...');

      // Sign in to Firebase with the Facebook credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('✅ [FacebookAuth] Firebase sign-in successful!');

      final user = userCredential.user;
      final mapped = _mapFirebaseUser(user);
      if (mapped == null) throw Exception('Failed to sign in with Facebook');

      debugPrint('✅ [FacebookAuth] User mapped: ${mapped.email}');
      return mapped;
    } catch (e, stackTrace) {
      debugPrint('❌ [FacebookAuth] ERROR: $e');
      debugPrint('❌ [FacebookAuth] Stack trace: $stackTrace');
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple Sign-In is only available on iOS and macOS');
    }

    try {
      debugPrint('🔵 [AppleSignIn] Starting sign-in flow...');

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );
      debugPrint('🔵 [AppleSignIn] Apple ID credential received');

      // Create OAuth credential for Firebase
      final oauthCredential = fb_auth.OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);
      debugPrint('🔵 [AppleSignIn] Firebase OAuth credential created');

      // Sign in to Firebase with Apple credential
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      debugPrint('✅ [AppleSignIn] Firebase sign-in successful!');

      // Update display name if provided by Apple (only on first sign-in)
      if (user != null && appleCredential.givenName != null && appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        await user.updateDisplayName(displayName);
        await user.reload();
        debugPrint('🔵 [AppleSignIn] Updated display name: $displayName');
      }

      final refreshed = _firebaseAuth.currentUser;
      final mapped = _mapFirebaseUser(refreshed);
      if (mapped == null) throw Exception('Failed to sign in with Apple');

      debugPrint('✅ [AppleSignIn] User mapped: ${mapped.email}');
      return mapped;
    } catch (e, stackTrace) {
      debugPrint('❌ [AppleSignIn] ERROR: $e');
      debugPrint('❌ [AppleSignIn] Stack trace: $stackTrace');
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('🔵 [Logout] Starting logout process...');

      // Sign out from Firebase (main auth)
      await _firebaseAuth.signOut();
      debugPrint('✅ [Logout] Firebase signed out');

      // Try to sign out from Google (ignore errors if not signed in with Google)
      try {
        await _googleSignIn.signOut();
        debugPrint('✅ [Logout] Google signed out');
      } catch (e) {
        debugPrint('⚠️ [Logout] Google sign out skipped: $e');
      }

      // Try to sign out from Facebook (ignore errors if not signed in with Facebook)
      try {
        await _facebookAuth.logOut();
        debugPrint('✅ [Logout] Facebook signed out');
      } catch (e) {
        debugPrint('⚠️ [Logout] Facebook logout skipped: $e');
      }

      debugPrint('✅ [Logout] Logout completed successfully');
    } catch (e) {
      debugPrint('❌ [Logout] Error during logout: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    return _mapFirebaseUser(user);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }
}
