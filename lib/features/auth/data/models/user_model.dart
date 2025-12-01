import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({required super.id, required super.email, required super.name, super.photoUrl, required super.createdAt});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'email': email, 'name': name, 'photoUrl': photoUrl, 'createdAt': createdAt.toIso8601String()};
  }
}
