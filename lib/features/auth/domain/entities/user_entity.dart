class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;

  UserEntity({required this.id, required this.email, required this.name, this.photoUrl, required this.createdAt});
}
