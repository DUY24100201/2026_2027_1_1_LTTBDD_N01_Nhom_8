import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';

class MusicPlaylist {
  final String id;
  final String name;
  final String description;
  final Color coverColor;
  final IconData coverIcon;
  final List<Song> songs;

  const MusicPlaylist({
    required this.id,
    required this.name,
    this.description = '',
    this.coverColor = AppColors.primary,
    this.coverIcon = Icons.queue_music_rounded,
    this.songs = const [],
  });

  MusicPlaylist copyWith({
    String? name,
    String? description,
    Color? coverColor,
    IconData? coverIcon,
    List<Song>? songs,
  }) {
    return MusicPlaylist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverColor: coverColor ?? this.coverColor,
      coverIcon: coverIcon ?? this.coverIcon,
      songs: songs ?? this.songs,
    );
  }

  factory MusicPlaylist.fromMap(Map<String, dynamic> map) {
    final rawSongs = map['songs'];
    final songs = rawSongs is List
        ? rawSongs
              .whereType<Map>()
              .map((song) => Song.fromMap(Map<String, dynamic>.from(song), ''))
              .toList()
        : <Song>[];

    return MusicPlaylist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      coverColor: Color(
        (map['coverColor'] as num?)?.toInt() ?? AppColors.primary.toARGB32(),
      ),
      coverIcon: iconDataForCodePoint(
        (map['coverIcon'] as num?)?.toInt(),
        fallback: Icons.queue_music_rounded,
      ),
      songs: songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverColor': coverColor.toARGB32(),
      'coverIcon': coverIcon.codePoint,
      'coverIconFontFamily': coverIcon.fontFamily,
      'songs': songs.map((song) => song.toMap()).toList(),
    };
  }
}
