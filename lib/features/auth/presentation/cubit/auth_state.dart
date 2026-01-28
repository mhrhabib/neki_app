part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? loadingProvider;
  AuthLoading({this.loadingProvider});
}

class Authenticated extends AuthState {
  final UserEntity user;
  Authenticated({required this.user});
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
