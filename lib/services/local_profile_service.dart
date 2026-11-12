import 'dart:convert';

import '../models/local_user_profile.dart';
import '../models/song.dart';
import 'storage_service.dart';

class LocalProfileService {
  LocalProfileService._();

  static final LocalProfileService instance = LocalProfileService._();

  static const String _profileKey = StorageService.userProfileKey;
  static const String _favoriteIdsKey = StorageService.favoriteSongsKey;
  static const String _recentSongsKey = StorageService.listeningHistoryKey;
  static const String _legacyProfileKey = 'melody_local_profile_v1';
  static const String _legacyFavoriteIdsKey = 'melody_favorite_song_ids_v1';
  static const String _legacyRecentSongsKey = 'melody_recent_songs_v1';
  static const Set<String> _initialFavoriteIds = {
    'ánh nắng của anh',
    'thấy em là thấy',
    'đổi thay',
  };
  static const int _maxRecentSongs = 20;

  LocalUserProfile _profile = const LocalUserProfile();
  Set<String> _favoriteIds = {};
  List<Song> _recentSongs = [];
  bool _loaded = false;

  LocalUserProfile get profile => _profile;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Song> get recentlyPlayed => List.unmodifiable(_recentSongs);

  Future<void> load() async {
    if (_loaded) return;

    final storage = StorageService.instance;
    var profileJson = await storage.readString(_profileKey);
    var migrateProfile = false;
    if (profileJson == null) {
      profileJson = await storage.readLegacyString(_legacyProfileKey);
      migrateProfile = profileJson != null;
    }

    var loadedProfile = const LocalUserProfile();
    if (profileJson != null) {
      final decoded = jsonDecode(profileJson);
      if (decoded is! Map) {
        throw const FormatException('Dữ liệu hồ sơ không hợp lệ.');
      }
      loadedProfile = LocalUserProfile.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    }

    var favoriteIds = await storage.readString(_favoriteIdsKey);
    var loadedFavoriteIds = <String>{};
    var migrateFavorites = false;
    if (favoriteIds != null) {
      loadedFavoriteIds = _decodeStringList(favoriteIds, 'yêu thích').toSet();
    } else {
      final legacyFavorites = await storage.readLegacyStringList(
        _legacyFavoriteIdsKey,
      );
      if (legacyFavorites == null) {
        loadedFavoriteIds = {..._initialFavoriteIds};
        migrateFavorites = true;
      } else {
        loadedFavoriteIds = legacyFavorites.toSet();
        migrateFavorites = true;
      }
    }

    var recentJson = await storage.readString(_recentSongsKey);
    var migrateHistory = false;
    if (recentJson == null) {
      recentJson = await storage.readLegacyString(_legacyRecentSongsKey);
      migrateHistory = recentJson != null;
    }
    var loadedRecentSongs = <Song>[];
    if (recentJson != null) {
      final decoded = jsonDecode(recentJson);
      if (decoded is! List) {
        throw const FormatException('Dữ liệu lịch sử nghe nhạc không hợp lệ.');
      }
      loadedRecentSongs = decoded
          .whereType<Map>()
          .map((item) => Song.fromMap(Map<String, dynamic>.from(item), ''))
          .toList();
    }

    if (migrateProfile) {
      await storage.writeString(_profileKey, profileJson!);
    }
    if (migrateFavorites) {
      await storage.writeString(
        _favoriteIdsKey,
        jsonEncode(loadedFavoriteIds.toList()),
      );
    }
    if (migrateHistory) {
      await storage.writeString(_recentSongsKey, recentJson!);
    }

    _profile = loadedProfile;
    _favoriteIds = loadedFavoriteIds;
    _recentSongs = loadedRecentSongs;
    _loaded = true;
  }

  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  List<String> _decodeStringList(String raw, String label) {
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw FormatException('Dữ liệu $label không hợp lệ.');
    }
    return List<String>.from(decoded);
  }

  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> saveProfile(LocalUserProfile profile) async {
    await load();
    await StorageService.instance.writeString(
      _profileKey,
      jsonEncode(profile.toMap()),
    );
    _profile = profile;
  }

  Future<void> setFavorite(String songId, bool favorite) async {
    await load();
    final updated = {..._favoriteIds};
    if (favorite) {
      updated.add(songId);
    } else {
      updated.remove(songId);
    }

    await StorageService.instance.writeString(
      _favoriteIdsKey,
      jsonEncode(updated.toList()),
    );
    _favoriteIds = updated;
  }

  Future<void> recordRecentlyPlayed(Song song) async {
    await load();
    final updated = [
      song,
      ..._recentSongs.where((item) => item.id != song.id),
    ].take(_maxRecentSongs).toList();
    await StorageService.instance.writeString(
      _recentSongsKey,
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
    _recentSongs = updated;
  }
}
