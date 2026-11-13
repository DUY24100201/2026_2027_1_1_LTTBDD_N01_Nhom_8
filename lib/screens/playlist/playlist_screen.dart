import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../models/music_playlist.dart';
import '../../models/song.dart';
import '../../services/playlist_service.dart';
import '../../widgets/intro_dialog_page.dart';
import '../player/player_screen.dart';

const Color _bgColor = AppColors.background;
const Color _cardColor = AppColors.surface;
const Color _primaryColor = AppColors.primary;
const Color _textColor = AppColors.white;
const Color _subTextColor = AppColors.secondaryText;

const List<Color> _coverColors = [
  Color(0xFFB87553),
  Color(0xFF7952C7),
  Color(0xFF455A88),
  Color(0xFF6546A5),
  Color(0xFF426B55),
  Color(0xFF984C83),
  Color(0xFF53617E),
];

const List<IconData> _coverIcons = [
  Icons.queue_music_rounded,
  Icons.headphones_rounded,
  Icons.nightlight_round,
  Icons.laptop_rounded,
  Icons.spa_rounded,
  Icons.favorite_rounded,
  Icons.album_rounded,
];

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistService _service = PlaylistService.instance;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      await _service.load();
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
      _showMessage('Không thể tải playlist: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _primaryColor),
    );
  }

  Future<void> _createPlaylist() async {
    final form = await _showPlaylistForm(context);
    if (form == null) return;

    try {
      await _service.create(
        name: form.name,
        description: form.description,
        coverColor: form.coverColor,
        coverIcon: form.coverIcon,
      );
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã tạo playlist "${form.name}".');
    } catch (error) {
      _showMessage('Không thể tạo playlist: $error');
    }
  }

  Future<void> _editPlaylist(MusicPlaylist playlist) async {
    final form = await _showPlaylistForm(context, playlist: playlist);
    if (form == null) return;

    try {
      await _service.update(
        playlist.copyWith(
          name: form.name,
          description: form.description,
          coverColor: form.coverColor,
          coverIcon: form.coverIcon,
        ),
      );
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã cập nhật playlist.');
    } catch (error) {
      _showMessage('Không thể cập nhật playlist: $error');
    }
  }

  Future<void> _deletePlaylist(MusicPlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Xóa playlist?', style: TextStyle(color: _textColor)),
        content: Text(
          'Playlist "${playlist.name}" sẽ bị xóa khỏi thiết bị.',
          style: const TextStyle(color: _subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.delete(playlist.id);
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã xóa playlist "${playlist.name}".');
    } catch (error) {
      _showMessage('Không thể xóa playlist: $error');
    }
  }

  Future<void> _openPlaylist(MusicPlaylist playlist) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          screenId: 'playlist_detail',
          child: PlaylistDetailScreen(playlistId: playlist.id),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SizedBox(
                width: double.infinity,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _PlaylistHeader(onBack: () => Navigator.maybePop(context)),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _primaryColor,
                              ),
                            )
                          : _loadError != null
                          ? _LoadError(
                              message: _loadError!,
                              onRetry: () {
                                setState(() {
                                  _loading = true;
                                  _loadError = null;
                                });
                                _loadPlaylists();
                              },
                            )
                          : _buildPlaylistList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlaylist,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo playlist'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPlaylistList() {
    final playlists = _service.playlists;
    if (playlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  color: _primaryColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chưa có playlist nào',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo playlist đầu tiên để lưu những bài hát yêu thích.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _subTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            '${playlists.length} playlist',
            style: const TextStyle(color: _subTextColor, fontSize: 13),
          ),
        ),
        for (final playlist in playlists)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openPlaylist(playlist),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _PlaylistCover(
                        color: playlist.coverColor,
                        icon: playlist.coverIcon,
                        size: 68,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${playlist.songs.length} bài hát',
                              style: const TextStyle(
                                color: _subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            if (playlist.description.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                playlist.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _subTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: _cardColor,
                        onSelected: (value) {
                          if (value == 'edit') _editPlaylist(playlist);
                          if (value == 'delete') _deletePlaylist(playlist);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Sửa playlist',
                              style: TextStyle(color: _textColor),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Xóa playlist',
                              style: TextStyle(color: _textColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _service = PlaylistService.instance;

  static final List<Song> _catalog = [
    const Song(
      id: 'ánh nắng của anh',
      name: 'Ánh Nắng Của Anh',
      artist: 'Đức Phúc',
      album: 'Ánh Nắng Của Anh',
      duration: Duration(minutes: 4, seconds: 15),
      coverColor: Color(0xFFE5A65B),
      coverIcon: Icons.wb_sunny_rounded,
    ),
    const Song(
      id: 'thấy em là thấy',
      name: 'Thấy Em Là Thấy',
      artist: 'Phạm Việt Thắng',
      album: 'Thấy Em Là Thấy',
      duration: Duration(minutes: 3, seconds: 45),
      coverColor: Color(0xFFD87885),
      coverIcon: Icons.favorite_rounded,
    ),
    const Song(
      id: 'có hẹn với thanh xuân',
      name: 'Có Hẹn Với Thanh Xuân',
      artist: 'MONSTAR',
      album: 'Có Hẹn Với Thanh Xuân',
      duration: Duration(minutes: 4, seconds: 20),
      coverColor: Color(0xFF7195C8),
      coverIcon: Icons.cloud_rounded,
    ),
    const Song(
      id: 'về nhà',
      name: 'Về Nhà',
      artist: 'Chillies',
      album: 'Qua Khung Cửa Sổ',
      duration: Duration(minutes: 3, seconds: 52),
      coverColor: Color(0xFF7A9A85),
      coverIcon: Icons.home_rounded,
    ),
    const Song(
      id: 'đổi thay',
      name: 'Đổi Thay',
      artist: 'Hồ Quang Hiếu',
      album: 'Đổi Thay',
      duration: Duration(minutes: 4, seconds: 5),
      coverColor: Color(0xFF987BC1),
      coverIcon: Icons.music_note_rounded,
    ),
  ];

  MusicPlaylist? get _playlist => _service.findById(widget.playlistId);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _primaryColor),
    );
  }

  Future<void> _editPlaylist(MusicPlaylist playlist) async {
    final form = await _showPlaylistForm(context, playlist: playlist);
    if (form == null) return;

    try {
      await _service.update(
        playlist.copyWith(
          name: form.name,
          description: form.description,
          coverColor: form.coverColor,
          coverIcon: form.coverIcon,
        ),
      );
      if (mounted) {
        setState(() {});
        _showMessage('Đã cập nhật playlist.');
      }
    } catch (error) {
      _showMessage('Không thể cập nhật playlist: $error');
    }
  }

  Future<void> _addSongs(MusicPlaylist playlist) async {
    final available = _catalog
        .where((song) => !playlist.songs.any((item) => item.id == song.id))
        .toList();
    if (available.isEmpty) {
      _showMessage('Tất cả bài hát đã có trong playlist.');
      return;
    }

    final song = await showDialog<Song>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Thêm bài hát', style: TextStyle(color: _textColor)),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width - 64, 360),
          height: min(available.length * 70.0, 350),
          child: ListView.builder(
            itemCount: available.length,
            itemBuilder: (context, index) {
              final item = available[index];
              return ListTile(
                leading: _PlaylistCover(
                  color: item.coverColor,
                  icon: item.coverIcon,
                  size: 42,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(color: _textColor),
                ),
                subtitle: Text(
                  item.artist,
                  style: const TextStyle(color: _subTextColor),
                ),
                onTap: () => Navigator.pop(dialogContext, item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    if (song == null) return;

    try {
      await _service.addSong(playlist.id, song);
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã thêm "${song.name}" vào playlist.');
    } catch (error) {
      _showMessage('Không thể thêm bài hát: $error');
    }
  }

  Future<void> _removeSong(MusicPlaylist playlist, Song song) async {
    try {
      await _service.removeSong(playlist.id, song.id);
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã xóa "${song.name}" khỏi playlist.');
    } catch (error) {
      _showMessage('Không thể xóa bài hát: $error');
    }
  }

  Future<void> _reorderSongs(
    MusicPlaylist playlist,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await _service.reorderSong(playlist.id, oldIndex, newIndex);
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage('Không thể sắp xếp bài hát: $error');
    }
  }

  Future<void> _playSongs(
    MusicPlaylist playlist, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (playlist.songs.isEmpty) {
      _showMessage('Playlist chưa có bài hát.');
      return;
    }

    final queue = [...playlist.songs];
    if (shuffle) queue.shuffle(Random());
    final index = shuffle ? 0 : startIndex;
    final song = queue[index];

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          screenId: 'player',
          child: PlayerScreen(
            songName: song.name,
            artist: song.artist,
            coverColor: song.coverColor,
            coverIcon: song.coverIcon,
            audioUrl: song.audioUrl,
            song: song,
            queue: queue,
            startIndex: index,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;
    if (playlist == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Playlist không còn tồn tại.',
                    style: TextStyle(color: _textColor),
                  ),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SizedBox(
                width: double.infinity,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _PlaylistHeader(
                      onBack: () => Navigator.maybePop(context),
                      actions: [
                        IconButton(
                          onPressed: () => _editPlaylist(playlist),
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: _textColor,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          Center(
                            child: _PlaylistCover(
                              color: playlist.coverColor,
                              icon: playlist.coverIcon,
                              size: 150,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            playlist.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (playlist.description.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Text(
                              playlist.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _subTextColor),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${playlist.songs.length} bài hát',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _subTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _playSongs(playlist),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Phát tất cả'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filled(
                                onPressed: () =>
                                    _playSongs(playlist, shuffle: true),
                                style: IconButton.styleFrom(
                                  backgroundColor: _cardColor,
                                  foregroundColor: _primaryColor,
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(Icons.shuffle_rounded),
                                tooltip: 'Phát ngẫu nhiên',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Bài hát',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _addSongs(playlist),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Thêm bài'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (playlist.songs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 38),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.music_off_rounded,
                                    color: _subTextColor,
                                    size: 42,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Playlist chưa có bài hát',
                                    style: TextStyle(color: _subTextColor),
                                  ),
                                ],
                              ),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: playlist.songs.length,
                              onReorderItem: (oldIndex, newIndex) =>
                                  _reorderSongs(playlist, oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final song = playlist.songs[index];
                                return Padding(
                                  key: ValueKey(song.id),
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: Material(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(17),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(17),
                                      onTap: () => _playSongs(
                                        playlist,
                                        startIndex: index,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          children: [
                                            _PlaylistCover(
                                              color: song.coverColor,
                                              icon: song.coverIcon,
                                              size: 48,
                                            ),
                                            const SizedBox(width: 11),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    song.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: _textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    song.artist,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: _subTextColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Xóa khỏi playlist',
                                              onPressed: () =>
                                                  _removeSong(playlist, song),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: _subTextColor,
                                              ),
                                            ),
                                            ReorderableDragStartListener(
                                              index: index,
                                              child: const Icon(
                                                Icons.drag_handle_rounded,
                                                color: _subTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  final VoidCallback onBack;
  final List<Widget> actions;

  const _PlaylistHeader({required this.onBack, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: _textColor),
          ),
          const Expanded(
            child: Text(
              'PLAYLIST',
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const _PlaylistCover({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, _cardColor, 0.55)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _PlaylistFormData {
  final String name;
  final String description;
  final Color coverColor;
  final IconData coverIcon;

  const _PlaylistFormData({
    required this.name,
    required this.description,
    required this.coverColor,
    required this.coverIcon,
  });
}

Future<_PlaylistFormData?> _showPlaylistForm(
  BuildContext context, {
  MusicPlaylist? playlist,
}) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: playlist?.name ?? '');
  final descriptionController = TextEditingController(
    text: playlist?.description ?? '',
  );
  var selectedColor = playlist?.coverColor ?? _primaryColor;
  var selectedIcon = playlist?.coverIcon ?? Icons.queue_music_rounded;

  try {
    return await showDialog<_PlaylistFormData>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            playlist == null ? 'Tạo playlist' : 'Sửa playlist',
            style: const TextStyle(color: _textColor),
          ),
          content: SizedBox(
            width: min(MediaQuery.sizeOf(context).width - 64, 380),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      maxLength: 40,
                      style: const TextStyle(color: _textColor),
                      decoration: const InputDecoration(
                        labelText: 'Tên playlist',
                        labelStyle: TextStyle(color: _subTextColor),
                        counterStyle: TextStyle(color: _subTextColor),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên playlist.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLength: 120,
                      maxLines: 2,
                      style: const TextStyle(color: _textColor),
                      decoration: const InputDecoration(
                        labelText: 'Mô tả (không bắt buộc)',
                        labelStyle: TextStyle(color: _subTextColor),
                        counterStyle: TextStyle(color: _subTextColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Màu bìa',
                      style: TextStyle(color: _subTextColor),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _coverColors.map((color) {
                        final selected = selectedColor == color;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          customBorder: const CircleBorder(),
                          child: CircleAvatar(
                            radius: selected ? 19 : 16,
                            backgroundColor: color,
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Biểu tượng bìa',
                      style: TextStyle(color: _subTextColor),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: _coverIcons.map((icon) {
                        final selected = selectedIcon == icon;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected ? selectedColor : _bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: Colors.white, size: 21),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  _PlaylistFormData(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    coverColor: selectedColor,
                    coverIcon: selectedIcon,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(playlist == null ? 'Tạo' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  } finally {
    nameController.dispose();
    descriptionController.dispose();
  }
}

Future<void> showAddSongToPlaylistDialog(
  BuildContext context,
  Song song,
) async {
  final service = PlaylistService.instance;
  final messenger = ScaffoldMessenger.of(context);

  try {
    await service.load();
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể tải playlist: $error'),
          backgroundColor: _primaryColor,
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final playlists = service.playlists;
  if (playlists.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Hãy tạo playlist trước khi thêm bài hát.'),
        backgroundColor: _primaryColor,
      ),
    );
    return;
  }

  final playlistId = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _cardColor,
      title: const Text(
        'Thêm vào playlist',
        style: TextStyle(color: _textColor),
      ),
      content: SizedBox(
        width: min(MediaQuery.sizeOf(context).width - 64, 360),
        height: min(playlists.length * 65.0, 350),
        child: ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return ListTile(
              leading: _PlaylistCover(
                color: playlist.coverColor,
                icon: playlist.coverIcon,
                size: 42,
              ),
              title: Text(
                playlist.name,
                style: const TextStyle(color: _textColor),
              ),
              subtitle: Text(
                '${playlist.songs.length} bài hát',
                style: const TextStyle(color: _subTextColor),
              ),
              onTap: () => Navigator.pop(dialogContext, playlist.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (playlistId == null) return;

  try {
    final added = await service.addSong(playlistId, song);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Đã thêm "${song.name}" vào playlist.'
                : 'Bài hát đã có trong playlist.',
          ),
          backgroundColor: _primaryColor,
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể thêm bài hát: $error'),
          backgroundColor: _primaryColor,
        ),
      );
    }
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _subTextColor),
            ),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
