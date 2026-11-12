import 'package:material_ui/material_ui.dart';

import '../player/player_screen.dart';

const Color bgColor = Color(0xFF15121F);
const Color cardColor = Color(0xFF252131);
const Color primaryColor = Color(0xFFB87553);
const Color textColor = Colors.white;
const Color subTextColor = Color(0xFFB5B0C0);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'Tất cả';

  final List<Map<String, dynamic>> songs = [
    {
      'name': 'Ánh Nắng Của Anh',
      'artist': 'Đức Phúc',
      'icon': Icons.wb_sunny,
      'color': const Color(0xFFE5A65B),
      'duration': '04:15',
      'favorite': true,
    },
    {
      'name': 'Thấy Em Là Thấy',
      'artist': 'Phạm Việt Thắng',
      'icon': Icons.favorite,
      'color': const Color(0xFFD87885),
      'duration': '03:45',
      'favorite': true,
    },
    {
      'name': 'Có Hẹn Với Thanh Xuân',
      'artist': 'MONSTAR',
      'icon': Icons.cloud,
      'color': const Color(0xFF7195C8),
      'duration': '04:20',
      'favorite': false,
    },
    {
      'name': 'Về Nhà',
      'artist': 'Chillies',
      'icon': Icons.home,
      'color': const Color(0xFF7A9A85),
      'duration': '03:52',
      'favorite': false,
    },
    {
      'name': 'Đổi Thay',
      'artist': 'Hồ Quang Hiếu',
      'icon': Icons.music_note,
      'color': const Color(0xFF987BC1),
      'duration': '04:05',
      'favorite': true,
    },
  ];

  List<Map<String, dynamic>> get filteredSongs {
    return songs.where((song) {
      final name = song['name'].toString().toLowerCase();
      final artist = song['artist'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      final matchesSearch = name.contains(query) || artist.contains(query);

      final matchesCategory =
          selectedCategory == 'Tất cả' ||
          (selectedCategory == 'Yêu thích' && song['favorite'] == true);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void openPlayer(Map<String, dynamic> song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          songName: song['name'] as String,
          artist: song['artist'] as String,
          coverColor: song['color'] as Color,
          coverIcon: song['icon'] as IconData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedSongs = filteredSongs;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Thư viện nhạc',
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: textColor),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.library_music,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bộ sưu tập của bạn',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${songs.length} bài hát',
                          style: const TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: textColor),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm bài hát hoặc ca sĩ...',
                  hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: subTextColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bộ lọc
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Tất cả', 'Yêu thích'].map((category) {
                  final selected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? primaryColor : cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: selected ? Colors.white : subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Tiêu đề danh sách
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tất cả bài hát',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${displayedSongs.length} bài',
                    style: const TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Danh sách bài hát
            Expanded(
              child: displayedSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy bài hát',
                        style: TextStyle(color: subTextColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayedSongs.length,
                      itemBuilder: (context, index) {
                        final song = displayedSongs[index];

                        return GestureDetector(
                          onTap: () => openPlayer(song),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: song['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    song['icon'],
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        song['artist'],
                                        style: const TextStyle(
                                          color: subTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  song['duration'],
                                  style: const TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Icon(
                                  Icons.play_circle_outline,
                                  color: primaryColor,
                                  size: 27,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
