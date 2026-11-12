import 'package:shared_preferences/shared_preferences.dart';

SharedPreferencesAsync? _preferences;

Future<void> initialize() async {
  _preferences ??= SharedPreferencesAsync();
}

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
