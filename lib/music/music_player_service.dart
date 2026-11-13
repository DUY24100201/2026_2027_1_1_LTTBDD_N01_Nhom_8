import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/music/song_library_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

class MusicPlayerService {
  MusicPlayerService._();

  static final MusicPlayerService instance = MusicPlayerService._();

  final AudioPlayer player = AudioPlayer();

  List<Song> queue = [];
  int currentIndex = -1;

  bool isShuffle = false;
  LoopMode loopMode = LoopMode.off;
  static const String _legacyShuffleSettingKey = 'melody_shuffle_enabled_v1';
  static const String _legacyRepeatSettingKey = 'melody_repeat_mode_v1';

  bool _settingsLoaded = false;
  Map<String, Object?> _settings = {};
  String? _activeStoredAudioSource;
  Timer? _sleepTimer;
  DateTime? _sleepTimerDeadline;
  final StreamController<void> _sleepTimerCompleted =
      StreamController<void>.broadcast();
  final StreamController<Object> _sleepTimerErrors =
      StreamController<Object>.broadcast();

  Song? get currentSong {
    if (currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
    return queue[currentIndex];
  }

  DateTime? get sleepTimerDeadline => _sleepTimerDeadline;
  Stream<void> get sleepTimerCompleted => _sleepTimerCompleted.stream;
  Stream<Object> get sleepTimerErrors => _sleepTimerErrors.stream;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> loadPlaybackSettings() async {
    if (_settingsLoaded) return;

    final storage = StorageService.instance;
    final rawSettings = await storage.readString(StorageService.appSettingsKey);
    var loadedSettings = <String, Object?>{};
    bool? legacyShuffle;
    String? legacyRepeat;

    if (rawSettings != null) {
      final decoded = jsonDecode(rawSettings);
      if (decoded is! Map) {
        throw const FormatException('Dữ liệu cài đặt ứng dụng không hợp lệ.');
      }
      loadedSettings = Map<String, Object?>.from(decoded);
    } else {
      legacyShuffle = await storage.readLegacyBool(_legacyShuffleSettingKey);
      legacyRepeat = await storage.readLegacyString(_legacyRepeatSettingKey);
      if (legacyShuffle != null || legacyRepeat != null) {
        loadedSettings = {'shuffle': ?legacyShuffle, 'repeat': ?legacyRepeat};
        await storage.writeString(
          StorageService.appSettingsKey,
          jsonEncode(loadedSettings),
        );
      }
    }

    final storedShuffle = loadedSettings['shuffle'];
    if (storedShuffle != null && storedShuffle is! bool) {
      throw const FormatException('Cài đặt phát ngẫu nhiên không hợp lệ.');
    }
    final storedRepeatMode = loadedSettings['repeat'] ?? legacyRepeat;
    if (storedRepeatMode != null && storedRepeatMode is! String) {
      throw const FormatException('Cài đặt lặp lại không hợp lệ.');
    }
    final loadedLoopMode = switch (storedRepeatMode) {
      'one' => LoopMode.one,
      'all' => LoopMode.all,
      _ => LoopMode.off,
    };

    if (loadedLoopMode != loopMode) {
      await player.setLoopMode(loadedLoopMode);
    }

    isShuffle = storedShuffle as bool? ?? legacyShuffle ?? false;
    loopMode = loadedLoopMode;
    _settings = loadedSettings;
    _settingsLoaded = true;
  }

  Future<void> setQueue(
    List<Song> songs, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    if (songs.isEmpty) return;

    queue = List<Song>.from(songs);
    currentIndex = startIndex.clamp(0, queue.length - 1);

    await playCurrent(autoplay: autoplay);
  }

  Future<void> playCurrent({bool autoplay = true}) async {
    final song = currentSong;

    if (song == null) return;

    if (song.audioUrl.trim().isEmpty) {
      throw Exception('Bài hát chưa có đường dẫn MP3.');
    }

    if (song.audioUrl.startsWith('data:audio/mpeg;base64,')) {
      final encodedAudio = song.audioUrl.substring(
        'data:audio/mpeg;base64,'.length,
      );
      final audioBytes = base64Decode(encodedAudio);
      if (kIsWeb) {
        await player.setUrl(song.audioUrl);
      } else {
        await player.setAudioSource(_MemoryAudioSource(audioBytes));
      }
      await _releasePreviousStoredAudio();
    } else if (SongLibraryService.isStoredAudioReference(song.audioUrl)) {
      final key = SongLibraryService.audioStorageKey(song.audioUrl);
      if (key == null) {
        throw const FormatException('Tham chiếu tệp MP3 không hợp lệ.');
      }
      final source = await StorageService.instance.resolveStoredAudio(key);
      if (source == null) {
        throw StateError('Không tìm thấy tệp MP3 đã lưu cho bài hát này.');
      }
      if (kIsWeb) {
        await player.setUrl(source);
      } else {
        await player.setFilePath(source);
      }
      await _releasePreviousStoredAudio();
      _activeStoredAudioSource = source;
    } else {
      await player.setUrl(song.audioUrl);
      await _releasePreviousStoredAudio();
    }

    if (autoplay) {
      await player.play();
    }
  }

  Future<void> playSong(Song song, {List<Song>? songs}) async {
    if (songs != null && songs.isNotEmpty) {
      final index = songs.indexWhere((item) => item.id == song.id);

      await setQueue(songs, startIndex: index >= 0 ? index : 0);
      return;
    }

    queue = [song];
    currentIndex = 0;

    await playCurrent();
  }

  Future<void> play() async {
    if (currentSong == null) return;

    if (player.processingState == ProcessingState.idle) {
      await playCurrent();
    } else {
      await player.play();
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    if (currentSong == null) return;
    await player.stop();
    await player.seek(Duration.zero);
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> next() async {
    if (queue.isEmpty) return;

    if (isShuffle && queue.length > 1) {
      final random = DateTime.now().microsecondsSinceEpoch % queue.length;
      currentIndex = random == currentIndex
          ? (random + 1) % queue.length
          : random;
    } else {
      currentIndex = (currentIndex + 1) % queue.length;
    }

    await playCurrent();
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;

    final position = player.position;

    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    currentIndex = (currentIndex - 1 + queue.length) % queue.length;

    await playCurrent();
  }

  Future<void> toggleShuffle() async {
    await loadPlaybackSettings();
    final updated = !isShuffle;
    final updatedSettings = {
      ..._settings,
      'shuffle': updated,
      'repeat': loopMode.name,
    };
    await StorageService.instance.writeString(
      StorageService.appSettingsKey,
      jsonEncode(updatedSettings),
    );
    _settings = updatedSettings;
    isShuffle = updated;
  }

  Future<void> cycleRepeatMode() async {
    final updated = switch (loopMode) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    await setRepeatMode(updated);
  }

  Future<void> setRepeatMode(LoopMode mode) async {
    await loadPlaybackSettings();
    final previousMode = loopMode;
    final updatedSettings = {
      ..._settings,
      'shuffle': isShuffle,
      'repeat': mode.name,
    };
    await StorageService.instance.writeString(
      StorageService.appSettingsKey,
      jsonEncode(updatedSettings),
    );

    try {
      await player.setLoopMode(mode);
    } catch (error, stackTrace) {
      final restoredSettings = {
        ..._settings,
        'shuffle': isShuffle,
        'repeat': previousMode.name,
      };
      try {
        await StorageService.instance.writeString(
          StorageService.appSettingsKey,
          jsonEncode(restoredSettings),
        );
      } catch (restoreError) {
        Error.throwWithStackTrace(
          StateError(
            'Không thể khôi phục cài đặt lặp lại đã lưu: $restoreError',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    _settings = updatedSettings;
    loopMode = mode;
  }

  void startSleepTimer(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive.');
    }

    cancelSleepTimer();
    _sleepTimerDeadline = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      unawaited(_stopAfterSleepTimer());
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDeadline = null;
  }

  Future<void> _stopAfterSleepTimer() async {
    _sleepTimer = null;
    _sleepTimerDeadline = null;
    try {
      await player.stop();
      _sleepTimerCompleted.add(null);
    } catch (error, stackTrace) {
      _sleepTimerErrors.addError(error, stackTrace);
    }
  }

  Future<void> _releasePreviousStoredAudio() async {
    final previous = _activeStoredAudioSource;
    _activeStoredAudioSource = null;
    if (previous != null) {
      await StorageService.instance.releaseStoredAudio(previous);
    }
  }

  Future<void> dispose() async {
    cancelSleepTimer();
    await _releasePreviousStoredAudio();
    await _sleepTimerCompleted.close();
    await _sleepTimerErrors.close();
    await player.dispose();
  }
}

// ignore: experimental_member_use
class _MemoryAudioSource extends StreamAudioSource {
  _MemoryAudioSource(this._bytes);

  final Uint8List _bytes;

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? _bytes.length;
    if (rangeStart < 0 || rangeEnd < rangeStart || rangeEnd > _bytes.length) {
      throw RangeError('Audio byte range is outside the stored file.');
    }
    // ignore: experimental_member_use
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      stream: Stream.value(_bytes.sublist(rangeStart, rangeEnd)),
      contentType: 'audio/mpeg',
    );
  }
}
