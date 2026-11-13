import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/local_profile_service.dart';
import 'package:lttbdd_nhom8/music/music_player_service.dart';
import 'package:lttbdd_nhom8/music/playlist_service.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:lttbdd_nhom8/admin/song_management_screen.dart';
import 'package:lttbdd_nhom8/admin/account_management_screen.dart';
import 'package:lttbdd_nhom8/music/library_screen.dart';
import 'package:lttbdd_nhom8/music/player_screen.dart';
import 'package:lttbdd_nhom8/music/playlist_screen.dart';
import 'package:lttbdd_nhom8/user/profile_screen.dart';

const Color _menuBackground = AppColors.background;
const Color _menuCardColor = AppColors.surface;
const Color _menuAccent = AppColors.primary;
const Color _menuText = AppColors.white;
const Color _menuSubText = AppColors.secondaryText;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MusicPlayerService _music = MusicPlayerService.instance;
  final LocalProfileService _profile = LocalProfileService.instance;
  final PlaylistService _playlists = PlaylistService.instance;

  bool _loading = true;
  String? _loadError;
  String _version = 'Đang tải...';
  String? _versionError;
  int _playlistCount = 0;
  late final StreamSubscription<void> _sleepTimerCompletedSubscription;
  late final StreamSubscription<Object> _sleepTimerErrorSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadVersion();
    _sleepTimerCompletedSubscription = _music.sleepTimerCompleted.listen((_) {
      _showMessage('Hẹn giờ kết thúc: đã dừng phát nhạc.');
      if (mounted) setState(() {});
    });
    _sleepTimerErrorSubscription = _music.sleepTimerErrors.listen(
      (error) => _showMessage('Không thể dừng nhạc theo hẹn giờ: $error'),
      onError: (Object error, StackTrace stackTrace) {
        _showMessage('Không thể dừng nhạc theo hẹn giờ: $error');
      },
    );
  }

  @override
  void dispose() {
    _sleepTimerCompletedSubscription.cancel();
    _sleepTimerErrorSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _profile.load(),
        _playlists.load(),
        _music.loadPlaybackSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _playlistCount = _playlists.playlists.length;
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
      SnackBar(content: Text(message), backgroundColor: _menuAccent),
    );
  }

  Future<void> _openProfile() =>
      _openPage('profile', ProfileScreen(onLogout: widget.onLogout));

  Future<void> _openAccountManagement() =>
      _openPage('account_management', const AccountManagementScreen());

  Future<void> _openLibrary() => _openPage('library', const LibraryScreen());

  Future<void> _openSongManagement() =>
      _openPage('song_management', const SongManagementScreen());

  Future<void> _openPlaylists() =>
      _openPage('playlist', const PlaylistScreen());

  Future<void> _openPage(String screenId, Widget page) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(screenId: screenId, child: page),
      ),
    );
  }

  Future<void> _openHistory() async {
    final songs = _profile.recentlyPlayed;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _menuCardColor,
        title: const Text(
          'Lịch sử nghe nhạc',
          style: TextStyle(color: _menuText),
        ),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width - 64, 370),
          height: min(max(songs.length, 1) * 68.0, 340),
          child: songs.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có bài hát nào được phát gần đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _menuSubText),
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
                        style: const TextStyle(color: _menuText),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: _menuSubText),
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
    await _openPage(
      'player',
      PlayerScreen(
        songName: song.name,
        artist: song.artist,
        coverColor: song.coverColor,
        coverIcon: song.coverIcon,
        audioUrl: song.audioUrl,
        song: song,
      ),
    );
  }

  Future<void> _toggleShuffle(bool enabled) async {
    if (_music.isShuffle == enabled) return;
    try {
      await _music.toggleShuffle();
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage('Không thể lưu chế độ phát ngẫu nhiên: $error');
    }
  }

  Future<void> _chooseRepeatMode() async {
    final selectedMode = await showDialog<LoopMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _menuCardColor,
        title: const Text('Chế độ lặp lại', style: TextStyle(color: _menuText)),
        content: RadioGroup<LoopMode>(
          groupValue: _music.loopMode,
          onChanged: (value) {
            if (value != null) Navigator.pop(dialogContext, value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _repeatOption(LoopMode.off, 'Tắt lặp'),
              _repeatOption(LoopMode.one, 'Lặp bài hát'),
              _repeatOption(LoopMode.all, 'Lặp danh sách'),
            ],
          ),
        ),
      ),
    );
    if (selectedMode == null || !mounted) return;

    try {
      await _music.setRepeatMode(selectedMode);
      if (mounted) setState(() {});
    } catch (error) {
      _showMessage('Không thể đổi chế độ lặp: $error');
    }
  }

  Widget _repeatOption(LoopMode mode, String label) {
    return RadioListTile<LoopMode>(
      value: mode,
      activeColor: _menuAccent,
      title: Text(label, style: const TextStyle(color: _menuText)),
    );
  }

  Future<void> _chooseSleepTimer() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _menuCardColor,
        title: const Text(
          'Hẹn giờ tắt nhạc',
          style: TextStyle(color: _menuText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in const [15, 30, 45, 60])
              ListTile(
                title: Text(
                  '$value phút',
                  style: const TextStyle(color: _menuText),
                ),
                onTap: () => Navigator.pop(dialogContext, value),
              ),
            if (_music.sleepTimerDeadline != null)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 0),
                child: const Text('Hủy hẹn giờ hiện tại'),
              ),
          ],
        ),
      ),
    );
    if (minutes == null || !mounted) return;

    if (minutes == 0) {
      _music.cancelSleepTimer();
      setState(() {});
      _showMessage('Đã hủy hẹn giờ tắt nhạc.');
      return;
    }

    _music.startSleepTimer(Duration(minutes: minutes));
    setState(() {});
    _showMessage('Nhạc sẽ tự dừng sau $minutes phút.');
  }

  Future<void> _showAudioQuality() => _showInformation(
    title: 'Chất lượng âm thanh',
    message:
        'Trình phát hiện sử dụng URL âm thanh có sẵn của từng bài hát. '
        'Nguồn nhạc hiện không cung cấp nhiều mức chất lượng để lựa chọn.',
  );

  Future<void> _showAppearance() => _showInformation(
    title: 'Giao diện',
    message:
        'Ứng dụng hiện sử dụng giao diện tối tím; tùy chọn đổi giao diện '
        'chưa khả dụng.',
  );

  Future<void> _showNotifications() => _showInformation(
    title: 'Thông báo',
    message:
        'Ứng dụng chưa tích hợp quyền thông báo hoặc dịch vụ chạy nền. '
        'Không có thông báo nào được bật.',
  );

  Future<void> _showAbout() => _showInformation(
    title: 'Melody Music Player',
    message:
        'Ứng dụng nghe nhạc Melody.\nPhiên bản $_version'
        '${_versionError == null ? '' : '\nKhông đọc được phiên bản: $_versionError'}',
  );

  Future<void> _showVersion() => _showInformation(
    title: 'Phiên bản ứng dụng',
    message: _versionError == null
        ? 'Melody Music Player $_version'
        : 'Không thể đọc phiên bản: $_versionError',
  );

  Future<void> _showInformation({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _menuCardColor,
        title: Text(title, style: const TextStyle(color: _menuText)),
        content: Text(
          message,
          style: const TextStyle(color: _menuSubText, height: 1.5),
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

  String get _sleepTimerSubtitle {
    final deadline = _music.sleepTimerDeadline;
    if (deadline == null) return 'Tự dừng nhạc sau 15, 30, 45 hoặc 60 phút';
    final remaining = deadline.difference(DateTime.now());
    final minutes = max(1, (remaining.inSeconds / 60).ceil());
    return 'Nhạc sẽ dừng sau khoảng $minutes phút';
  }

  String _repeatModeLabel(LoopMode mode) => switch (mode) {
    LoopMode.off => 'Tắt lặp',
    LoopMode.one => 'Lặp bài hát',
    LoopMode.all => 'Lặp danh sách',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _menuBackground,
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
                                color: _menuAccent,
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
            icon: const Icon(Icons.arrow_back_rounded, color: _menuText),
          ),
          const Expanded(
            child: Text(
              'MENU',
              style: TextStyle(
                color: _menuText,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
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
              'Không thể tải dữ liệu menu: $_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _menuSubText),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _sectionTitle('TÀI KHOẢN VÀ CÁ NHÂN'),
        _menuCard([
          _menuTile(
            icon: Icons.person_outline_rounded,
            title: 'Hồ sơ cá nhân',
            subtitle: _profile.profile.displayName.isEmpty
                ? 'Thông tin hồ sơ trên thiết bị'
                : _profile.profile.displayName,
            onTap: _openProfile,
          ),
          if (AuthService.instance.isAdmin)
            _menuTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Quản lý tài khoản',
              subtitle: 'Danh sách người dùng đã đăng ký',
              onTap: _openAccountManagement,
            ),
          _menuTile(
            icon: Icons.library_music_rounded,
            title: 'Thư viện của tôi',
            subtitle: 'Bài hát và mục yêu thích',
            onTap: _openLibrary,
          ),
          if (AuthService.instance.isAdmin)
            _menuTile(
              icon: Icons.library_add_rounded,
              title: 'Quản lý bài hát',
              subtitle: 'Thêm, sửa hoặc xóa trong thư viện chung',
              onTap: _openSongManagement,
            ),
          _menuTile(
            icon: Icons.queue_music_rounded,
            title: 'Playlist của tôi',
            subtitle: '$_playlistCount playlist',
            onTap: _openPlaylists,
          ),
          _menuTile(
            icon: Icons.history_rounded,
            title: 'Lịch sử nghe nhạc',
            subtitle: _profile.recentlyPlayed.isEmpty
                ? 'Chưa có bài hát đã phát'
                : '${_profile.recentlyPlayed.length} bài hát gần đây',
            onTap: _openHistory,
            isLast: true,
          ),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('ÂM NHẠC'),
        _menuCard([
          _menuTile(
            icon: Icons.shuffle_rounded,
            title: 'Phát ngẫu nhiên',
            subtitle: _music.isShuffle ? 'Đang bật' : 'Đang tắt',
            trailing: Switch(
              value: _music.isShuffle,
              activeThumbColor: _menuAccent,
              onChanged: _toggleShuffle,
            ),
            onTap: () => _toggleShuffle(!_music.isShuffle),
          ),
          _menuTile(
            icon: Icons.repeat_rounded,
            title: 'Chế độ lặp lại',
            subtitle: _repeatModeLabel(_music.loopMode),
            onTap: _chooseRepeatMode,
          ),
          _menuTile(
            icon: Icons.timer_outlined,
            title: 'Hẹn giờ tắt nhạc',
            subtitle: _sleepTimerSubtitle,
            onTap: _chooseSleepTimer,
          ),
          _menuTile(
            icon: Icons.graphic_eq_rounded,
            title: 'Chất lượng âm thanh',
            subtitle: 'Theo URL nguồn nhạc',
            onTap: _showAudioQuality,
            isLast: true,
          ),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('CÀI ĐẶT ỨNG DỤNG'),
        _menuCard([
          _menuTile(
            icon: Icons.palette_outlined,
            title: 'Giao diện sáng/tối',
            subtitle: 'Đang sử dụng giao diện tối',
            onTap: _showAppearance,
          ),
          _menuTile(
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            subtitle: 'Kiểm tra hỗ trợ thông báo',
            onTap: _showNotifications,
          ),
          _menuTile(
            icon: Icons.info_outline_rounded,
            title: 'Giới thiệu ứng dụng',
            subtitle: 'Melody Music Player',
            onTap: _showAbout,
          ),
          _menuTile(
            icon: Icons.system_update_alt_rounded,
            title: 'Phiên bản ứng dụng',
            subtitle: _version,
            onTap: _showVersion,
            isLast: true,
          ),
        ]),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: _menuSubText,
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Material(
      color: _menuCardColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: _menuAccent),
          title: Text(
            title,
            style: const TextStyle(
              color: _menuText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _menuSubText, fontSize: 11),
          ),
          trailing:
              trailing ??
              const Icon(Icons.chevron_right_rounded, color: _menuSubText),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 58,
            endIndent: 14,
            color: AppColors.border,
          ),
      ],
    );
  }
}
