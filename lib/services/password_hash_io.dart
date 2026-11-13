import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

Future<List<int>> derivePasswordHash(
  String password,
  List<int> salt,
  int iterations,
) async {
  final hmac = crypto.Hmac(crypto.sha256, utf8.encode(password));
  final firstBlock = Uint8List(salt.length + 4)
    ..setRange(0, salt.length, salt)
    ..setRange(salt.length, salt.length + 4, const [0, 0, 0, 1]);
  var currentBlock = hmac.convert(firstBlock).bytes;
  final derivedKey = Uint8List.fromList(currentBlock);

  for (var iteration = 1; iteration < iterations; iteration++) {
    currentBlock = hmac.convert(currentBlock).bytes;
    for (var index = 0; index < derivedKey.length; index++) {
      derivedKey[index] ^= currentBlock[index];
    }
    if (iteration % 2048 == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  return derivedKey;
}
