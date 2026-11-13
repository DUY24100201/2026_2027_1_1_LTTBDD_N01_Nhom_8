import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferencesAsync? _preferences;
Directory? _mediaDirectory;

Future<void> initialize() async {
  _preferences ??= SharedPreferencesAsync();
}

Future<File> _mediaFile(String key) async {
  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
    throw ArgumentError.value(key, 'key', 'Invalid media storage key.');
  }
  final directory = _mediaDirectory ??= Directory(
    '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}melody_media',
  );
  await directory.create(recursive: true);
  return File('${directory.path}${Platform.pathSeparator}$key.mp3');
}

Future<void> writeBinary(String key, Uint8List bytes) async {
  final file = await _mediaFile(key);
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> readBinary(String key) async {
  final file = await _mediaFile(key);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> deleteBinary(String key) async {
  final file = await _mediaFile(key);
  if (await file.exists()) await file.delete();
}

Future<String?> resolveStoredAudio(String key) async {
  final file = await _mediaFile(key);
  return await file.exists() ? file.path : null;
}

Future<void> releaseStoredAudio(String source) => Future<void>.value();

Future<String?> readString(String key) async {
  return _preferences!.getString(key);
}

Future<void> writeString(String key, String value) {
  return _preferences!.setString(key, value);
}

Future<String?> readLegacyString(String key) async {
  return _preferences!.getString('flutter.$key');
}

Future<bool?> readLegacyBool(String key) async {
  return _preferences!.getBool('flutter.$key');
}

Future<List<String>?> readLegacyStringList(String key) async {
  return _preferences!.getStringList('flutter.$key');
}
