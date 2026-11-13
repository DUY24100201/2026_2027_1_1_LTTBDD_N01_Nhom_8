class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  UserModel copyWith({String? name, String? email}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final name = map['name'];
    final email = map['email'];
    final createdAtValue = map['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    if (id is! String ||
        name is! String ||
        email is! String ||
        createdAt == null) {
      throw const FormatException('Dữ liệu tài khoản User không hợp lệ.');
    }

    return UserModel(id: id, name: name, email: email, createdAt: createdAt);
  }

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };
}
