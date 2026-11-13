import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

class SongLibraryService extends ChangeNotifier {
  SongLibraryService({StorageService? storage, AuthService? authService})
    : _storage = storage ?? StorageService.instance,
      _auth = authService ?? AuthService.instance;

  static final SongLibraryService instance = SongLibraryService();

  static const String storedAudioUriPrefix = 'melody-audio://';
  static const String _legacyAudioDataUriPrefix = 'data:audio/mpeg;base64,';

  static const List<Song> _legacyCatalog = [
    Song(
      id: 'ánh nắng của anh',
      name: 'Ánh Nắng Của Anh',
      artist: 'Đức Phúc',
      album: 'Ánh Nắng Của Anh',
      duration: Duration(minutes: 4, seconds: 15),
      coverColor: Color(0xFFE5A65B),
      coverIcon: Icons.wb_sunny_rounded,
    ),
    Song(
      id: 'thấy em là thấy',
      name: 'Thấy Em Là Thấy',
      artist: 'Phạm Việt Thắng',
      album: 'Thấy Em Là Thấy',
      duration: Duration(minutes: 3, seconds: 45),
      coverColor: Color(0xFFD87885),
      coverIcon: Icons.favorite_rounded,
    ),
    Song(
      id: 'có hẹn với thanh xuân',
      name: 'Có Hẹn Với Thanh Xuân',
      artist: 'MONSTAR',
      album: 'Có Hẹn Với Thanh Xuân',
      duration: Duration(minutes: 4, seconds: 20),
      coverColor: Color(0xFF7195C8),
      coverIcon: Icons.cloud_rounded,
    ),
    Song(
      id: 'về nhà',
      name: 'Về Nhà',
      artist: 'Chillies',
      album: 'Qua Khung Cửa Sổ',
      duration: Duration(minutes: 3, seconds: 52),
      coverColor: Color(0xFF7A9A85),
      coverIcon: Icons.home_rounded,
    ),
    Song(
      id: 'đổi thay',
      name: 'Đổi Thay',
      artist: 'Hồ Quang Hiếu',
      album: 'Đổi Thay',
      duration: Duration(minutes: 4, seconds: 5),
      coverColor: Color(0xFF987BC1),
      coverIcon: Icons.music_note_rounded,
    ),
  ];

  final StorageService _storage;
  final AuthService _auth;
  List<Song>? _songs;

  static void validateMp3({
    required String fileName,
    required List<int> bytes,
  }) {
    if (!fileName.toLowerCase().endsWith('.mp3')) {
      throw const FormatException('Vui lòng chọn file có đuôi .mp3.');
    }
    if (bytes.isEmpty) {
      throw const FormatException('File MP3 rỗng hoặc không đọc được.');
    }
    final hasId3Header =
        bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33;
    var audioStart = 0;
    if (hasId3Header) {
      if (bytes.length < 10 ||
          bytes.sublist(6, 10).any((byte) => (byte & 0x80) != 0)) {
        throw const FormatException('File đã chọn không có định dạng MP3.');
      }
      final tagSize =
          (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
      audioStart = 10 + tagSize;
    }
    var hasMpegFrame = false;
    if (bytes.length >= 4 && audioStart <= bytes.length - 4) {
      final lastStart = (audioStart + 4096).clamp(audioStart, bytes.length - 4);
      for (var index = audioStart; index <= lastStart; index++) {
        final first = bytes[index];
        final second = bytes[index + 1];
        final third = bytes[index + 2];
        final version = (second >> 3) & 0x03;
        final layer = (second >> 1) & 0x03;
        final bitrate = (third >> 4) & 0x0F;
        final sampleRate = (third >> 2) & 0x03;
        if (first == 0xFF &&
            (second & 0xE0) == 0xE0 &&
            version != 0x01 &&
            layer != 0 &&
            bitrate != 0 &&
            bitrate != 0x0F &&
            sampleRate != 0x03) {
          hasMpegFrame = true;
          break;
        }
      }
    }
    if (!hasMpegFrame) {
      throw const FormatException('File đã chọn không có định dạng MP3.');
    }
    final audioBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (readMp3Duration(audioBytes) == Duration.zero) {
      throw const FormatException(
        'File MP3 không có frame âm thanh hoàn chỉnh.',
      );
    }
  }

  static bool isStoredAudioReference(String audioUrl) =>
      audioUrl.startsWith(storedAudioUriPrefix);

  static String? audioStorageKey(String audioUrl) {
    if (!isStoredAudioReference(audioUrl)) return null;
    final key = audioUrl.substring(storedAudioUriPrefix.length);
    return RegExp(r'^song_audio_[a-zA-Z0-9_-]+$').hasMatch(key) ? key : null;
  }

  Future<List<Song>> readSongs() async {
    await _load(force: true);
    return List<Song>.unmodifiable(_songs!);
  }

  Future<Song> addSong(
    Song song, {
    required Uint8List audioBytes,
    required String audioFileName,
  }) async {
    _auth.requireAdmin();
    await _load(force: true);
    _validateSong(song);
    validateMp3(fileName: audioFileName, bytes: audioBytes);
    if (_songs!.any((item) => item.id == song.id)) {
      throw const SongLibraryException('Bài hát này đã tồn tại.');
    }
    final key = _newAudioKey(song.id);
    await _storeNewAudio(key, audioBytes);
    final normalizedSong = _normalizeSong(
      _copySong(song, audioUrl: '$storedAudioUriPrefix$key'),
    );
    try {
      await _save([..._songs!, normalizedSong]);
    } catch (error, stackTrace) {
      try {
        await _storage.deleteBinary(key);
      } catch (cleanupError) {
        throw SongLibraryException(
          'Không thể lưu bài hát và không thể dọn tệp MP3: $cleanupError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    notifyListeners();
    return normalizedSong;
  }

  Future<Song> updateSong(
    Song song, {
    Uint8List? audioBytes,
    String? audioFileName,
  }) async {
    _auth.requireAdmin();
    await _load(force: true);
    final index = _songs!.indexWhere((item) => item.id == song.id);
    if (index < 0) {
      throw const SongLibraryException('Không tìm thấy bài hát cần sửa.');
    }
    final previous = _songs![index];
    _validateSong(song);
    String? newAudioKey;
    var audioUrl = previous.audioUrl;
    if (audioBytes != null) {
      if (audioFileName == null) {
        throw const SongLibraryException('Thiếu tên file MP3 đã chọn.');
      }
      validateMp3(fileName: audioFileName, bytes: audioBytes);
      newAudioKey = _newAudioKey(song.id);
      await _storeNewAudio(newAudioKey, audioBytes);
      audioUrl = '$storedAudioUriPrefix$newAudioKey';
    }
    final updated = [..._songs!];
    updated[index] = _normalizeSong(_copySong(song, audioUrl: audioUrl));
    try {
      await _save(updated);
    } catch (error, stackTrace) {
      if (newAudioKey != null) {
        try {
          await _storage.deleteBinary(newAudioKey);
        } catch (cleanupError) {
          throw SongLibraryException(
            'Không thể cập nhật bài hát và không thể dọn tệp MP3 mới: $cleanupError',
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    notifyListeners();
    if (newAudioKey != null) {
      final previousKey = audioStorageKey(previous.audioUrl);
      if (previousKey != null) {
        try {
          await _storage.deleteBinary(previousKey);
        } catch (error) {
          throw SongLibraryException(
            'Bài hát đã được cập nhật nhưng không thể dọn tệp MP3 cũ: $error',
          );
        }
      }
    }
    return updated[index];
  }

  Future<void> deleteSong(String songId) async {
    _auth.requireAdmin();
    await _load(force: true);
    final updated = _songs!.where((song) => song.id != songId).toList();
    if (updated.length == _songs!.length) {
      throw const SongLibraryException('Không tìm thấy bài hát cần xóa.');
    }
    final deleted = _songs!.firstWhere((song) => song.id == songId);
    await _save(updated);
    notifyListeners();
    final key = audioStorageKey(deleted.audioUrl);
    if (key != null) {
      try {
        await _storage.deleteBinary(key);
      } catch (error) {
        throw SongLibraryException(
          'Bài hát đã bị xóa khỏi thư viện nhưng không thể dọn tệp MP3: $error',
        );
      }
    }
  }

  Future<void> _load({bool force = false}) async {
    if (!force && _songs != null) return;
    final raw = await _storage.readString(StorageService.sharedSongsKey);
    if (raw == null) {
      _songs = _legacyCatalog;
      await _save(_songs!);
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Danh sách bài hát chung không hợp lệ.');
    }
    final songs = decoded.map((value) {
      if (value is! Map) {
        throw const FormatException('Dữ liệu bài hát chung không hợp lệ.');
      }
      return Song.fromMap(Map<String, dynamic>.from(value), '');
    }).toList();
    var migrated = false;
    final migratedSongs = <Song>[];
    for (final song in songs) {
      if (!song.audioUrl.startsWith(_legacyAudioDataUriPrefix)) {
        migratedSongs.add(song);
        continue;
      }
      try {
        final bytes = base64Decode(
          song.audioUrl.substring(_legacyAudioDataUriPrefix.length),
        );
        if (bytes.isEmpty) {
          migratedSongs.add(song);
          continue;
        }
        final key = _newAudioKey(song.id);
        await _storeNewAudio(key, bytes);
        migratedSongs.add(
          _copySong(song, audioUrl: '$storedAudioUriPrefix$key'),
        );
        migrated = true;
      } on FormatException {
        migratedSongs.add(song);
      }
    }
    _songs = migratedSongs;
    if (migrated) await _save(migratedSongs);
  }

  static Duration readMp3Duration(Uint8List bytes) {
    var offset = 0;
    if (bytes.length >= 10 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      final tagSize =
          (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
      offset = 10 + tagSize + ((bytes[5] & 0x10) != 0 ? 10 : 0);
    }

    final audioEnd =
        bytes.length >= 128 &&
            bytes[bytes.length - 128] == 0x54 &&
            bytes[bytes.length - 127] == 0x41 &&
            bytes[bytes.length - 126] == 0x47
        ? bytes.length - 128
        : bytes.length;
    var totalSamples = 0;
    var sampleRate = 0;

    while (offset <= audioEnd - 4) {
      final first = bytes[offset];
      final second = bytes[offset + 1];
      final third = bytes[offset + 2];
      final version = (second >> 3) & 0x03;
      final layer = (second >> 1) & 0x03;
      final bitrateIndex = (third >> 4) & 0x0F;
      final sampleRateIndex = (third >> 2) & 0x03;
      if (first != 0xFF ||
          (second & 0xE0) != 0xE0 ||
          version == 0x01 ||
          layer == 0 ||
          bitrateIndex == 0 ||
          bitrateIndex == 0x0F ||
          sampleRateIndex == 0x03) {
        offset++;
        continue;
      }

      final mpeg1 = version == 0x03;
      const baseSampleRates = [44100, 48000, 32000];
      final frameSampleRate =
          baseSampleRates[sampleRateIndex] ~/
          switch (version) {
            0x02 => 2,
            0x00 => 4,
            _ => 1,
          };
      final bitrateTable = mpeg1
          ? switch (layer) {
              0x03 => const [
                0,
                32,
                64,
                96,
                128,
                160,
                192,
                224,
                256,
                288,
                320,
                352,
                384,
                416,
                448,
                0,
              ],
              0x02 => const [
                0,
                32,
                48,
                56,
                64,
                80,
                96,
                112,
                128,
                160,
                192,
                224,
                256,
                320,
                384,
                0,
              ],
              _ => const [
                0,
                32,
                40,
                48,
                56,
                64,
                80,
                96,
                112,
                128,
                160,
                192,
                224,
                256,
                320,
                0,
              ],
            }
          : switch (layer) {
              0x03 => const [
                0,
                32,
                48,
                56,
                64,
                80,
                96,
                112,
                128,
                144,
                160,
                176,
                192,
                224,
                256,
                0,
              ],
              _ => const [
                0,
                8,
                16,
                24,
                32,
                40,
                48,
                56,
                64,
                80,
                96,
                112,
                128,
                144,
                160,
                0,
              ],
            };
      final bitrate = bitrateTable[bitrateIndex] * 1000;
      final padding = (third >> 1) & 1;
      final frameLength = layer == 0x03
          ? ((12 * bitrate ~/ frameSampleRate) + padding) * 4
          : ((mpeg1 || layer != 0x01 ? 144 : 72) * bitrate ~/ frameSampleRate) +
                padding;
      if (frameLength < 4 || offset + frameLength > audioEnd) {
        offset++;
        continue;
      }

      totalSamples += layer == 0x03
          ? 384
          : (mpeg1 || layer != 0x01 ? 1152 : 576);
      sampleRate = frameSampleRate;
      offset += frameLength;
    }

    if (totalSamples == 0 || sampleRate == 0) return Duration.zero;
    return Duration(milliseconds: (totalSamples * 1000 / sampleRate).round());
  }

  Future<void> _save(List<Song> songs) async {
    await _storage.writeString(
      StorageService.sharedSongsKey,
      jsonEncode(songs.map((song) => song.toMap()).toList()),
    );
    _songs = songs;
  }

  Song _normalizeSong(Song song) => Song(
    id: song.id.trim(),
    name: song.name.trim(),
    artist: song.artist.trim(),
    album: song.album.trim(),
    genre: song.genre.trim(),
    audioUrl: song.audioUrl.trim(),
    coverUrl: song.coverUrl.trim(),
    duration: song.duration,
    playCount: song.playCount,
    coverColor: song.coverColor,
    coverIcon: song.coverIcon,
  );

  Song _copySong(Song song, {required String audioUrl}) => Song(
    id: song.id,
    name: song.name,
    artist: song.artist,
    album: song.album,
    genre: song.genre,
    audioUrl: audioUrl,
    coverUrl: song.coverUrl,
    duration: song.duration,
    playCount: song.playCount,
    coverColor: song.coverColor,
    coverIcon: song.coverIcon,
  );

  String _newAudioKey(String songId) {
    final encodedId = base64Url
        .encode(utf8.encode(songId.trim()))
        .replaceAll('=', '');
    return 'song_audio_${encodedId}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _storeNewAudio(String key, Uint8List bytes) async {
    try {
      await _storage.writeBinary(key, bytes);
    } catch (error, stackTrace) {
      try {
        await _storage.deleteBinary(key);
      } catch (cleanupError) {
        throw SongLibraryException(
          'Không thể lưu tệp MP3 và không thể dọn tệp chưa hoàn chỉnh: $cleanupError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _validateSong(Song song) {
    if (song.id.trim().isEmpty ||
        song.name.trim().isEmpty ||
        song.artist.trim().isEmpty) {
      throw const SongLibraryException('Tên bài hát và ca sĩ là bắt buộc.');
    }
  }
}

class SongLibraryException implements Exception {
  const SongLibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}
