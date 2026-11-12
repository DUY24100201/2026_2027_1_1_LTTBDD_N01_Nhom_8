import 'package:flutter/foundation.dart';

import 'storage_backend_io.dart'
    if (dart.library.js_interop) 'storage_backend_web.dart'
    as backend;

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String userProfileKey = 'user_profile';
  static const String playlistsKey = 'playlists';
  static const String favoriteSongsKey = 'favorite_songs';
  static const String listeningHistoryKey = 'listening_history';
  static const String appSettingsKey = 'app_settings';

  Future<void>? _initialization;
  Map<String, Object>? _mockValues;

  Future<void> initialize() {
    if (_mockValues != null) return Future<void>.value();
    return _initialization ??= _initializeBackend();
  }

  Future<void> _initializeBackend() async {
    try {
      await backend.initialize();
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<String?> readString(String key) {
    return _access('đọc dữ liệu "$key"', () async {
      final values = _mockValues;
      if (values != null) return values[key] as String?;
      return backend.readString(key);
    });
  }

  Future<void> writeString(String key, String value) {
    return _access('lưu dữ liệu "$key"', () async {
      final values = _mockValues;
      if (values != null) {
        values[key] = value;
        return;
      }
      await backend.writeString(key, value);
    });
  }

  Future<String?> readLegacyString(String key) {
    return _access('đọc dữ liệu cũ "$key"', () async {
      final values = _mockValues;
      if (values != null) return values[key] as String?;
      return backend.readLegacyString(key);
    });
  }

  Future<bool?> readLegacyBool(String key) {
    return _access('đọc cài đặt cũ "$key"', () async {
      final values = _mockValues;
      if (values != null) return values[key] as bool?;
      return backend.readLegacyBool(key);
    });
  }

  Future<List<String>?> readLegacyStringList(String key) {
    return _access('đọc danh sách cũ "$key"', () async {
      final values = _mockValues;
      if (values != null) {
        final value = values[key];
        return value == null ? null : List<String>.from(value as List);
      }
      return backend.readLegacyStringList(key);
    });
  }

  Future<T> _access<T>(String action, Future<T> Function() operation) async {
    try {
      await initialize();
      return await operation();
    } catch (error, stackTrace) {
      if (error is StorageException) rethrow;
      Error.throwWithStackTrace(StorageException(action, error), stackTrace);
    }
  }

  @visibleForTesting
  void setMockInitialValues(Map<String, Object> values) {
    _mockValues = Map<String, Object>.from(values);
    _initialization = null;
  }
}

class StorageException implements Exception {
  const StorageException(this.action, this.cause);

  final String action;
  final Object cause;

  @override
  String toString() => 'Không thể $action: $cause';
}
