import 'dart:convert';

import 'package:lttbdd_nhom8/user/models/user_model.dart';
import 'package:lttbdd_nhom8/services/account_storage_access.dart';
import 'package:lttbdd_nhom8/services/password_hash_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

class UserStorageService {
  UserStorageService({
    StorageService? storage,
    this._access,
    PasswordHashService? passwords,
  }) : _storage = storage ?? StorageService.instance,
       _passwords = passwords ?? PasswordHashService();

  static final UserStorageService instance = UserStorageService();

  final StorageService _storage;
  final PasswordHashService _passwords;
  AccountStorageAccess? _access;
  List<_StoredUser> _users = [];

  void setAccessPolicy(AccountStorageAccess access) {
    _access = access;
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await _load();

    final normalizedName = name.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) {
      throw const UserStorageException('Vui lòng nhập họ và tên.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const UserStorageException('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (password.trim().isEmpty) {
      throw const UserStorageException('Vui lòng nhập mật khẩu.');
    }
    if (password.length < 8) {
      throw const UserStorageException('Mật khẩu phải có ít nhất 8 ký tự.');
    }
    if (password.length > 128) {
      throw const UserStorageException(
        'Mật khẩu không được dài quá 128 ký tự.',
      );
    }
    if (_users.any((item) => item.user.email == normalizedEmail)) {
      throw const UserStorageException('Email này đã được đăng ký.');
    }

    final user = UserModel(
      id: PasswordHashService.newId(),
      name: normalizedName,
      email: normalizedEmail,
      createdAt: DateTime.now().toUtc(),
    );
    final storedUser = _StoredUser(
      user: user,
      digest: await _passwords.create(password),
    );
    await _save([..._users, storedUser]);
    return user;
  }

  Future<UserModel?> authenticate(String email, String password) async {
    await _load();
    final storedUser = _findStoredUserByEmail(_normalizeEmail(email));
    if (storedUser == null ||
        !await _passwords.verify(password, storedUser.digest)) {
      return null;
    }
    return storedUser.user;
  }

  Future<List<UserModel>> readUsers() async {
    _requireAdmin();
    await _load(force: true);
    return List<UserModel>.unmodifiable(
      _users.map((storedUser) => storedUser.user),
    );
  }

  Future<List<UserModel>> searchUsers(String query) async {
    _requireAdmin();
    await _load(force: true);
    final normalizedQuery = query.trim().toLowerCase();
    return List<UserModel>.unmodifiable(
      _users
          .map((storedUser) => storedUser.user)
          .where(
            (user) =>
                user.name.toLowerCase().contains(normalizedQuery) ||
                user.email.toLowerCase().contains(normalizedQuery),
          ),
    );
  }

  Future<UserModel?> findById(String id) async {
    _requireReadAccess(id);
    await _load(force: true);
    return _findStoredUserById(id)?.user;
  }

  Future<UserModel?> findByEmail(String email) async {
    await _load(force: true);
    final user = _findStoredUserByEmail(_normalizeEmail(email))?.user;
    if (user != null) _requireReadAccess(user.id);
    return user;
  }

  Future<UserModel> updateUser(UserModel user) async {
    _requireReadAccess(user.id);
    await _load(force: true);
    final index = _users.indexWhere((item) => item.user.id == user.id);
    if (index < 0) {
      throw const UserStorageException('Không tìm thấy tài khoản User.');
    }
    final normalizedName = user.name.trim();
    final normalizedEmail = _normalizeEmail(user.email);
    if (normalizedName.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const UserStorageException('Thông tin hồ sơ User không hợp lệ.');
    }
    if (_users.any(
      (item) => item.user.id != user.id && item.user.email == normalizedEmail,
    )) {
      throw const UserStorageException(
        'Email này đã được tài khoản khác sử dụng.',
      );
    }

    final updatedUser = user.copyWith(
      name: normalizedName,
      email: normalizedEmail,
    );
    final updated = [..._users];
    updated[index] = updated[index].copyWith(user: updatedUser);
    await _save(updated);
    return updatedUser;
  }

  Future<bool> emailExists(String email) async {
    await _load(force: true);
    return _findStoredUserByEmail(_normalizeEmail(email)) != null;
  }

  Future<void> _load({bool force = false}) async {
    if (!force && _users.isNotEmpty) return;
    final raw = await _storage.readString(StorageService.userAccountsKey);
    if (raw == null) {
      _users = [];
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Danh sách tài khoản User không hợp lệ.');
    }
    final userData = decoded.map((value) {
      if (value is! Map) {
        throw const FormatException('Dữ liệu tài khoản User không hợp lệ.');
      }
      return _StoredUser.fromMap(Map<String, dynamic>.from(value));
    }).toList();
    final requiresRoleMigration = decoded.any(
      (value) => value is! Map || value['role'] != 'USER',
    );
    _users = userData;
    if (requiresRoleMigration) {
      await _storage.writeString(
        StorageService.userAccountsKey,
        jsonEncode(userData.map((item) => item.toMap()).toList()),
      );
    }
  }

  Future<void> _save(List<_StoredUser> users) async {
    await _storage.writeString(
      StorageService.userAccountsKey,
      jsonEncode(users.map((item) => item.toMap()).toList()),
    );
    _users = users;
  }

  _StoredUser? _findStoredUserByEmail(String email) {
    for (final user in _users) {
      if (user.user.email == email) return user;
    }
    return null;
  }

  _StoredUser? _findStoredUserById(String id) {
    for (final user in _users) {
      if (user.user.id == id) return user;
    }
    return null;
  }

  void _requireAdmin() {
    if (_access?.isAdmin != true) {
      throw const UserStorageAuthorizationException();
    }
  }

  void _requireReadAccess(String userId) {
    if (_access?.isAdmin == true || _access?.currentUserId == userId) return;
    throw const UserStorageAuthorizationException();
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();
}

class UserStorageException implements Exception {
  const UserStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserStorageAuthorizationException implements Exception {
  const UserStorageAuthorizationException();

  @override
  String toString() => 'Bạn không có quyền truy cập dữ liệu tài khoản User.';
}

class _StoredUser {
  const _StoredUser({required this.user, required this.digest});

  final UserModel user;
  final PasswordDigest digest;

  _StoredUser copyWith({UserModel? user}) {
    return _StoredUser(user: user ?? this.user, digest: digest);
  }

  factory _StoredUser.fromMap(Map<String, dynamic> map) {
    return _StoredUser(
      user: UserModel.fromMap(map),
      digest: PasswordDigest.fromMap(map),
    );
  }

  Map<String, Object> toMap() => {
    ...user.toMap(),
    'role': 'USER',
    ...digest.toMap(),
  };
}
