import 'package:material_ui/material_ui.dart';

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
    this.coverColor = const Color(0xFFB87553),
    this.coverIcon = Icons.music_note,
  });

  factory Song.fromMap(Map<String, dynamic> map, String documentId) {
    return Song(
      id: documentId,
      name: map['name']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      album: map['album']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
      duration: Duration(seconds: (map['duration'] as num?)?.toInt() ?? 0),
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get durationText {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
