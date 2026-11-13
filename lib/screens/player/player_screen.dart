import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../models/song.dart';
import '../../services/local_profile_service.dart';
import '../../services/music_player_service.dart';

const Color bgColor = AppColors.background;
const Color cardColor = AppColors.surface;
const Color primaryColor = AppColors.primary;
const Color textColor = AppColors.white;
const Color subTextColor = AppColors.secondaryText;

class PlayerScreen extends StatefulWidget {
  final String songName;
  final String artist;
  final Color coverColor;
  final IconData coverIcon;
  final String audioUrl;
  final Song? song;
  final List<Song>? queue;
  final int startIndex;

  const PlayerScreen({
    super.key,
    required this.songName,
    required this.artist,
    required this.coverColor,
    required this.coverIcon,
    this.audioUrl = '',
    this.song,
    this.queue,
    this.startIndex = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final MusicPlayerService music = MusicPlayerService.instance;

  bool loading = false;
  String? errorMessage;

  bool get hasAudio =>
      (widget.song?.audioUrl ?? widget.audioUrl).trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _startSong();
  }

  Future<void> _startSong() async {
    String? settingsError;
    try {
      await music.loadPlaybackSettings();
    } catch (error) {
      settingsError = 'Không thể tải cài đặt phát nhạc: $error';
    }

    if (!mounted) return;

    final requestedQueue = widget.queue;
    final requestedIndex = requestedQueue == null || requestedQueue.isEmpty
        ? 0
        : widget.startIndex.clamp(0, requestedQueue.length - 1);
    final requestedSong = requestedQueue == null || requestedQueue.isEmpty
        ? widget.song ??
              Song(
                id: widget.songName,
                name: widget.songName,
                artist: widget.artist,
                audioUrl: widget.audioUrl,
                coverColor: widget.coverColor,
                coverIcon: widget.coverIcon,
              )
        : requestedQueue[requestedIndex];

    final sameQueue =
        requestedQueue == null ||
        (music.queue.length == requestedQueue.length &&
            List.generate(
              music.queue.length,
              (index) => music.queue[index].id == requestedQueue[index].id,
            ).every((matches) => matches));
    if (music.currentSong?.id == requestedSong.id &&
        sameQueue &&
        (requestedQueue == null || music.currentIndex == requestedIndex)) {
      if (settingsError != null) {
        setState(() => errorMessage = settingsError);
      }
      return;
    }

    if (requestedSong.audioUrl.trim().isEmpty) {
      setState(() {
        errorMessage = 'Bài hát chưa được cập nhật file MP3.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = settingsError;
    });

    var started = false;
    try {
      if (requestedQueue != null && requestedQueue.isNotEmpty) {
        await music.setQueue(requestedQueue, startIndex: requestedIndex);
      } else {
        await music.playSong(requestedSong);
      }
      started = true;
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể phát nhạc. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    if (started) await _recordRecentlyPlayed(requestedSong);
  }

  Future<void> _recordRecentlyPlayed(Song song) async {
    try {
      await LocalProfileService.instance.recordRecentlyPlayed(song);
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage =
              'Bài hát đang phát nhưng không thể lưu lịch sử: $error';
        });
      }
    }
  }

  Future<void> _skipNext() async {
    try {
      await music.next();
      final song = music.currentSong;
      if (song != null) await _recordRecentlyPlayed(song);
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể phát bài tiếp theo: $error';
        });
      }
    }
  }

  Future<void> _skipPrevious() async {
    try {
      await music.previous();
      final song = music.currentSong;
      if (song != null) await _recordRecentlyPlayed(song);
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể phát bài trước đó: $error';
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayback() async {
    if (!hasAudio) {
      setState(() {
        errorMessage = 'Bài hát chưa được cập nhật file MP3.';
      });
      return;
    }

    try {
      await music.togglePlayPause();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể phát bài hát này.';
        });
      }
    }
  }

  Future<void> _toggleShuffle() async {
    try {
      await music.toggleShuffle();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể lưu chế độ phát ngẫu nhiên: $error';
        });
      }
    }
  }

  Future<void> _cycleRepeat() async {
    try {
      await music.cycleRepeatMode();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể lưu chế độ lặp lại: $error';
        });
      }
    }
  }

  Widget _roundControl({
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = textColor,
    double iconSize = 27,
    bool active = false,
  }) {
    return Material(
      color: active ? primaryColor.withValues(alpha: 0.16) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onPressed == null
                ? subTextColor.withValues(alpha: 0.35)
                : color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return StreamBuilder<Duration?>(
      stream: music.player.durationStream,
      initialData: music.player.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: music.player.positionStream,
          initialData: music.player.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            final maxValue = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;

            final currentValue = position.inMilliseconds
                .toDouble()
                .clamp(0.0, maxValue)
                .toDouble();

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: cardColor,
                    thumbColor: primaryColor,
                    overlayColor: primaryColor.withValues(alpha: 0.14),
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: currentValue,
                    max: maxValue,
                    onChanged: !hasAudio || duration == Duration.zero
                        ? null
                        : (value) {
                            music.seek(Duration(milliseconds: value.toInt()));
                          },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        _roundControl(
          icon: Icons.shuffle_rounded,
          onPressed: _toggleShuffle,
          color: music.isShuffle ? primaryColor : subTextColor,
          active: music.isShuffle,
          iconSize: 23,
        ),

        // Previous
        _roundControl(
          icon: Icons.skip_previous_rounded,
          onPressed: hasAudio ? _skipPrevious : null,
          iconSize: 34,
        ),

        // Play / Pause
        StreamBuilder<PlayerState>(
          stream: music.player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;

            return Material(
              color: primaryColor,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: primaryColor.withValues(alpha: 0.35),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: loading ? null : _togglePlayback,
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 43,
                        ),
                ),
              ),
            );
          },
        ),

        // Next
        _roundControl(
          icon: Icons.skip_next_rounded,
          onPressed: hasAudio ? _skipNext : null,
          iconSize: 34,
        ),

        // Repeat
        _roundControl(
          icon: music.loopMode == LoopMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          onPressed: _cycleRepeat,
          color: music.loopMode == LoopMode.off ? subTextColor : primaryColor,
          active: music.loopMode != LoopMode.off,
          iconSize: 23,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'ĐANG PHÁT',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;

            final coverSize = (constraints.maxWidth * 0.68)
                .clamp(180.0, compact ? 230.0 : 280.0)
                .toDouble();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, compact ? 8 : 18, 24, 24),
                  child: Column(
                    children: [
                      // Ảnh bìa bo góc
                      Container(
                        width: coverSize,
                        height: coverSize,
                        decoration: BoxDecoration(
                          color: widget.coverColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: widget.coverColor.withValues(alpha: 0.24),
                              blurRadius: 34,
                              spreadRadius: 1,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Center(
                            child: Icon(
                              widget.coverIcon,
                              color: Colors.white,
                              size: coverSize * 0.36,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: compact ? 20 : 26),

                      // Tên bài hát
                      Text(
                        widget.songName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tên ca sĩ
                      Text(
                        widget.artist,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                        ),
                      ),

                      // Thông báo trạng thái
                      if (errorMessage != null) ...[
                        const SizedBox(height: 22),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFFFB547),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB547),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: compact ? 20 : 28),

                      // Thanh tiến trình
                      _buildProgress(),

                      SizedBox(height: compact ? 22 : 34),

                      // Các nút điều khiển
                      _buildControls(),

                      SizedBox(height: compact ? 30 : 42),

                      // Nhãn ứng dụng
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'MELODY MUSIC PLAYER',
                          style: TextStyle(
                            color: subTextColor,
                            letterSpacing: 3,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
