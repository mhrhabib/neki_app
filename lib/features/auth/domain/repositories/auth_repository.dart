import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({required String email, required String password, required String name});
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
}
