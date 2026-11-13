import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const _databaseName = 'melody_music_media';
const _mediaStoreName = 'audio_files';

Future<void> initialize() async {
  await Future<void>.value();
}

Future<web.IDBDatabase>? _database;

Future<web.IDBDatabase> _openDatabase() {
  return _database ??= _openDatabaseOnce();
}

Future<web.IDBDatabase> _openDatabaseOnce() {
  final request = web.window.indexedDB.open(_databaseName, 1);
  final completer = Completer<web.IDBDatabase>();
  request.onupgradeneeded = ((web.Event _) {
    (request.result as web.IDBDatabase).createObjectStore(_mediaStoreName);
  }).toJS;
  request.onsuccess = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.complete(request.result as web.IDBDatabase);
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    _database = null;
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(request.error?.message ?? 'IndexedDB could not be opened.'),
      );
    }
  }).toJS;
  request.onblocked = ((web.Event _) {
    _database = null;
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('IndexedDB upgrade is blocked by another open tab.'),
      );
    }
  }).toJS;
  return completer.future;
}

Future<void> _waitForTransaction(web.IDBTransaction transaction) {
  final completer = Completer<void>();
  transaction.oncomplete = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  transaction.onabort = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(
          transaction.error?.message ?? 'IndexedDB transaction aborted.',
        ),
      );
    }
  }).toJS;
  transaction.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError(
          transaction.error?.message ?? 'IndexedDB transaction failed.',
        ),
      );
    }
  }).toJS;
  return completer.future;
}

Future<void> writeBinary(String key, Uint8List bytes) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_mediaStoreName.toJS, 'readwrite');
  final completed = _waitForTransaction(transaction);
  transaction.objectStore(_mediaStoreName).put(bytes.toJS, key.toJS);
  await completed;
}

Future<Uint8List?> readBinary(String key) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_mediaStoreName.toJS, 'readonly');
  final completed = _waitForTransaction(transaction);
  final request = transaction.objectStore(_mediaStoreName).get(key.toJS);
  final result = Completer<Uint8List?>();
  request.onsuccess = ((web.Event _) {
    final value = request.result;
    if (value == null || value.isUndefinedOrNull) {
      result.complete(null);
    } else {
      result.complete(Uint8List.fromList((value as JSUint8Array).toDart));
    }
  }).toJS;
  request.onerror = ((web.Event _) {
    result.completeError(
      StateError(request.error?.message ?? 'IndexedDB read failed.'),
    );
  }).toJS;
  try {
    final bytes = await result.future;
    await completed;
    return bytes;
  } on Object catch (error, stackTrace) {
    try {
      await completed;
    } on Object {
      // The request error is more specific than the transaction abort error.
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

Future<void> deleteBinary(String key) async {
  final database = await _openDatabase();
  final transaction = database.transaction(_mediaStoreName.toJS, 'readwrite');
  final completed = _waitForTransaction(transaction);
  transaction.objectStore(_mediaStoreName).delete(key.toJS);
  await completed;
}

Future<String?> resolveStoredAudio(String key) async {
  final bytes = await readBinary(key);
  if (bytes == null) return null;
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'audio/mpeg'),
  );
  return web.URL.createObjectURL(blob);
}

Future<void> releaseStoredAudio(String source) async {
  if (source.startsWith('blob:')) web.URL.revokeObjectURL(source);
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
