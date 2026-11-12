import 'package:material_ui/material_ui.dart';

import '../../models/song.dart';
import '../search/search_screen.dart';
import '../../widgets/intro_dialog_page.dart';

import '../menu/menu_screen.dart';
import '../playlist/playlist_screen.dart';
import '../profile/profile_screen.dart';
import '../player/player_screen.dart';
import '../library/library_screen.dart' as music_library;

const Color bgColor = Color(0xFF15121F);
const Color cardColor = Color(0xFF252131);
const Color textColor = Colors.white;
const Color subTextColor = Color(0xFFB5B0C0);
const Color primaryColor = Color(0xFFB87553);

class HomeScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  bool isPlaying = true;

  String currentSong = 'Có Hẹn Với Thanh Xuân';
  String currentArtist = 'MoMo';

  final List<Map<String, dynamic>> songs = [
    {
      'name': 'Ánh Nắng Của Anh',
      'artist': 'Đức Phúc',
      'icon': Icons.wb_sunny,
      'color': const Color(0xFFB87553),
    },
    {
      'name': 'Thấy Em Là Thấy',
      'artist': 'Phạm Việt Thắng',
      'icon': Icons.cloud,
      'color': const Color(0xFF7776C8),
    },
    {
      'name': 'Có Hẹn Với Thanh Xuân',
      'artist': 'MoMo',
      'icon': Icons.nightlife,
      'color': const Color(0xFF984C83),
    },
    {
      'name': 'Về Nhà',
      'artist': 'Chillies',
      'icon': Icons.waves,
      'color': const Color(0xFF53617E),
    },
    {
      'name': 'Đổi Thay',
      'artist': 'Hồ Quang Hiếu',
      'icon': Icons.music_note,
      'color': const Color(0xFF53617E),
    },
  ];

  final List<Map<String, dynamic>> playlists = [
    {
      'name': 'Top Hits Việt Nam',
      'icon': Icons.headphones,
      'color': const Color(0xFF7952C7),
    },
    {
      'name': 'Lo-fi Chill',
      'icon': Icons.nightlight_round,
      'color': const Color(0xFF455A88),
    },
    {
      'name': 'Nhạc Tập Trung',
      'icon': Icons.laptop,
      'color': const Color(0xFF6546A5),
    },
    {
      'name': 'Nhạc Thư Giãn',
      'icon': Icons.spa,
      'color': const Color(0xFF426B55),
    },
  ];

  final List<Map<String, dynamic>> shortcuts = [
    {'name': 'Tất cả bài hát', 'icon': Icons.music_note},
    {'name': 'Playlist', 'icon': Icons.queue_music},
    {'name': 'Yêu thích', 'icon': Icons.favorite_border},
    {'name': 'Tải xuống', 'icon': Icons.download},
  ];

  // Hiển thị thông báo
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Mở thư viện nhạc
  Future<void> openLibrary({String initialCategory = 'Tất cả'}) async {
    setState(() {
      selectedTab = 1;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          child: music_library.LibraryScreen(initialCategory: initialCategory),
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedTab = 0;
    });
  }

  Future<void> openSearch() async {
    setState(() {
      selectedTab = 2;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IntroDialogPage(child: SearchScreen()),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedTab = 0;
    });
  }

  Future<void> openPlaylists() async {
    setState(() {
      selectedTab = 3;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IntroDialogPage(child: PlaylistScreen()),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedTab = 0;
    });
  }

  Future<void> openProfile() async {
    setState(() {
      selectedTab = 4;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            IntroDialogPage(child: ProfileScreen(onLogout: widget.onLogout)),
      ),
    );

    if (!mounted) return;

    setState(() {
      selectedTab = 0;
    });
  }

  Future<void> openMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IntroDialogPage(child: MenuScreen()),
      ),
    );
  }

  // Mở trang phát nhạc
  void openPlayer(Map<String, dynamic> song) {
    final track = Song.fromMap(song, songIdForName(song['name'] as String));
    setState(() {
      currentSong = song['name'] as String;
      currentArtist = song['artist'] as String;
      isPlaying = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          child: PlayerScreen(
            songName: song['name'] as String,
            artist: song['artist'] as String,
            coverColor: song['color'] as Color,
            coverIcon: song['icon'] as IconData,
            audioUrl: track.audioUrl,
            song: track,
          ),
        ),
      ),
    );
  }

  // Xử lý các ô chức năng
  void handleShortcut(String name) {
    switch (name) {
      case 'Tất cả bài hát':
        openLibrary();
        break;

      case 'Playlist':
        openPlaylists();
        break;

      case 'Yêu thích':
        openLibrary(initialCategory: 'Yêu thích');
        break;

      case 'Tải xuống':
        showMessage('Chức năng Tải xuống đang được phát triển');
        break;
    }
  }

  // Điều hướng
  void handleNavigation(int index) {
    if (index == 0) {
      setState(() {
        selectedTab = 0;
      });
      return;
    }

    if (index == 1) {
      openLibrary();
      return;
    }

    if (index == 2) {
      openSearch();
      return;
    }

    if (index == 3) {
      openPlaylists();
      return;
    }

    if (index == 4) {
      openProfile();
      return;
    }

    setState(() {
      selectedTab = index;
    });

    final labels = ['Trang chủ', 'Thư viện', 'Tìm kiếm', 'Playlist', 'Cá nhân'];

    showMessage('Chức năng ${labels[index]} đang được phát triển');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final phoneWidth = screenWidth > 430 ? 390.0 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B13),
      body: Center(
        child: SizedBox(
          width: phoneWidth,
          height: screenHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth > 430 ? 24 : 0),
            child: Scaffold(
              backgroundColor: bgColor,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(18),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _buildHeader(),
                                const SizedBox(height: 22),
                                _buildBanner(),
                                const SizedBox(height: 22),
                                _buildShortcuts(),
                                const SizedBox(height: 18),

                                _buildSectionTitle(
                                  'Nghe gần đây',
                                  onTap: openLibrary,
                                ),

                                const SizedBox(height: 14),
                                _buildRecentSongs(),
                                const SizedBox(height: 24),

                                _buildSectionTitle(
                                  'Playlist nổi bật',
                                  onTap: openPlaylists,
                                ),

                                const SizedBox(height: 14),
                                _buildPlaylistRow(),
                                const SizedBox(height: 20),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildMiniPlayer(),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNavigation(),
            ),
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: openMenu,
          icon: const Icon(Icons.menu, color: textColor, size: 28),
        ),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 32),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Melody',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Music Player',
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () => showMessage('Thông báo'),
          icon: const Icon(
            Icons.notifications_none,
            color: textColor,
            size: 27,
          ),
        ),

        InkWell(
          onTap: openProfile,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            backgroundColor: primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // BANNER
  Widget _buildBanner() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF49385E)),
        gradient: const LinearGradient(
          colors: [Color(0xFF302541), Color(0xFF211B30), Color(0xFF49316B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Thưởng thức\nâm nhạc mọi lúc',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Hàng triệu bài hát yêu thích',
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),

                  const SizedBox(height: 6),

                  ElevatedButton.icon(
                    onPressed: () => openPlayer(songs[0]),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Nghe ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 5),

          const Icon(Icons.album, size: 50, color: Color(0xFFB58AEF)),
        ],
      ),
    );
  }

  // SHORTCUTS
  Widget _buildShortcuts() {
    return Row(
      children: shortcuts.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () {
                handleShortcut(item['name'] as String);
              },
              child: Container(
                height: 112,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFF3A334B)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                      size: 31,
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        item['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title, {required VoidCallback onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        TextButton(
          onPressed: onTap,
          child: const Text(
            'Xem tất cả ›',
            style: TextStyle(color: primaryColor, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // RECENT SONGS
  Widget _buildRecentSongs() {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final song = songs[index];

          return SizedBox(
            width: 145,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => openPlayer(song),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 95,
                    width: 145,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [song['color'] as Color, cardColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          song['icon'] as IconData,
                          color: Colors.white70,
                          size: 48,
                        ),

                        const Positioned(
                          right: 8,
                          bottom: 8,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    song['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  Text(
                    song['artist'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // PLAYLIST
  Widget _buildPlaylistRow() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final playlist = playlists[index];

          return InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: openPlaylists,
            child: Container(
              width: 145,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFF49385E)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [playlist['color'] as Color, cardColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    playlist['icon'] as IconData,
                    color: Colors.white,
                    size: 40,
                  ),

                  Text(
                    playlist['name'] as String,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MINI PLAYER
  Widget _buildMiniPlayer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF49385E)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF984C83),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: InkWell(
              onTap: () {
                final song = songs.firstWhere(
                  (song) => song['name'] == currentSong,
                  orElse: () => songs[0],
                );

                openPlayer(song);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  Text(
                    currentArtist,
                    style: const TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                isPlaying = !isPlaying;
              });
            },
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: primaryColor,
              size: 35,
            ),
          ),

          IconButton(
            onPressed: () {
              final currentIndex = songs.indexWhere(
                (song) => song['name'] == currentSong,
              );

              final nextIndex = (currentIndex + 1) % songs.length;

              setState(() {
                currentSong = songs[nextIndex]['name'] as String;
                currentArtist = songs[nextIndex]['artist'] as String;
              });

              showMessage('Đã chọn bài tiếp theo');
            },
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    final items = [
      {'icon': Icons.home, 'label': 'Trang chủ'},
      {'icon': Icons.library_music, 'label': 'Thư viện'},
      {'icon': Icons.search, 'label': 'Tìm kiếm'},
      {'icon': Icons.queue_music, 'label': 'Playlist'},
      {'icon': Icons.person_outline, 'label': 'Cá nhân'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Color(0xFF302A3D))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = selectedTab == index;

            return Expanded(
              child: InkWell(
                onTap: () => handleNavigation(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: selected ? primaryColor : subTextColor,
                        size: 25,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          color: selected ? primaryColor : subTextColor,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
