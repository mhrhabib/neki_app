import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Mock implementation - replace with real API calls
  UserEntity? _currentUser;

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(id: 'user123', email: email, name: email.split('@')[0], createdAt: DateTime.now());

    return _currentUser!;
  }

  @override
  Future<UserEntity> register({required String email, required String password, required String name}) async {
    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(id: 'user123', email: email, name: name, createdAt: DateTime.now());

    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }
}
