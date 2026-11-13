import 'dart:convert';
import 'dart:math';

import 'package:lttbdd_nhom8/auth/models/password_digest.dart';
import 'package:lttbdd_nhom8/services/password_hash_io.dart'
    if (dart.library.js_interop) 'package:lttbdd_nhom8/services/password_hash_web.dart'
    as password_hash;

export 'package:lttbdd_nhom8/auth/models/password_digest.dart';

const int passwordHashIterations = 600000;

class PasswordHashService {
  Future<PasswordDigest> create(String password) async {
    final salt = _secureRandomBytes(16);
    final hash = await password_hash.derivePasswordHash(
      password,
      salt,
      passwordHashIterations,
    );
    return PasswordDigest(
      salt: salt,
      hash: hash,
      iterations: passwordHashIterations,
    );
  }

  Future<bool> verify(String password, PasswordDigest digest) async {
    final hash = await password_hash.derivePasswordHash(
      password,
      digest.salt,
      digest.iterations,
    );
    return _constantTimeEquals(hash, digest.hash);
  }

  static List<int> secureRandomBytes(int length) => _secureRandomBytes(length);

  static String newId() =>
      base64Url.encode(_secureRandomBytes(16)).replaceAll('=', '');

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }
}
