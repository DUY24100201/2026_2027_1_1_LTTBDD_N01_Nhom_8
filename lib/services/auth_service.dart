import 'dart:convert';
import 'dart:math';

import 'password_hash_io.dart'
    if (dart.library.js_interop) 'password_hash_web.dart' as password_hash;
import 'storage_service.dart';

const int _passwordHashIterations = 600000;
const int _passwordSaltLength = 16;
const int _passwordHashLength = 32;
const String _passwordHashAlgorithm = 'pbkdf2-hmac-sha256';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  AuthUser copyWith({String? name, String? email}) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({StorageService? storage})
    : _storage = storage ?? StorageService.instance;

  static final AuthService instance = AuthService();

  static const String _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

  final StorageService _storage;
  List<_StoredAccount> _accounts = [];
  AuthUser? _currentUser;
  Future<void>? _initialization;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final pendingInitialization = _initialization;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final initialization = _load();
    _initialization = initialization;
    try {
      await initialization;
      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<AuthUser> register(String name, String email, String password) async {
    await _ensureInitialized();

    final normalizedName = name.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) {
      throw const AuthException('Vui lòng nhập họ và tên.');
    }
    if (!RegExp(_emailPattern).hasMatch(normalizedEmail)) {
      throw const AuthException(
        'Vui lòng nhập địa chỉ email hợp lệ.',
      );
    }
    if (password.trim().isEmpty) {
      throw const AuthException('Vui lòng nhập mật khẩu.');
    }
    if (password.length < 8) {
      throw const AuthException(
        'Mật khẩu phải có ít nhất 8 ký tự.',
      );
    }
    if (password.length > 128) {
      throw const AuthException(
        'Mật khẩu không được dài quá 128 ký tự.',
      );
    }
    if (_findAccountByEmail(normalizedEmail) != null) {
      throw const AuthException('Email này đã được đăng ký.');
    }

    final salt = _secureRandomBytes(_passwordSaltLength);
    final passwordHash = await password_hash.derivePasswordHash(
      password,
      salt,
      _passwordHashIterations,
    );
    final account = _StoredAccount(
      user: AuthUser(
        id: _newId(),
        name: normalizedName,
        email: normalizedEmail,
        createdAt: DateTime.now().toUtc(),
      ),
      salt: salt,
      passwordHash: passwordHash,
      iterations: _passwordHashIterations,
    );
    final updatedAccounts = [..._accounts, account];
    await _saveAccounts(updatedAccounts);
    _accounts = updatedAccounts;
    return account.user;
  }

  Future<bool> login(String email, String password) async {
    await _ensureInitialized();

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Vui lòng nhập email và mật khẩu.');
    }

    final account = _findAccountByEmail(normalizedEmail);
    if (account == null) {
      throw const AuthException('Email này chưa được đăng ký.');
    }

    final passwordHash = await password_hash.derivePasswordHash(
      password,
      account.salt,
      account.iterations,
    );
    if (!_constantTimeEquals(passwordHash, account.passwordHash)) {
      throw const AuthException('Mật khẩu không chính xác.');
    }

    await _storage.writeString(StorageService.authSessionKey, account.user.id);
    _currentUser = account.user;
    return true;
  }

  Future<void> logout() async {
    await _ensureInitialized();
    await _storage.writeString(StorageService.authSessionKey, '');
    _currentUser = null;
  }

  AuthUser? getCurrentUser() => _currentUser;

  Future<List<AuthUser>> getAllUsers() async {
    await _ensureInitialized();
    _accounts = await _readAccounts();
    return List<AuthUser>.unmodifiable(
      _accounts.map((account) => account.user),
    );
  }

  Future<AuthUser?> getUserByEmail(String email) async {
    await _ensureInitialized();
    return _findAccountByEmail(_normalizeEmail(email))?.user;
  }

  Future<bool> isEmailExists(String email) async {
    await _ensureInitialized();
    return _findAccountByEmail(_normalizeEmail(email)) != null;
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

    final normalizedName = name.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) {
      throw const AuthException('Vui lòng nhập họ và tên.');
    }
    if (!RegExp(_emailPattern).hasMatch(normalizedEmail)) {
      throw const AuthException('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (_accounts.any(
      (account) =>
          account.user.id != currentUser.id &&
          account.user.email == normalizedEmail,
    )) {
      throw const AuthException('Email này đã được tài khoản khác sử dụng.');
    }

    final accountIndex = _accounts.indexWhere(
      (account) => account.user.id == currentUser.id,
    );
    if (accountIndex < 0) {
      throw const AuthException('Không tìm thấy tài khoản đang đăng nhập.');
    }

    final updatedUser = currentUser.copyWith(
      name: normalizedName,
      email: normalizedEmail,
    );
    final updatedAccounts = [..._accounts];
    updatedAccounts[accountIndex] = updatedAccounts[accountIndex].copyWith(
      user: updatedUser,
    );
    await _saveAccounts(updatedAccounts);

    _accounts = updatedAccounts;
    _currentUser = updatedUser;
    return updatedUser;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _load() async {
    final accounts = await _readAccounts();

    final sessionUserId = await _storage.readString(
      StorageService.authSessionKey,
    );
    final currentAccount = accounts.where(
      (account) => account.user.id == sessionUserId,
    );
    final currentUser = currentAccount.isEmpty
        ? null
        : currentAccount.first.user;
    if (sessionUserId != null &&
        sessionUserId.isNotEmpty &&
        currentUser == null) {
      await _storage.writeString(StorageService.authSessionKey, '');
    }

    _accounts = accounts;
    _currentUser = currentUser;
  }

  Future<List<_StoredAccount>> _readAccounts() async {
    final accountsJson = await _storage.readString(
      StorageService.userAccountsKey,
    );
    if (accountsJson == null) return [];

    final decoded = jsonDecode(accountsJson);
    if (decoded is! List) {
      throw const FormatException('Danh sách tài khoản không hợp lệ.');
    }

    return decoded.map((value) {
      if (value is! Map) {
        throw const FormatException('Dữ liệu tài khoản không hợp lệ.');
      }
      return _StoredAccount.fromMap(Map<String, dynamic>.from(value));
    }).toList();
  }

  Future<void> _saveAccounts(List<_StoredAccount> accounts) {
    return _storage.writeString(
      StorageService.userAccountsKey,
      jsonEncode(accounts.map((account) => account.toMap()).toList()),
    );
  }

  _StoredAccount? _findAccountByEmail(String email) {
    for (final account in _accounts) {
      if (account.user.email == email) return account;
    }
    return null;
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static String _newId() =>
      base64Url.encode(_secureRandomBytes(16)).replaceAll('=', '');

  static bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }
}

class _StoredAccount {
  const _StoredAccount({
    required this.user,
    required this.salt,
    required this.passwordHash,
    required this.iterations,
  });

  final AuthUser user;
  final List<int> salt;
  final List<int> passwordHash;
  final int iterations;

  _StoredAccount copyWith({AuthUser? user}) {
    return _StoredAccount(
      user: user ?? this.user,
      salt: salt,
      passwordHash: passwordHash,
      iterations: iterations,
    );
  }

  factory _StoredAccount.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final name = map['name'];
    final email = map['email'];
    final createdAtValue = map['createdAt'];
    final rawSalt = map['salt'];
    final rawPasswordHash = map['passwordHash'];
    final algorithm = map['algorithm'];
    final iterations = map['iterations'];
    if (id is! String ||
        name is! String ||
        email is! String ||
        createdAtValue is! String ||
        rawSalt is! String ||
        rawPasswordHash is! String ||
        algorithm != _passwordHashAlgorithm ||
        iterations is! int ||
        iterations <= 0 ||
        iterations > 1000000) {
      throw const FormatException(
        'Dữ liệu tài khoản không hợp lệ.',
      );
    }

    final createdAt = DateTime.tryParse(createdAtValue);
    final salt = base64.decode(rawSalt);
    final passwordHash = base64.decode(rawPasswordHash);
    if (createdAt == null ||
        salt.length != _passwordSaltLength ||
        passwordHash.length != _passwordHashLength) {
      throw const FormatException(
        'Thông tin xác thực tài khoản không hợp lệ.',
      );
    }

    return _StoredAccount(
      user: AuthUser(
        id: id,
        name: name,
        email: email,
        createdAt: createdAt,
      ),
      salt: salt,
      passwordHash: passwordHash,
      iterations: iterations,
    );
  }

  Map<String, Object> toMap() => {
    ...user.toMap(),
    'salt': base64.encode(salt),
    'passwordHash': base64.encode(passwordHash),
    'algorithm': _passwordHashAlgorithm,
    'iterations': iterations,
  };
}
