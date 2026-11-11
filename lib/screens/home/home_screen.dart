import 'package:flutter/material.dart';

const Color bgColor = Color(0xFF15121F);
const Color cardColor = Color(0xFF252131);
const Color textColor = Colors.white;
const Color subTextColor = Color(0xFFB5B0C0);
const Color primaryColor = Color(0xFFB87553);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  bool isPlaying = true;

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
      'icon': Icons.waves,
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 1),
      ),
    );
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
          borderRadius: BorderRadius.circular(
            screenWidth > 430 ? 24 : 0,
          ),
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
                                onTap: () =>
                                    showMessage('Tất cả bài hát'),
                              ),
                              const SizedBox(height: 14),
                              _buildRecentSongs(),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                'Playlist nổi bật',
                                onTap: () =>
                                    showMessage('Tất cả playlist'),
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


  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.menu, color: textColor, size: 28),
        const SizedBox(width: 15),
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
        CircleAvatar(
          backgroundColor: primaryColor,
          child: IconButton(
            onPressed: () => showMessage('Tài khoản cá nhân'),
            icon: const Icon(Icons.person, color: Colors.white),
            splashRadius: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 205,
      padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Thưởng thức\nâm nhạc mọi lúc',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hàng triệu bài hát yêu thích',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => showMessage('Bắt đầu nghe nhạc'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Nghe ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.album, size: 90, color: Color(0xFFB58AEF)),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    return Row(
      children: shortcuts.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => showMessage(item['name'] as String),
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
                    Text(
                      item['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textColor, fontSize: 11),
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

  Widget _buildRecentSongs() {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final song = songs[index];

          return SizedBox(
            width: 145,
            child: InkWell(
              onTap: () => showMessage('Đang chọn ${song['name']}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 95,
                    width: 145,
                    decoration: BoxDecoration(
                      color: song['color'] as Color,
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
            onTap: () => showMessage(playlist['name'] as String),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Có Hẹn Với Thanh Xuân',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'MONO',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
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
            onPressed: () => showMessage('Bài tiếp theo'),
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

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
                onTap: () {
                  setState(() {
                    selectedTab = index;
                  });

                  if (index != 0) {
                    showMessage(items[index]['label'] as String);
                  }
                },
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
