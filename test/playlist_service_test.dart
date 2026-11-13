import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lttbdd_nhom8/music/models/music_playlist.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/music/playlist_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

void main() {
  test('playlist changes and songs are persisted locally', () async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({});

    final service = PlaylistService.instance;
    await service.load();

    final playlist = await service.create(
      name: 'Chill',
      description: 'Nhạc thư giãn',
      coverColor: const Color(0xFF455A88),
      coverIcon: Icons.nightlight_round,
    );
    const firstSong = Song(
      id: 'song-1',
      name: 'Bài hát đầu tiên',
      artist: 'Ca sĩ',
      audioUrl: 'https://example.com/song-1.mp3',
      duration: Duration(minutes: 3, seconds: 12),
      coverColor: Color(0xFFE5A65B),
      coverIcon: Icons.music_note,
    );
    const secondSong = Song(
      id: 'song-2',
      name: 'Bài hát thứ hai',
      artist: 'Ca sĩ khác',
    );

    expect(await service.addSong(playlist.id, firstSong), isTrue);
    expect(await service.addSong(playlist.id, firstSong), isFalse);
    await service.addSong(playlist.id, secondSong);
    await service.reorderSong(playlist.id, 0, 1);

    final updatedPlaylist = service.findById(playlist.id)!;
    expect(updatedPlaylist.songs.map((song) => song.id), ['song-2', 'song-1']);

    final stored = jsonDecode(
      (await storage.readString(StorageService.playlistsKey))!,
    ) as List<dynamic>;
    final restored = MusicPlaylist.fromMap(
      Map<String, dynamic>.from(stored.single as Map),
    );
    expect(restored.name, 'Chill');
    expect(restored.description, 'Nhạc thư giãn');
    expect(restored.songs.last.audioUrl, firstSong.audioUrl);
    expect(restored.songs.last.duration, firstSong.duration);
    expect(restored.coverColor.toARGB32(), playlist.coverColor.toARGB32());

    await service.removeSong(playlist.id, 'song-2');
    await service.delete(playlist.id);
    expect(service.playlists, isEmpty);
    expect(await storage.readString(StorageService.playlistsKey), '[]');
  });
}
