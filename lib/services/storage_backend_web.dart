import 'dart:convert';

import 'package:web/web.dart' as web;

Future<void> initialize() async {
  await Future<void>.value();
}

Future<String?> readString(String key) async {
  return web.window.localStorage.getItem(key);
}

Future<void> writeString(String key, String value) async {
  web.window.localStorage.setItem(key, value);
}

Future<String?> readLegacyString(String key) async {
  final value = _readLegacyValue(key);
  return value is String ? value : null;
}

Future<bool?> readLegacyBool(String key) async {
  final value = _readLegacyValue(key);
  return value is bool ? value : null;
}

Future<List<String>?> readLegacyStringList(String key) async {
  final value = _readLegacyValue(key);
  if (value is! List || value.any((item) => item is! String)) return null;
  return List<String>.from(value);
}

Object? _readLegacyValue(String key) {
  final value = web.window.localStorage.getItem('flutter.$key');
  if (value == null) return null;

  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}
