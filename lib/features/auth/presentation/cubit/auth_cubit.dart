import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../roza/presentation/cubit/roza_cubit.dart';
import '../../../dhikir/presentation/cubit/dhikir_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../zakat/presentation/cubit/zakat_cubit.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthCubit({required this.authRepository}) : super(AuthInitial()) {
    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user: user));
        // Trigger onboarding check for the new user
        getIt<OnboardingCubit>().checkOnboarding();
      } else {
        // ─── CRITICAL FIX FOR SESSION PERSISTENCE ───
        // Only emit Unauthenticated if we are NOT in the initial setup phase.
        // At startup (AuthInitial), Firebase stream often emits null briefly.
        // We let checkAuthStatus() handle the definitive initial check.
        if (state is! AuthInitial && state is! AuthLoading) {
          emit(Unauthenticated());
        }
      }
    });
  }

  Future<void> checkAuthStatus() async {
    try {
      if (state is Authenticated) return;
      emit(AuthLoading());

      // ─── Session restoration, in order of cheapest → most patient ───
      // Firebase Auth persists the last signed-in user on disk and restores
      // it synchronously on SDK init, so in most cases getCurrentUser()
      // returns immediately. Only when the SDK is still restoring (first
      // frame after a cold start / process death) do we need to wait.
      UserEntity? user = await authRepository.getCurrentUser();

      // If the direct check came back empty, wait on the auth stream. We
      // use generous timeouts because on slower devices (especially after
      // a reinstall or OS kill) Firebase's token refresh can take 2-4s.
      if (user == null) {
        try {
          user = await authRepository.authStateChanges
              .where((u) => u != null)
              .first
              .timeout(const Duration(seconds: 4));
        } catch (_) {
          // Stream never emitted a non-null — try one more direct read in
          // case the SDK finished restoring between our first check and now.
          user = await authRepository.getCurrentUser();
        }
      }

      // Final grace period: give Firebase one more beat to finish disk I/O
      // before we give up and kick the user back to the login screen.
      if (user == null) {
        await Future.delayed(const Duration(seconds: 1));
        user = await authRepository.getCurrentUser();
      }

      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      emit(AuthLoading(loadingProvider: 'email'));
      final user = await authRepository.login(email: email, password: password);
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      emit(AuthLoading(loadingProvider: 'email'));
      final user = await authRepository.register(
        email: email,
        password: password,
        name: name,
      );
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading(loadingProvider: 'google'));
      debugPrint('🔵 Starting Google Sign-In...');
      final user = await authRepository.signInWithGoogle();
      debugPrint('✅ Google Sign-In successful: ${user.email}');
      emit(Authenticated(user: user));
    } catch (e) {
      debugPrint('❌ Google Sign-In ERROR: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      emit(AuthLoading(loadingProvider: 'facebook'));
      debugPrint('🔵 Starting Facebook Login...');
      final user = await authRepository.signInWithFacebook();
      debugPrint('✅ Facebook Login successful: ${user.email}');
      emit(Authenticated(user: user));
    } catch (e) {
      debugPrint('❌ Facebook Login ERROR: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signInWithApple() async {
    try {
      emit(AuthLoading(loadingProvider: 'apple'));
      final user = await authRepository.signInWithApple();
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔵 Starting logout from AuthCubit...');

      // 1. Clear session data from other Cubits to stop listeners and wipe local state
      try {
        getIt<SalahCubit>().clear();
        getIt<PointsCubit>().clear();
        getIt<RozaCubit>().clear();
        getIt<DhikirCubit>().clear();
        getIt<ChallengeCubit>().clear();
        getIt<ProfileCubit>().clear();
        getIt<ZakatCubit>().clear();
        getIt<LeaderboardCubit>().clear();
        getIt<OnboardingCubit>().clear(); // Also clear onboarding if user-specific
        getIt<SalahLockCubit>().clear(); // Stop background timers and listeners
      } catch (e) {
        debugPrint('⚠️ [AuthCubit] Cleanup failed for some cubits: $e');
      }

      await authRepository.logout();
      debugPrint('✅ Logout successful, emitting Unauthenticated state');
      emit(Unauthenticated());
    } catch (e) {
      debugPrint('❌ Logout ERROR in AuthCubit: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      // Even if there's an error, we should still mark as unauthenticated
      // because Firebase auth was signed out
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
