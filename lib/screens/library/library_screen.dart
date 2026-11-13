import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../models/song.dart';
import '../../services/local_profile_service.dart';
import '../playlist/playlist_screen.dart';
import '../player/player_screen.dart';
import '../../widgets/intro_dialog_page.dart';

const Color bgColor = AppColors.background;
const Color cardColor = AppColors.surface;
const Color primaryColor = AppColors.primary;
const Color textColor = AppColors.white;
const Color subTextColor = AppColors.secondaryText;

class LibraryScreen extends StatefulWidget {
  final String initialCategory;

  const LibraryScreen({super.key, this.initialCategory = 'Tất cả'});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  late String selectedCategory;

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

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final service = LocalProfileService.instance;
      await service.load();
      if (!mounted) return;
      setState(() {
        for (final song in songs) {
          song['favorite'] = service.isFavorite(
            songIdForName(song['name'] as String),
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải bài hát yêu thích: $error'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredSongs {
    return songs.where((song) {
      final name = song['name'].toString().toLowerCase();
      final artist = song['artist'].toString().toLowerCase();
      final query = searchQuery.toLowerCase().trim();

      final matchesSearch = name.contains(query) || artist.contains(query);

      final matchesCategory =
          selectedCategory == 'Tất cả' ||
          (selectedCategory == 'Yêu thích' && song['favorite'] == true);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void openPlayer(Map<String, dynamic> song) {
    final track = _toSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IntroDialogPage(
          screenId: 'player',
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

  Song _toSong(Map<String, dynamic> map) {
    final name = map['name'] as String;
    return Song.fromMap(map, songIdForName(name));
  }

  Future<void> toggleFavorite(Map<String, dynamic> song) async {
    final id = songIdForName(song['name'] as String);

    try {
      final service = LocalProfileService.instance;
      await service.load();
      final favorite = !service.isFavorite(id);
      await service.setFavorite(id, favorite);
      if (mounted) {
        setState(() {
          song['favorite'] = favorite;
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật yêu thích: $error'),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SizedBox(
                  width: double.infinity,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCollectionCard(),
                            _buildSearchBar(),
                            _buildCategoryTabs(),
                            _buildListTitle(),
                            Expanded(child: _buildSongList()),
                          ],
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

  Widget _buildHeader() {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: textColor, size: 25),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Thư viện nhạc',
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: textColor),
              color: cardColor,
              onSelected: (value) {
                setState(() {
                  selectedCategory = value == 'favorite'
                      ? 'Yêu thích'
                      : 'Tất cả';
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'all',
                  child: Text(
                    'Tất cả bài hát',
                    style: TextStyle(color: textColor),
                  ),
                ),
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(
                    'Bài hát yêu thích',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.library_music,
                color: primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bộ sưu tập của bạn',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${songs.length} bài hát',
                    style: const TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        height: 56,
        child: TextField(
          controller: searchController,
          style: const TextStyle(color: textColor),
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Tìm bài hát hoặc ca sĩ...',
            hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: subTextColor),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() => searchQuery = '');
                    },
                    icon: const Icon(Icons.close, color: subTextColor),
                  )
                : null,
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      child: Row(
        children: ['Tất cả', 'Yêu thích'].map((category) {
          final selected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: selected ? Colors.white : subTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedCategory == 'Tất cả'
                ? 'Tất cả bài hát'
                : 'Bài hát yêu thích',
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${filteredSongs.length} bài',
            style: const TextStyle(color: subTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    final displayedSongs = filteredSongs;

    if (displayedSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, color: subTextColor, size: 45),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy bài hát',
              style: TextStyle(color: subTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      itemCount: displayedSongs.length,
      itemBuilder: (context, index) {
        final song = displayedSongs[index];

        return GestureDetector(
          onTap: () => openPlayer(song),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: song['color'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    song['icon'] as IconData,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        song['artist'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  song['duration'] as String,
                  style: const TextStyle(color: subTextColor, fontSize: 12),
                ),
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => toggleFavorite(song),
                  icon: Icon(
                    song['favorite'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: song['favorite'] == true
                        ? primaryColor
                        : subTextColor,
                    size: 19,
                  ),
                ),
                IconButton(
                  tooltip: 'Thêm vào playlist',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      showAddSongToPlaylistDialog(context, _toSong(song)),
                  icon: const Icon(
                    Icons.playlist_add_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
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
    );
  }
}
