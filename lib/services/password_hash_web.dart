import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<List<int>> derivePasswordHash(
  String password,
  List<int> salt,
  int iterations,
) async {
  final subtle = web.window.crypto.subtle;
  final key = await subtle
      .importKey(
        'raw',
        Uint8List.fromList(utf8.encode(password)).toJS,
        {'name': 'PBKDF2'}.jsify()! as JSAny,
        false,
        <JSString>['deriveBits'.toJS].toJS,
      )
      .toDart;
  final algorithm = {
    'name': 'PBKDF2',
    'salt': Uint8List.fromList(salt).toJS,
    'iterations': iterations,
    'hash': 'SHA-256',
  }.jsify()! as JSAny;
  final derivedBits = await subtle.deriveBits(algorithm, key, 256).toDart;

  return List<int>.from(derivedBits.toDart.asUint8List());
}
