import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());
      final user = await authRepository.getCurrentUser();
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

  Future<void> register({required String email, required String password, required String name}) async {
    try {
      emit(AuthLoading(loadingProvider: 'email'));
      final user = await authRepository.register(email: email, password: password, name: name);
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
}
