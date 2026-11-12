import 'package:material_ui/material_ui.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import '../models/song.dart';

class MusicPlayerService {
  MusicPlayerService._();

  static final MusicPlayerService instance = MusicPlayerService._();

  final AudioPlayer player = AudioPlayer();

  List<Song> queue = [];
  int currentIndex = -1;

  bool isShuffle = false;
  LoopMode loopMode = LoopMode.off;

  Song? get currentSong {
    if (currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
    return queue[currentIndex];
  }

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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

    await player.setUrl(song.audioUrl);

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
    isShuffle = !isShuffle;
  }

  Future<void> cycleRepeatMode() async {
    if (loopMode == LoopMode.off) {
      loopMode = LoopMode.one;
    } else if (loopMode == LoopMode.one) {
      loopMode = LoopMode.all;
    } else {
      loopMode = LoopMode.off;
    }

    await player.setLoopMode(loopMode);
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
