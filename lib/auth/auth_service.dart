import 'dart:convert';

import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/auth/models/auth_user.dart';
import 'package:lttbdd_nhom8/services/account_storage_access.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:lttbdd_nhom8/user/models/user_model.dart';
import 'package:lttbdd_nhom8/user/user_storage_service.dart';

export 'models/auth_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthorizationException extends AuthException {
  const AuthorizationException(super.message);
}

class AuthService implements AccountStorageAccess {
  AuthService({
    StorageService? storage,
    UserStorageService? userStorage,
    AdminStorageService? adminStorage,
  }) : _storage = storage ?? StorageService.instance,
       _users =
           userStorage ??
           (storage == null
               ? UserStorageService.instance
               : UserStorageService(storage: storage)),
       _admins =
           adminStorage ??
           (storage == null
               ? AdminStorageService.instance
               : AdminStorageService(storage: storage)) {
    _users.setAccessPolicy(this);
    _admins.setAccessPolicy(this);
  }

  static final AuthService instance = AuthService();

  static const String _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
  static const String _userRole = 'USER';
  static const String _adminRole = 'ADMIN';

  final StorageService _storage;
  final UserStorageService _users;
  final AdminStorageService _admins;

  AuthUser? _currentUser;
  String? _restoringUserId;
  Future<void>? _initialization;
  bool _initialized = false;

  @override
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  @override
  String? get currentUserId =>
      _currentUser?.role == UserRole.user ? _currentUser?.id : _restoringUserId;

  Future<void> initialize() async {
    if (_initialized) return;
    final pendingInitialization = _initialization;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  void configureAdminAuthentication(AdminAuthenticationAuthority authority) {
    if (_initialized || _initialization != null) {
      throw StateError('Không thể cấu hình xác thực Admin sau khi khởi tạo.');
    }
    _admins.configureAuthenticationAuthority(authority);
  }

  Future<AuthUser> register(String name, String email, String password) async {
    await _ensureInitialized();
    final normalizedEmail = _normalizeEmail(email);
    if (!RegExp(_emailPattern).hasMatch(normalizedEmail)) {
      throw const AuthException('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    try {
      final user = await _users.createUser(
        name: name,
        email: normalizedEmail,
        password: password,
      );
      return AuthUser.fromUser(user);
    } on UserStorageException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<bool> login(String email, String password) async {
    await _ensureInitialized();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Vui lòng nhập email và mật khẩu.');
    }

    final admin = await _admins.authenticate(normalizedEmail, password);
    if (admin != null) {
      await _saveSession(id: admin.id, role: _adminRole);
      _currentUser = AuthUser.fromAdmin(admin);
      return true;
    }
    if (normalizedEmail == AdminStorageService.developmentAdminEmail &&
        await _admins.developmentAdminExists()) {
      throw const AuthException('Mật khẩu không chính xác.');
    }

    final user = await _users.authenticate(normalizedEmail, password);
    if (user == null) {
      if (await _users.emailExists(normalizedEmail)) {
        throw const AuthException('Mật khẩu không chính xác.');
      }
      throw const AuthException('Email này chưa được đăng ký.');
    }
    await _saveSession(id: user.id, role: _userRole);
    _currentUser = AuthUser.fromUser(user);
    return true;
  }

  Future<void> logout() async {
    await _ensureInitialized();
    await _clearSession();
    _currentUser = null;
  }

  AuthUser? getCurrentUser() => _currentUser;

  bool get isUser => _currentUser?.role == UserRole.user;

  void requireAdmin() {
    if (!isAdmin) {
      throw const AuthorizationException(
        'Bạn không có quyền thực hiện chức năng quản trị.',
      );
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    await _ensureInitialized();
    requireAdmin();
    return _users.readUsers();
  }

  Future<List<AdminModel>> getAllAdmins() async {
    await _ensureInitialized();
    requireAdmin();
    return _admins.readAdmins();
  }

  Future<UserModel?> getUserByEmail(String email) async {
    await _ensureInitialized();
    try {
      return await _users.findByEmail(_normalizeEmail(email));
    } on UserStorageAuthorizationException {
      throw const AuthorizationException(
        'Bạn không có quyền truy cập tài khoản User này.',
      );
    }
  }

  Future<bool> isEmailExists(String email) async {
    await _ensureInitialized();
    return _users.emailExists(email);
  }

  Future<AuthUser> updateCurrentUserProfile({
    required String name,
    required String email,
  }) async {
    await _ensureInitialized();
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw const AuthException('Vui lòng đăng nhập để cập nhật hồ sơ.');
    }

    try {
      if (currentUser.role == UserRole.admin) {
        final updatedAdmin = await _admins.updateAdmin(
          AdminModel(
            id: currentUser.id,
            name: name,
            email: email,
            createdAt: currentUser.createdAt,
          ),
        );
        _currentUser = AuthUser.fromAdmin(updatedAdmin);
      } else {
        final updatedUser = await _users.updateUser(
          UserModel(
            id: currentUser.id,
            name: name,
            email: email,
            createdAt: currentUser.createdAt,
          ),
        );
        _currentUser = AuthUser.fromUser(updatedUser);
      }
    } on UserStorageException catch (error) {
      throw AuthException(error.message);
    } on AdminStorageException catch (error) {
      throw AuthException(error.message);
    }
    return _currentUser!;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _initialize() async {
    await _admins.initializeDevelopmentAdmin();
    await _loadSession();
  }

  Future<void> _loadSession() async {
    final currentSession = await _storage.readString(
      StorageService.authSessionAccountKey,
    );
    if (currentSession != null) {
      if (currentSession.isEmpty) return;
      final decoded = jsonDecode(currentSession);
      if (decoded is! Map ||
          decoded['id'] is! String ||
          (decoded['role'] != _userRole && decoded['role'] != _adminRole)) {
        throw const FormatException('Phiên đăng nhập không hợp lệ.');
      }
      final id = decoded['id'] as String;
      final role = decoded['role'] as String;
      if (role == _adminRole) {
        final admin = await _admins.restoreSession(id);
        if (admin == null) {
          await _clearSession();
        } else {
          _currentUser = AuthUser.fromAdmin(admin);
        }
        return;
      }
      await _restoreUserSession(id);
      if (_currentUser == null) await _clearSession();
      return;
    }

    final legacyUserId = await _storage.readString(
      StorageService.authSessionKey,
    );
    if (legacyUserId == null || legacyUserId.isEmpty) return;
    await _restoreUserSession(legacyUserId);
    final currentUser = _currentUser;
    if (currentUser != null) {
      await _saveSession(id: currentUser.id, role: _userRole);
    } else {
      await _clearSession();
    }
  }

  Future<void> _restoreUserSession(String id) async {
    _restoringUserId = id;
    try {
      final user = await _users.findById(id);
      if (user != null) _currentUser = AuthUser.fromUser(user);
    } finally {
      _restoringUserId = null;
    }
  }

  Future<void> _saveSession({required String id, required String role}) async {
    await _storage.writeString(
      StorageService.authSessionAccountKey,
      jsonEncode({'id': id, 'role': role}),
    );
    await _storage.writeString(
      StorageService.authSessionKey,
      role == _userRole ? id : '',
    );
  }

  Future<void> _clearSession() async {
    await _storage.writeString(StorageService.authSessionAccountKey, '');
    await _storage.writeString(StorageService.authSessionKey, '');
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();
}
