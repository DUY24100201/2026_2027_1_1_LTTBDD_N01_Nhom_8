import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/local_user_profile.dart';
import '../../models/song.dart';
import '../../services/local_profile_service.dart';
import '../../services/playlist_service.dart';
import '../../widgets/intro_dialog_page.dart';
import '../auth/login/login_screen.dart';
import '../library/library_screen.dart' as music_library;
import '../player/player_screen.dart';
import '../playlist/playlist_screen.dart';

const Color _profileBackground = Color(0xFF15121F);
const Color _profileCard = Color(0xFF252131);
const Color _profileAccent = Color(0xFFB87553);
const Color _profileText = Colors.white;
const Color _profileSubText = Color(0xFFB5B0C0);

class ProfileScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalProfileService _profileService = LocalProfileService.instance;
  final PlaylistService _playlistService = PlaylistService.instance;

  bool _loading = true;
  String? _loadError;
  String _version = 'Đang tải...';
  String? _versionError;
  int _favoriteCount = 0;
  int _playlistCount = 0;

  LocalUserProfile get _profile => _profileService.profile;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadVersion();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([_profileService.load(), _playlistService.load()]);
      if (!mounted) return;
      setState(() {
        _favoriteCount = _profileService.favoriteIds.length;
        _playlistCount = _playlistService.playlists.length;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = packageInfo.buildNumber.isEmpty
            ? packageInfo.version
            : '${packageInfo.version}+${packageInfo.buildNumber}';
        _versionError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _version = 'Không khả dụng';
        _versionError = error.toString();
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _profileAccent),
    );
  }

  Future<void> _refreshCounts() async {
    try {
      await Future.wait([_profileService.load(), _playlistService.load()]);
      if (!mounted) return;
      setState(() {
        _favoriteCount = _profileService.favoriteIds.length;
        _playlistCount = _playlistService.playlists.length;
      });
    } catch (error) {
      _showMessage('Không thể cập nhật thông tin: $error');
    }
  }

  Future<void> _editProfile() async {
    final form = await _showEditProfileDialog(context, _profile);
    if (form == null) return;

    final updated = _profile.copyWith(
      displayName: form.displayName,
      email: form.email,
      clearEmail: form.email == null,
    );

    try {
      await _profileService.saveProfile(updated);
      await _profileService.reload();
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã lưu hồ sơ cá nhân.');
    } catch (error) {
      _showMessage('Không thể lưu hồ sơ: $error');
    }
  }

  Future<void> _changeAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFile(type: FileType.image);
      if (result == null || !mounted) return;

      final sourceBytes = await result.xFile.readAsBytes();
      if (sourceBytes.isEmpty) {
        throw StateError('Không đọc được ảnh đã chọn.');
      }
      if (sourceBytes.length > 12 * 1024 * 1024) {
        throw StateError('Ảnh gốc quá lớn (tối đa 12 MB).');
      }

      final resizedBytes = await _resizeAvatar(sourceBytes);
      if (resizedBytes == null) {
        throw StateError('Không thể xử lý ảnh đã chọn.');
      }
      if (!mounted) return;
      if (resizedBytes.length > 1024 * 1024) {
        throw StateError('Ảnh sau khi thu nhỏ vẫn quá lớn để lưu.');
      }

      final updated = _profile.copyWith(
        avatarBase64: base64Encode(resizedBytes),
      );
      await _profileService.saveProfile(updated);
      if (!mounted) return;
      setState(() {});
      _showMessage('Đã cập nhật ảnh đại diện.');
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật ảnh đại diện: $error'),
          backgroundColor: _profileAccent,
        ),
      );
    }
  }

  Future<void> _openFavorites() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const IntroDialogPage(
          child: music_library.LibraryScreen(initialCategory: 'Yêu thích'),
        ),
      ),
    );
    await _refreshCounts();
  }

  Future<void> _openPlaylists() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const IntroDialogPage(child: PlaylistScreen()),
      ),
    );
    await _refreshCounts();
  }

  Future<void> _openHistory() async {
    final songs = _profileService.recentlyPlayed;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _profileCard,
        title: const Text(
          'Lịch sử nghe nhạc',
          style: TextStyle(color: _profileText),
        ),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width - 64, 370),
          height: min(max(songs.length, 1) * 68.0, 340),
          child: songs.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có bài hát nào được phát gần đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _profileSubText),
                  ),
                )
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: song.coverColor,
                        child: Icon(song.coverIcon, color: Colors.white),
                      ),
                      title: Text(
                        song.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _profileText),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: _profileSubText),
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openPlayer(song);
                      },
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
  }

  Future<void> _openPlayer(Song song) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          child: PlayerScreen(
            songName: song.name,
            artist: song.artist,
            coverColor: song.coverColor,
            coverIcon: song.coverIcon,
            audioUrl: song.audioUrl,
            song: song,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final onLogout = widget.onLogout;
    if (onLogout != null) {
      await onLogout();
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showAppearance() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _profileCard,
        title: const Text('Giao diện', style: TextStyle(color: _profileText)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.dark_mode_rounded, color: _profileAccent),
              title: Text('Tối', style: TextStyle(color: _profileText)),
              subtitle: Text(
                'Giao diện tối đang được sử dụng.',
                style: TextStyle(color: _profileSubText),
              ),
              trailing: Icon(Icons.check_circle, color: _profileAccent),
            ),
            Text(
              'Các màn hình hiện dùng màu cố định nên chưa hỗ trợ chuyển sang '
              'giao diện sáng.',
              style: TextStyle(color: _profileSubText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _profileCard,
        title: const Text(
          'Melody Music Player',
          style: TextStyle(color: _profileText),
        ),
        content: Text(
          'Ứng dụng nghe nhạc Melody.\nPhiên bản $_version'
          '${_versionError == null ? '' : '\nKhông đọc được phiên bản: $_versionError'}',
          style: const TextStyle(color: _profileSubText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVersion() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _profileCard,
        title: const Text(
          'Phiên bản ứng dụng',
          style: TextStyle(color: _profileText),
        ),
        content: Text(
          _versionError == null
              ? 'Melody Music Player $_version'
              : 'Không thể đọc phiên bản: $_versionError',
          style: const TextStyle(color: _profileSubText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _profileBackground,
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
                    _buildHeader(),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _profileAccent,
                              ),
                            )
                          : _loadError != null
                          ? _buildLoadError()
                          : _buildContent(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _profileText),
          ),
          const Expanded(
            child: Text(
              'Hồ sơ cá nhân',
              style: TextStyle(
                color: _profileText,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa hồ sơ',
            onPressed: _loading || _loadError != null ? null : _editProfile,
            icon: const Icon(Icons.edit_rounded, color: _profileAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
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
              'Không thể tải hồ sơ: $_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _profileSubText),
            ),
            TextButton(
              onPressed: () {
                setState(() => _loading = true);
                _loadData();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        _buildProfileCard(),
        const SizedBox(height: 14),
        _buildStatistics(),
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 3),
          child: Text(
            'TÀI KHOẢN',
            style: TextStyle(
              color: _profileSubText,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _buildOption(
          icon: Icons.manage_accounts_rounded,
          title: 'Chỉnh sửa hồ sơ',
          subtitle: 'Tên hiển thị và email tùy chọn',
          onTap: _editProfile,
        ),
        _buildOption(
          icon: Icons.favorite_rounded,
          title: 'Bài hát yêu thích',
          subtitle: '$_favoriteCount bài hát',
          onTap: _openFavorites,
        ),
        _buildOption(
          icon: Icons.queue_music_rounded,
          title: 'Playlist của tôi',
          subtitle: '$_playlistCount playlist',
          onTap: _openPlaylists,
        ),
        _buildOption(
          icon: Icons.history_rounded,
          title: 'Lịch sử nghe nhạc',
          subtitle: _profileService.recentlyPlayed.isEmpty
              ? 'Chưa có bài hát gần đây'
              : '${_profileService.recentlyPlayed.length} bài hát gần đây',
          onTap: _openHistory,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 22, bottom: 10, left: 3),
          child: Text(
            'ỨNG DỤNG',
            style: TextStyle(
              color: _profileSubText,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _buildOption(
          icon: Icons.palette_outlined,
          title: 'Giao diện',
          subtitle: 'Tối',
          onTap: _showAppearance,
        ),
        _buildOption(
          icon: Icons.info_outline_rounded,
          title: 'Giới thiệu ứng dụng',
          subtitle: 'Melody Music Player',
          onTap: _showAbout,
        ),
        _buildOption(
          icon: Icons.system_update_alt_rounded,
          title: 'Phiên bản ứng dụng',
          subtitle: _version,
          onTap: _showVersion,
        ),
        const SizedBox(height: 18),
        _buildOption(
          icon: Icons.logout_rounded,
          title: 'Đăng xuất',
          subtitle: 'Quay lại màn hình đăng nhập',
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final displayName = _profile.displayName.trim().isEmpty
        ? 'Người nghe nhạc'
        : _profile.displayName;
    final email = _profile.email;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _profileCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3A334B)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatar(size: 98),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: _profileAccent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _changeAvatar,
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _profileText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email == null || email.isEmpty ? 'Hồ sơ cục bộ' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _profileSubText, fontSize: 13),
          ),
          if (_profile.joinedAt != null) ...[
            const SizedBox(height: 7),
            Text(
              'Tham gia ${_formatDate(_profile.joinedAt!)}',
              style: const TextStyle(color: _profileSubText, fontSize: 12),
            ),
          ],
          const SizedBox(height: 11),
          TextButton.icon(
            onPressed: _changeAvatar,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Đổi ảnh đại diện'),
            style: TextButton.styleFrom(foregroundColor: _profileAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    final avatar = _profile.avatarBase64;
    if (avatar == null || avatar.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _profileAccent.withValues(alpha: 0.18),
        child: Icon(
          Icons.person_rounded,
          color: _profileAccent,
          size: size * 0.55,
        ),
      );
    }

    return ClipOval(
      child: Image.memory(
        base64Decode(avatar),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: _profileAccent.withValues(alpha: 0.18),
          child: Icon(
            Icons.person_rounded,
            color: _profileAccent,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _StatisticCard(
            icon: Icons.favorite_rounded,
            value: _favoriteCount.toString(),
            label: 'Yêu thích',
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _StatisticCard(
            icon: Icons.queue_music_rounded,
            value: _playlistCount.toString(),
            label: 'Playlist',
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: _profileCard,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _profileAccent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _profileAccent, size: 21),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _profileText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _profileSubText, fontSize: 11),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: _profileSubText,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _profileCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: _profileAccent, size: 21),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _profileText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: _profileSubText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm {
  final String displayName;
  final String? email;

  const _ProfileForm({required this.displayName, this.email});
}

Future<Uint8List?> _resizeAvatar(Uint8List sourceBytes) async {
  final codec = await ui.instantiateImageCodec(
    sourceBytes,
    targetWidth: 256,
    targetHeight: 256,
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Future<_ProfileForm?> _showEditProfileDialog(
  BuildContext context,
  LocalUserProfile profile,
) {
  return showDialog<_ProfileForm>(
    context: context,
    builder: (_) => _EditProfileDialog(profile: profile),
  );
}

class _EditProfileDialog extends StatefulWidget {
  final LocalUserProfile profile;

  const _EditProfileDialog({required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _emailController = TextEditingController(text: widget.profile.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _profileCard,
      title: const Text(
        'Chỉnh sửa hồ sơ',
        style: TextStyle(color: _profileText),
      ),
      content: SizedBox(
        width: min(MediaQuery.sizeOf(context).width - 64, 380),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 40,
                  style: const TextStyle(color: _profileText),
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    labelStyle: TextStyle(color: _profileSubText),
                    counterStyle: TextStyle(color: _profileSubText),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên hiển thị.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 100,
                  style: const TextStyle(color: _profileText),
                  decoration: const InputDecoration(
                    labelText: 'Email (không bắt buộc)',
                    labelStyle: TextStyle(color: _profileSubText),
                    counterStyle: TextStyle(color: _profileSubText),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty && !email.contains('@')) {
                      return 'Email chưa hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thông tin chỉ được lưu trên thiết bị, không dùng để đăng nhập.',
                  style: TextStyle(color: _profileSubText, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final email = _emailController.text.trim();
            Navigator.pop(
              context,
              _ProfileForm(
                displayName: _nameController.text.trim(),
                email: email.isEmpty ? null : email,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _profileAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
