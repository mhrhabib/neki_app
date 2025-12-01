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
      emit(AuthLoading());
      final user = await authRepository.login(email: email, password: password);
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> register({required String email, required String password, required String name}) async {
    try {
      emit(AuthLoading());
      final user = await authRepository.register(email: email, password: password, name: name);
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
