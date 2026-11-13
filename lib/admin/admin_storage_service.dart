import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/services/account_storage_access.dart';
import 'package:lttbdd_nhom8/services/password_hash_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

abstract interface class AdminAuthenticationAuthority {
  Future<AdminModel?> authenticateAdmin(String email, String password);

  Future<AdminModel?> restoreAdminSession(String adminId);
}

class LocalOnlyAdminAuthenticationAuthority
    implements AdminAuthenticationAuthority {
  const LocalOnlyAdminAuthenticationAuthority();

  @override
  Future<AdminModel?> authenticateAdmin(String email, String password) async =>
      null;

  @override
  Future<AdminModel?> restoreAdminSession(String adminId) async => null;
}

class AdminStorageService {
  AdminStorageService({
    StorageService? storage,
    this._access,
    AdminAuthenticationAuthority? authority,
    String? developmentAdminPassword,
    bool enableDevelopmentBootstrap = true,
    PasswordHashService? passwords,
  }) : _storage = storage ?? StorageService.instance,
       _authority = authority ?? const LocalOnlyAdminAuthenticationAuthority(),
       _developmentAdminPassword =
           developmentAdminPassword ??
           const String.fromEnvironment('MELODY_DEV_ADMIN_PASSWORD'),
       _developmentBootstrapEnabled = kDebugMode && enableDevelopmentBootstrap,
       _passwords = passwords ?? PasswordHashService();

  static final AdminStorageService instance = AdminStorageService();
  static const String developmentAdminEmail = 'admin@melody.local';
  static const String _developmentAdminName = 'Melody Development Admin';

  final StorageService _storage;
  AccountStorageAccess? _access;
  AdminAuthenticationAuthority _authority;
  final String _developmentAdminPassword;
  final bool _developmentBootstrapEnabled;
  final PasswordHashService _passwords;
  List<_StoredAdmin> _admins = [];

  void setAccessPolicy(AccountStorageAccess access) {
    _access = access;
  }

  void configureAuthenticationAuthority(
    AdminAuthenticationAuthority authority,
  ) {
    _authority = authority;
  }

  Future<void> initializeDevelopmentAdmin() async {
    if (!_developmentBootstrapEnabled || _developmentAdminPassword.isEmpty) {
      return;
    }

    await _load(force: true);
    if (_findStoredAdminByEmail(developmentAdminEmail) != null) return;

    final admin = AdminModel(
      id: PasswordHashService.newId(),
      name: _developmentAdminName,
      email: developmentAdminEmail,
      createdAt: DateTime.now().toUtc(),
    );
    final digest = await _passwords.create(_developmentAdminPassword);
    await _save([..._admins, _StoredAdmin(admin: admin, digest: digest)]);
  }

  Future<AdminModel?> authenticate(String email, String password) async {
    final normalizedEmail = _normalizeEmail(email);
    final admin = await _authority.authenticateAdmin(normalizedEmail, password);
    if (admin != null) {
      if (_normalizeEmail(admin.email) != normalizedEmail) {
        throw const AdminStorageException(
          'Nguồn xác thực trả về tài khoản Admin không khớp.',
        );
      }
      _validateAdminProfile(admin);
      await _load(force: true);
      final normalizedAdmin = admin.copyWith(
        email: _normalizeEmail(admin.email),
      );
      final index = _admins.indexWhere(
        (item) => item.admin.id == normalizedAdmin.id,
      );
      final updated = [..._admins];
      final storedAdmin = _StoredAdmin(
        admin: normalizedAdmin,
        digest: index < 0 ? null : updated[index].digest,
      );
      if (index < 0) {
        updated.add(storedAdmin);
      } else {
        updated[index] = storedAdmin;
      }
      await _save(updated);
      return normalizedAdmin;
    }

    if (normalizedEmail == developmentAdminEmail &&
        _developmentBootstrapEnabled &&
        _developmentAdminPassword.isEmpty &&
        _authority is LocalOnlyAdminAuthenticationAuthority) {
      throw const AdminStorageException(
        'Tài khoản Admin debug chưa được khởi tạo. Hãy chạy lại ứng dụng với '
        '--dart-define=MELODY_DEV_ADMIN_PASSWORD=<mật-khẩu-thử-nghiệm>.',
      );
    }

    if (!_isDevelopmentPasswordLogin(normalizedEmail, password)) return null;
    await _load(force: true);
    final storedAdmin = _findStoredAdminByEmail(developmentAdminEmail);
    final digest = storedAdmin?.digest;
    if (storedAdmin == null ||
        digest == null ||
        !await _passwords.verify(password, digest)) {
      return null;
    }
    return storedAdmin.admin;
  }

  Future<bool> developmentAdminExists() async {
    await _load(force: true);
    return _findStoredAdminByEmail(developmentAdminEmail) != null;
  }

  Future<AdminModel?> restoreSession(String adminId) async {
    final admin = await _authority.restoreAdminSession(adminId);
    if (admin == null) return null;
    if (admin.id != adminId) {
      throw const AdminStorageException(
        'Nguồn xác thực trả về phiên Admin không khớp.',
      );
    }
    _validateAdminProfile(admin);

    await _load(force: true);
    final index = _admins.indexWhere((item) => item.admin.id == admin.id);
    final updated = [..._admins];
    final storedAdmin = _StoredAdmin(
      admin: admin,
      digest: index < 0 ? null : updated[index].digest,
    );
    if (index < 0) {
      updated.add(storedAdmin);
    } else {
      updated[index] = storedAdmin;
    }
    await _save(updated);
    return admin;
  }

  Future<AdminModel> saveAdmin(AdminModel admin) async {
    _requireAdmin();
    await _load(force: true);
    if (_admins.any(
      (item) =>
          item.admin.id == admin.id ||
          _normalizeEmail(item.admin.email) == _normalizeEmail(admin.email),
    )) {
      throw const AdminStorageException('Tài khoản Admin này đã tồn tại.');
    }
    _validateAdminProfile(admin);
    final normalizedAdmin = admin.copyWith(
      name: admin.name.trim(),
      email: _normalizeEmail(admin.email),
    );
    await _save([..._admins, _StoredAdmin(admin: normalizedAdmin)]);
    return normalizedAdmin;
  }

  Future<List<AdminModel>> readAdmins() async {
    _requireAdmin();
    await _load(force: true);
    return List<AdminModel>.unmodifiable(
      _admins.map((storedAdmin) => storedAdmin.admin),
    );
  }

  Future<List<AdminModel>> searchAdmins(String query) async {
    _requireAdmin();
    await _load(force: true);
    final normalizedQuery = query.trim().toLowerCase();
    return List<AdminModel>.unmodifiable(
      _admins
          .map((storedAdmin) => storedAdmin.admin)
          .where(
            (admin) =>
                admin.name.toLowerCase().contains(normalizedQuery) ||
                admin.email.toLowerCase().contains(normalizedQuery),
          ),
    );
  }

  Future<AdminModel?> findById(String id) async {
    _requireAdmin();
    await _load(force: true);
    for (final storedAdmin in _admins) {
      final admin = storedAdmin.admin;
      if (admin.id == id) return admin;
    }
    return null;
  }

  Future<AdminModel?> findByEmail(String email) async {
    _requireAdmin();
    await _load(force: true);
    final normalizedEmail = _normalizeEmail(email);
    for (final storedAdmin in _admins) {
      final admin = storedAdmin.admin;
      if (_normalizeEmail(admin.email) == normalizedEmail) return admin;
    }
    return null;
  }

  Future<AdminModel> updateAdmin(AdminModel admin) async {
    _requireAdmin();
    await _load(force: true);
    final index = _admins.indexWhere((item) => item.admin.id == admin.id);
    if (index < 0) {
      throw const AdminStorageException('Không tìm thấy tài khoản Admin.');
    }
    final normalizedEmail = _normalizeEmail(admin.email);
    if (_admins.any(
      (item) =>
          item.admin.id != admin.id &&
          _normalizeEmail(item.admin.email) == normalizedEmail,
    )) {
      throw const AdminStorageException(
        'Email này đã được tài khoản Admin khác sử dụng.',
      );
    }

    _validateAdminProfile(admin);
    final updatedAdmin = admin.copyWith(
      name: admin.name.trim(),
      email: normalizedEmail,
    );
    final updated = [..._admins];
    updated[index] = updated[index].copyWith(admin: updatedAdmin);
    await _save(updated);
    return updatedAdmin;
  }

  Future<void> _load({bool force = false}) async {
    if (!force && _admins.isNotEmpty) return;
    final raw = await _storage.readString(StorageService.adminAccountsKey);
    if (raw == null) {
      _admins = [];
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Danh sách tài khoản Admin không hợp lệ.');
    }
    _admins = decoded.map((value) {
      if (value is! Map) {
        throw const FormatException('Dữ liệu tài khoản Admin không hợp lệ.');
      }
      return _StoredAdmin.fromMap(Map<String, dynamic>.from(value));
    }).toList();
  }

  Future<void> _save(List<_StoredAdmin> admins) async {
    await _storage.writeString(
      StorageService.adminAccountsKey,
      jsonEncode(admins.map((admin) => admin.toMap()).toList()),
    );
    _admins = admins;
  }

  _StoredAdmin? _findStoredAdminByEmail(String email) {
    final normalizedEmail = _normalizeEmail(email);
    for (final admin in _admins) {
      if (_normalizeEmail(admin.admin.email) == normalizedEmail) return admin;
    }
    return null;
  }

  bool _isDevelopmentPasswordLogin(String email, String password) =>
      _developmentBootstrapEnabled &&
      _developmentAdminPassword.isNotEmpty &&
      _normalizeEmail(email) == developmentAdminEmail &&
      password == _developmentAdminPassword;

  void _requireAdmin() {
    if (_access?.isAdmin != true) {
      throw const AdminStorageAuthorizationException();
    }
  }

  void _validateAdminProfile(AdminModel admin) {
    if (admin.id.trim().isEmpty ||
        admin.name.trim().isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(admin.email.trim())) {
      throw const AdminStorageException('Thông tin hồ sơ Admin không hợp lệ.');
    }
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();
}

class _StoredAdmin {
  const _StoredAdmin({required this.admin, this.digest});

  final AdminModel admin;
  final PasswordDigest? digest;

  _StoredAdmin copyWith({AdminModel? admin}) =>
      _StoredAdmin(admin: admin ?? this.admin, digest: digest);

  factory _StoredAdmin.fromMap(Map<String, dynamic> map) {
    final hasDigest =
        map.containsKey('salt') ||
        map.containsKey('passwordHash') ||
        map.containsKey('algorithm') ||
        map.containsKey('iterations');
    return _StoredAdmin(
      admin: AdminModel.fromMap(map),
      digest: hasDigest ? PasswordDigest.fromMap(map) : null,
    );
  }

  Map<String, Object> toMap() => {
    ...admin.toMap(),
    if (digest != null) ...digest!.toMap(),
  };
}

class AdminStorageException implements Exception {
  const AdminStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminStorageAuthorizationException implements Exception {
  const AdminStorageAuthorizationException();

  @override
  String toString() => 'Bạn không có quyền truy cập dữ liệu tài khoản Admin.';
}
