import 'package:material_ui/material_ui.dart';

import '../../models/song.dart';
import '../../services/music_player_service.dart';

import 'package:just_audio/just_audio.dart';

const Color bgColor = Color(0xFF15121F);
const Color cardColor = Color(0xFF252131);
const Color primaryColor = Color(0xFFB87553);
const Color textColor = Colors.white;
const Color subTextColor = Color(0xFFB5B0C0);

class PlayerScreen extends StatefulWidget {
  final String songName;
  final String artist;
  final Color coverColor;
  final IconData coverIcon;
  final String audioUrl;

  const PlayerScreen({
    super.key,
    required this.songName,
    required this.artist,
    required this.coverColor,
    required this.coverIcon,
    this.audioUrl = '',
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final MusicPlayerService music = MusicPlayerService.instance;

  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _startSong();
  }

  Future<void> _startSong() async {
    if (music.currentSong?.name == widget.songName) return;

    if (widget.audioUrl.trim().isEmpty) {
      setState(() {
        errorMessage = 'Bài hát chưa được cập nhật file MP3.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final song = Song(
        id: widget.songName,
        name: widget.songName,
        artist: widget.artist,
        audioUrl: widget.audioUrl,
        coverColor: widget.coverColor,
        coverIcon: widget.coverIcon,
      );

      await music.playSong(song);
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể phát nhạc: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text(
          'ĐANG PHÁT',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: widget.coverColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: widget.coverColor.withValues(alpha: 0.3),
                          blurRadius: 35,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.coverIcon,
                      color: Colors.white,
                      size: 110,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    widget.songName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.artist,
                    style: const TextStyle(color: subTextColor, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),

                  if (loading)
                    const CircularProgressIndicator(color: primaryColor),

                  StreamBuilder<Duration>(
                    stream: music.player.positionStream,
                    initialData: music.player.position,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;

                      final duration = music.player.duration ?? Duration.zero;

                      final maxValue = duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0;

                      final currentValue = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, maxValue);

                      return Column(
                        children: [
                          Slider(
                            value: currentValue,
                            max: maxValue,
                            activeColor: primaryColor,
                            inactiveColor: cardColor,
                            onChanged: duration == Duration.zero
                                ? null
                                : (value) {
                                    music.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(color: subTextColor),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: subTextColor),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await music.toggleShuffle();
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          Icons.shuffle,
                          color: music.isShuffle ? primaryColor : subTextColor,
                        ),
                      ),

                      IconButton(
                        onPressed: music.previous,
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: textColor,
                          size: 42,
                        ),
                      ),

                      StreamBuilder<PlayerState>(
                        stream: music.player.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;

                          return IconButton(
                            onPressed: () async {
                              try {
                                await music.togglePlayPause();
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    errorMessage = e.toString();
                                  });
                                }
                              }
                            },
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: primaryColor,
                              size: 68,
                            ),
                          );
                        },
                      ),

                      IconButton(
                        onPressed: music.next,
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: textColor,
                          size: 42,
                        ),
                      ),

                      IconButton(
                        onPressed: () async {
                          await music.cycleRepeatMode();
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          music.loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: music.loopMode == LoopMode.off
                              ? subTextColor
                              : primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  const Text(
                    'MELODY MUSIC PLAYER',
                    style: TextStyle(
                      color: subTextColor,
                      letterSpacing: 3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
