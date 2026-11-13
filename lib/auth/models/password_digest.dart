import 'dart:convert';

const String passwordHashAlgorithm = 'pbkdf2-hmac-sha256';
const int _passwordSaltLength = 16;
const int _passwordHashLength = 32;

class PasswordDigest {
  const PasswordDigest({
    required this.salt,
    required this.hash,
    required this.iterations,
  });

  final List<int> salt;
  final List<int> hash;
  final int iterations;

  factory PasswordDigest.fromMap(Map<String, dynamic> map) {
    final rawSalt = map['salt'];
    final rawHash = map['passwordHash'];
    final algorithm = map['algorithm'];
    final iterations = map['iterations'];
    if (rawSalt is! String ||
        rawHash is! String ||
        algorithm != passwordHashAlgorithm ||
        iterations is! int ||
        iterations <= 0 ||
        iterations > 1000000) {
      throw const FormatException('Thông tin xác thực tài khoản không hợp lệ.');
    }

    final salt = base64.decode(rawSalt);
    final hash = base64.decode(rawHash);
    if (salt.length != _passwordSaltLength ||
        hash.length != _passwordHashLength) {
      throw const FormatException('Thông tin xác thực tài khoản không hợp lệ.');
    }

    return PasswordDigest(salt: salt, hash: hash, iterations: iterations);
  }

  Map<String, Object> toMap() => {
    'salt': base64.encode(salt),
    'passwordHash': base64.encode(hash),
    'algorithm': passwordHashAlgorithm,
    'iterations': iterations,
  };
}
