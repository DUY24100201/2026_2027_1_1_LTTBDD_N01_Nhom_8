import 'package:material_ui/material_ui.dart';

import '../../models/song.dart';
import '../playlist/playlist_screen.dart';
import '../player/player_screen.dart';
import '../../widgets/intro_dialog_page.dart';

const Color bgColor = Color(0xFF15121F);
const Color cardColor = Color(0xFF252131);
const Color primaryColor = Color(0xFFB87553);
const Color textColor = Colors.white;
const Color subTextColor = Color(0xFFB5B0C0);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  String searchQuery = '';
  String selectedFilter = 'Tất cả';

  final List<Map<String, dynamic>> songs = [
    {
      'name': 'Ánh Nắng Của Anh',
      'artist': 'Đức Phúc',
      'album': 'Ánh Nắng Của Anh',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFE5A65B),
      'duration': '04:15',
      'audioUrl': '',
    },
    {
      'name': 'Thấy Em Là Thấy',
      'artist': 'Phạm Việt Thắng',
      'album': 'Thấy Em Là Thấy',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFD87885),
      'duration': '03:45',
      'audioUrl': '',
    },
    {
      'name': 'Có Hẹn Với Thanh Xuân',
      'artist': 'MONSTAR',
      'album': 'Có Hẹn Với Thanh Xuân',
      'icon': Icons.cloud_rounded,
      'color': const Color(0xFF7195C8),
      'duration': '04:20',
      'audioUrl': '',
    },
    {
      'name': 'Về Nhà',
      'artist': 'Chillies',
      'album': 'Qua Khung Cửa Sổ',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF7A9A85),
      'duration': '03:52',
      'audioUrl': '',
    },
    {
      'name': 'Đổi Thay',
      'artist': 'Hồ Quang Hiếu',
      'album': 'Đổi Thay',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFF987BC1),
      'duration': '04:05',
      'audioUrl': '',
    },
  ];

  final List<String> filters = ['Tất cả', 'Bài hát', 'Ca sĩ', 'Album'];

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  String normalize(String value) {
    return value.trim().toLowerCase();
  }

  List<Map<String, dynamic>> get filteredSongs {
    final query = normalize(searchQuery);

    if (query.isEmpty) return [];

    return songs.where((song) {
      final name = normalize(song['name'].toString());
      final artist = normalize(song['artist'].toString());
      final album = normalize(song['album'].toString());

      switch (selectedFilter) {
        case 'Bài hát':
          return name.contains(query);
        case 'Ca sĩ':
          return artist.contains(query);
        case 'Album':
          return album.contains(query);
        default:
          return name.contains(query) ||
              artist.contains(query) ||
              album.contains(query);
      }
    }).toList();
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
  }

  void clearSearch() {
    searchController.clear();

    setState(() {
      searchQuery = '';
    });

    searchFocusNode.requestFocus();
  }

  void openPlayer(Map<String, dynamic> song) {
    final track = _toSong(song);
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

  Song _toSong(Map<String, dynamic> map) {
    final name = map['name'] as String;
    return Song.fromMap(map, name.trim().toLowerCase());
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: textColor),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KHÁM PHÁ',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tìm kiếm',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: searchFocusNode.hasFocus
              ? primaryColor.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 17),

          const Icon(Icons.search_rounded, color: primaryColor, size: 25),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
              style: const TextStyle(color: textColor, fontSize: 14),
              cursorColor: primaryColor,
              decoration: const InputDecoration(
                hintText: 'Bài hát, ca sĩ hoặc album...',
                hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          if (searchQuery.isNotEmpty)
            IconButton(
              onPressed: clearSearch,
              icon: const Icon(
                Icons.close_rounded,
                color: subTextColor,
                size: 20,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.tune_rounded, color: subTextColor, size: 21),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? primaryColor : cardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.white : subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    final title = searchQuery.isEmpty ? 'Gợi ý tìm kiếm' : 'Kết quả tìm kiếm';

    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (searchQuery.isNotEmpty)
            Text(
              '${filteredSongs.length} kết quả',
              style: const TextStyle(color: subTextColor, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildSongItem(Map<String, dynamic> song, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openPlayer(song),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: song['color'] as Color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    song['icon'] as IconData,
                    color: Colors.white,
                    size: 26,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        song['artist'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        song['album'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  song['duration'] as String,
                  style: const TextStyle(color: subTextColor, fontSize: 11),
                ),

                const SizedBox(width: 5),

                IconButton(
                  tooltip: 'Thêm vào playlist',
                  onPressed: () =>
                      showAddSongToPlaylistDialog(context, _toSong(song)),
                  icon: const Icon(
                    Icons.playlist_add_rounded,
                    color: primaryColor,
                    size: 25,
                  ),
                ),

                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: primaryColor,
                  size: 29,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      {
        'title': 'Nhạc Việt',
        'subtitle': 'Những ca khúc Việt Nam',
        'icon': Icons.music_note_rounded,
        'color': const Color(0xFFB87553),
        'query': 'Việt',
      },
      {
        'title': 'Tình yêu',
        'subtitle': 'Giai điệu về tình yêu',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFD87885),
        'query': 'Thấy',
      },
      {
        'title': 'Chill',
        'subtitle': 'Âm nhạc thư giãn',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF7195C8),
        'query': 'Chillies',
      },
    ];

    return Column(
      children: suggestions.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                searchController.text = item['query'] as String;
                onSearchChanged(item['query'] as String);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: subTextColor,
                      size: 15,
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

  Widget _buildEmptyResult() {
    return Padding(
      padding: const EdgeInsets.only(top: 65),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: subTextColor,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Thử tìm bằng tên bài hát hoặc ca sĩ khác nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredSongs;

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
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
                          children: [
                            _buildSearchBox(),

                            const SizedBox(height: 18),

                            _buildFilters(),

                            _buildSectionTitle(),

                            if (searchQuery.isEmpty)
                              _buildSuggestions()
                            else if (results.isEmpty)
                              _buildEmptyResult()
                            else
                              ...results.asMap().entries.map(
                                (entry) =>
                                    _buildSongItem(entry.value, entry.key),
                              ),

                            if (searchQuery.isEmpty) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Tìm kiếm bài hát yêu thích của bạn',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
}
