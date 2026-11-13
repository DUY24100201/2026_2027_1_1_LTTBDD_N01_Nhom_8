class AdminModel {
  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  AdminModel copyWith({String? name, String? email}) {
    return AdminModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
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
      throw const FormatException('Dữ liệu tài khoản Admin không hợp lệ.');
    }

    return AdminModel(id: id, name: name, email: email, createdAt: createdAt);
  }

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };
}
