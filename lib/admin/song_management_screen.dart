import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/music/song_library_service.dart';

class SongManagementScreen extends StatefulWidget {
  const SongManagementScreen({super.key});

  @override
  State<SongManagementScreen> createState() => _SongManagementScreenState();
}

class _SongManagementScreenState extends State<SongManagementScreen> {
  final SongLibraryService _library = SongLibraryService.instance;
  List<Song> _songs = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      AuthService.instance.requireAdmin();
      final songs = await _library.readSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _editSong([Song? song]) async {
    if (!AuthService.instance.isAdmin) {
      _showMessage('Chỉ Admin mới được quản lý bài hát.');
      return;
    }
    final result = await showDialog<_SongEditorResult>(
      context: context,
      builder: (_) => _SongEditorDialog(song: song),
    );
    if (result == null || !mounted) return;
    try {
      setState(() => _saving = true);
      if (song == null) {
        final bytes = result.audioBytes;
        final fileName = result.audioFileName;
        if (bytes == null || fileName == null) {
          throw const SongLibraryException('Vui lòng chọn file MP3.');
        }
        await _library.addSong(
          result.song,
          audioBytes: bytes,
          audioFileName: fileName,
        );
      } else {
        await _library.updateSong(
          result.song,
          audioBytes: result.audioBytes,
          audioFileName: result.audioFileName,
        );
      }
      await _loadSongs();
      _showMessage(song == null ? 'Đã thêm bài hát.' : 'Đã cập nhật bài hát.');
    } catch (error) {
      await _loadSongs();
      _showMessage('Không thể lưu bài hát: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSong(Song song) async {
    if (!AuthService.instance.isAdmin) {
      _showMessage('Chỉ Admin mới được quản lý bài hát.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Xóa bài hát?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Bài hát "${song.name}" sẽ bị xóa khỏi thư viện chung.',
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _library.deleteSong(song.id);
      await _loadSongs();
      _showMessage('Đã xóa bài hát.');
    } catch (error) {
      await _loadSongs();
      _showMessage('Không thể xóa bài hát: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Quản lý bài hát')),
        body: const Center(
          child: Text(
            'Bạn không có quyền truy cập chức năng này.',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        title: const Text('Quản lý bài hát'),
        actions: [
          TextButton.icon(
            onPressed: _loading || _saving ? null : () => _editSong(),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Tải MP3 lên'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _saving ? null : () => _editSong(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm bài hát'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildError()
          : _buildManagementBody(),
    );
  }

  Widget _buildManagementBody() {
    final query = _searchQuery.trim().toLowerCase();
    final songs = _songs.where((song) {
      return query.isEmpty ||
          song.name.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        if (_saving) const LinearProgressIndicator(color: AppColors.primary),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Tổng số bài hát trong thư viện: ${_songs.length}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm bài hát, ca sĩ hoặc album',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: songs.isEmpty
              ? Center(
                  child: Text(
                    _songs.isEmpty
                        ? 'Chưa có bài hát do Admin thêm.'
                        : 'Không tìm thấy bài hát phù hợp.',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: songs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _songTile(songs[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không thể tải thư viện: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          TextButton(onPressed: _loadSongs, child: const Text('Thử lại')),
        ],
      ),
    ),
  );

  Widget _songTile(Song song) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: ListTile(
      leading: _cover(song.coverUrl, song.coverColor, song.coverIcon),
      title: Text(
        song.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          song.artist,
          if (song.album.isNotEmpty) song.album,
          if (song.genre.isNotEmpty) song.genre,
          if (song.duration > Duration.zero) song.durationText,
          if (song.audioUrl.isEmpty) 'Chưa có MP3',
        ].join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
      trailing: PopupMenuButton<String>(
        color: AppColors.surface,
        onSelected: (action) {
          if (action == 'edit') _editSong(song);
          if (action == 'delete') _deleteSong(song);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: Text('Sửa', style: TextStyle(color: AppColors.white)),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text('Xóa', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    ),
  );

  Widget _cover(String source, Color color, IconData icon) {
    final data = _decodeDataUri(source);
    if (data != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          data,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _coverPlaceholder(color, icon),
        ),
      );
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          source,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _coverPlaceholder(color, icon),
        ),
      );
    }
    return _coverPlaceholder(color, icon);
  }

  Widget _coverPlaceholder(Color color, IconData icon) => CircleAvatar(
    backgroundColor: color,
    child: Icon(icon, color: AppColors.white),
  );
}

class _SongEditorDialog extends StatefulWidget {
  const _SongEditorDialog({this.song});

  final Song? song;

  @override
  State<_SongEditorDialog> createState() => _SongEditorDialogState();
}

class _SongEditorDialogState extends State<_SongEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final TextEditingController _genreController;
  late final TextEditingController _coverController;
  String? _audioFilename;
  Uint8List? _audioBytes;
  Uint8List? _coverBytes;
  Duration? _audioDuration;
  String? _error;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    final song = widget.song;
    _nameController = TextEditingController(text: song?.name ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _albumController = TextEditingController(text: song?.album ?? '');
    _genreController = TextEditingController(text: song?.genre ?? '');
    _coverController = TextEditingController(text: song?.coverUrl ?? '');
    _audioFilename = song?.audioUrl.isNotEmpty == true
        ? 'Đã lưu file MP3'
        : null;
  }

  Future<void> _selectMp3() async {
    await _selectingFile(() async {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['mp3'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      SongLibraryService.validateMp3(fileName: file.name, bytes: bytes);
      setState(() {
        _audioBytes = bytes;
        _audioFilename = file.name;
        _audioDuration = SongLibraryService.readMp3Duration(bytes);
      });
    });
  }

  Future<void> _selectCover() async {
    await _selectingFile(() async {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('Ảnh bìa rỗng hoặc không đọc được.');
      }
      final extension = file.extension?.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => throw const FormatException('Định dạng ảnh bìa không hợp lệ.'),
      };
      _coverBytes = bytes;
      _coverController.text = 'data:$mimeType;base64,${base64Encode(bytes)}';
      setState(() {});
    });
  }

  Future<void> _selectingFile(Future<void> Function() select) async {
    setState(() {
      _selecting = true;
      _error = null;
    });
    try {
      await select();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final artist = _artistController.text.trim();
    if (name.isEmpty || artist.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên bài hát và ca sĩ.');
      return;
    }
    if (_audioBytes == null && widget.song == null) {
      setState(() => _error = 'Vui lòng chọn file MP3.');
      return;
    }
    final oldSong = widget.song;
    Navigator.pop(
      context,
      _SongEditorResult(
        song: Song(
          id: oldSong?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          artist: artist,
          album: _albumController.text.trim(),
          genre: _genreController.text.trim(),
          audioUrl: oldSong?.audioUrl ?? '',
          coverUrl: _coverController.text.trim(),
          duration: _audioDuration ?? oldSong?.duration ?? Duration.zero,
          playCount: oldSong?.playCount ?? 0,
          coverColor: oldSong?.coverColor ?? AppColors.primary,
          coverIcon: oldSong?.coverIcon ?? Icons.music_note,
        ),
        audioBytes: _audioBytes,
        audioFileName: _audioFilename,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: Text(
      widget.song == null ? 'Thêm bài hát' : 'Sửa bài hát',
      style: const TextStyle(color: AppColors.white),
    ),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameController, 'Tên bài hát'),
            _field(_artistController, 'Ca sĩ'),
            _field(_albumController, 'Album'),
            _field(_genreController, 'Thể loại'),
            TextField(
              controller: _coverController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(
                labelText: 'Đường dẫn ảnh bìa (tùy chọn)',
              ),
            ),
            if (_coverBytes != null) ...[
              const SizedBox(height: 10),
              Image.memory(
                _coverBytes!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _selecting ? null : _selectCover,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Chọn ảnh bìa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selecting ? null : _selectMp3,
              icon: const Icon(Icons.audio_file_outlined),
              label: Text(_audioFilename ?? 'Chọn file MP3'),
            ),
            if (_selecting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 4),
              const Text(
                'Đang đọc file đã chọn...',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
            if (_audioFilename != null) ...[
              const SizedBox(height: 6),
              Text(
                'File: $_audioFilename'
                '${_audioBytes == null ? '' : ' • ${_formatFileSize(_audioBytes!.length)}'}',
                style: const TextStyle(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
            if (_audioBytes != null) ...[
              const SizedBox(height: 4),
              Text(
                _audioDuration == null || _audioDuration == Duration.zero
                    ? 'Không đọc được thời lượng từ MP3.'
                    : 'Thời lượng: ${_formatDuration(_audioDuration!)}',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _selecting ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      ElevatedButton(
        onPressed: _selecting ? null : _save,
        child: const Text('Lưu'),
      ),
    ],
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(labelText: label),
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SongEditorResult {
  const _SongEditorResult({
    required this.song,
    required this.audioBytes,
    required this.audioFileName,
  });

  final Song song;
  final Uint8List? audioBytes;
  final String? audioFileName;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Uint8List? _decodeDataUri(String uri) {
  final separator = uri.indexOf(',');
  if (!uri.startsWith('data:') || separator < 0) return null;
  try {
    return base64Decode(uri.substring(separator + 1));
  } on FormatException {
    return null;
  }
}
