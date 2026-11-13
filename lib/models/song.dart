import 'package:material_ui/material_ui.dart';

import '../core/constants/app_colors.dart';

const List<IconData> _knownSongIcons = [
  Icons.music_note,
  Icons.music_note_rounded,
  Icons.wb_sunny,
  Icons.wb_sunny_rounded,
  Icons.favorite,
  Icons.favorite_rounded,
  Icons.cloud,
  Icons.cloud_rounded,
  Icons.home,
  Icons.home_rounded,
  Icons.nightlife,
  Icons.waves,
  Icons.queue_music_rounded,
  Icons.headphones_rounded,
  Icons.nightlight_round,
  Icons.laptop_rounded,
  Icons.spa_rounded,
  Icons.album_rounded,
];

String songIdForName(String name) => name.trim().toLowerCase();

IconData iconDataForCodePoint(
  int? codePoint, {
  IconData fallback = Icons.music_note,
}) {
  for (final icon in _knownSongIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return fallback;
}

class Song {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String audioUrl;
  final String coverUrl;
  final Duration duration;
  final int playCount;
  final Color coverColor;
  final IconData coverIcon;

  const Song({
    required this.id,
    required this.name,
    required this.artist,
    this.album = '',
    this.audioUrl = '',
    this.coverUrl = '',
    this.duration = Duration.zero,
    this.playCount = 0,
    this.coverColor = AppColors.primary,
    this.coverIcon = Icons.music_note,
  });

  factory Song.fromMap(Map<String, dynamic> map, String documentId) {
    final rawDuration = map['durationSeconds'] ?? map['duration'];
    final durationSeconds = switch (rawDuration) {
      num value => value.toInt(),
      String value => _parseDuration(value),
      _ => 0,
    };
    final rawColor = map['coverColor'] ?? map['color'];
    final rawIcon = map['coverIcon'] ?? map['icon'];

    return Song(
      id: map['id']?.toString() ?? documentId,
      name: map['name']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      album: map['album']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
      duration: Duration(seconds: durationSeconds),
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
      coverColor: rawColor is Color
          ? rawColor
          : Color(
              (rawColor as num?)?.toInt() ?? AppColors.primary.toARGB32(),
            ),
      coverIcon: rawIcon is IconData
          ? rawIcon
          : iconDataForCodePoint((rawIcon as num?)?.toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'album': album,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'durationSeconds': duration.inSeconds,
      'playCount': playCount,
      'coverColor': coverColor.toARGB32(),
      'coverIcon': coverIcon.codePoint,
      'coverIconFontFamily': coverIcon.fontFamily,
    };
  }

  static int _parseDuration(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null) return 0;

    return minutes * 60 + seconds;
  }

  String get durationText {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
