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
        // Only emit Unauthenticated if we're not in a loading state
        // to avoid flickering during social login
        if (state is! AuthLoading) {
          emit(Unauthenticated());
        }
      }
    });
  }

  Future<void> checkAuthStatus() async {
    try {
      if (state is Authenticated) return;
      emit(AuthLoading());

      // Try to get user immediately
      UserEntity? user = await authRepository.getCurrentUser();

      // If null, wait a bit for Firebase Auth to initialize (it can be slow on cold start)
      if (user == null) {
        await Future.delayed(const Duration(milliseconds: 500));
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
