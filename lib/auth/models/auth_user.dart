import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/user/models/user_model.dart';

enum UserRole { user, admin }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final UserRole role;

  AuthUser copyWith({String? name, String? email}) => AuthUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    createdAt: createdAt,
    role: role,
  );

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'role': role.name.toUpperCase(),
  };

  factory AuthUser.fromUser(UserModel user) => AuthUser(
    id: user.id,
    name: user.name,
    email: user.email,
    createdAt: user.createdAt,
    role: UserRole.user,
  );

  factory AuthUser.fromAdmin(AdminModel admin) => AuthUser(
    id: admin.id,
    name: admin.name,
    email: admin.email,
    createdAt: admin.createdAt,
    role: UserRole.admin,
  );
}
