import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/music/models/music_playlist.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

class PlaylistService {
  PlaylistService._();

  static final PlaylistService instance = PlaylistService._();

  static const String _storageKey = StorageService.playlistsKey;
  static const String _legacyStorageKey = 'melody_playlists_v1';

  List<MusicPlaylist> _playlists = [];
  bool _loaded = false;

  List<MusicPlaylist> get playlists => List.unmodifiable(_playlists);

  Future<void> load() async {
    if (_loaded) return;

    final storage = StorageService.instance;
    var raw = await storage.readString(_storageKey);
    var readLegacyValue = false;
    if (raw == null) {
      raw = await storage.readLegacyString(_legacyStorageKey);
      readLegacyValue = raw != null;
    }

    final loadedPlaylists = <MusicPlaylist>[];
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Dữ liệu playlist không hợp lệ.');
      }

      loadedPlaylists.addAll(
        decoded.whereType<Map>().map(
          (item) => MusicPlaylist.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    }

    if (readLegacyValue) {
      await storage.writeString(_storageKey, raw!);
    }

    _playlists = loadedPlaylists;
    _loaded = true;
  }

  MusicPlaylist? findById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  Future<MusicPlaylist> create({
    required String name,
    required String description,
    required Color coverColor,
    required IconData coverIcon,
  }) async {
    await load();
    final playlist = MusicPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description.trim(),
      coverColor: coverColor,
      coverIcon: coverIcon,
    );
    await _save([..._playlists, playlist]);
    return playlist;
  }

  Future<void> update(MusicPlaylist playlist) async {
    await load();
    final index = _playlists.indexWhere((item) => item.id == playlist.id);
    if (index < 0) throw StateError('Không tìm thấy playlist cần sửa.');

    final updated = [..._playlists];
    updated[index] = playlist;
    await _save(updated);
  }

  Future<void> delete(String id) async {
    await load();
    final updated = _playlists.where((item) => item.id != id).toList();
    if (updated.length == _playlists.length) {
      throw StateError('Không tìm thấy playlist cần xóa.');
    }
    await _save(updated);
  }

  Future<bool> addSong(String playlistId, Song song) async {
    await load();
    final playlist = findById(playlistId);
    if (playlist == null) throw StateError('Không tìm thấy playlist.');
    if (playlist.songs.any((item) => item.id == song.id)) return false;

    await update(playlist.copyWith(songs: [...playlist.songs, song]));
    return true;
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await load();
    final playlist = findById(playlistId);
    if (playlist == null) throw StateError('Không tìm thấy playlist.');

    await update(
      playlist.copyWith(
        songs: playlist.songs.where((song) => song.id != songId).toList(),
      ),
    );
  }

  Future<void> reorderSong(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    await load();
    final playlist = findById(playlistId);
    if (playlist == null) throw StateError('Không tìm thấy playlist.');

    final songs = [...playlist.songs];
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    await update(playlist.copyWith(songs: songs));
  }

  Future<void> _save(List<MusicPlaylist> playlists) async {
    await StorageService.instance.writeString(
      _storageKey,
      jsonEncode(playlists.map((playlist) => playlist.toMap()).toList()),
    );

    _playlists = playlists;
    _loaded = true;
  }
}
