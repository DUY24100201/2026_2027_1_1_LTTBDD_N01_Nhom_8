import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/user/models/local_user_profile.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/services/local_profile_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

void main() {
  test(
    'profile, favorites, and history persist without changing playlists',
    () async {
      final storage = StorageService.instance;
      const legacySong = Song(
        id: 'legacy-song',
        name: 'Bài hát cũ',
        artist: 'Ca sĩ cũ',
      );
      storage.setMockInitialValues({
        'melody_playlists_v1': 'playlist data must remain unchanged',
        'melody_local_profile_v1': jsonEncode(
          const LocalUserProfile(displayName: 'Hồ sơ cũ').toMap(),
        ),
        'melody_favorite_song_ids_v1': [
          'ánh nắng của anh',
          'thấy em là thấy',
          'đổi thay',
        ],
        'melody_recent_songs_v1': jsonEncode([legacySong.toMap()]),
      });

      final service = LocalProfileService.instance;
      await service.load();
      expect(service.favoriteIds.length, 3);
      expect(service.profile.displayName, 'Hồ sơ cũ');
      expect(service.recentlyPlayed.single.id, 'legacy-song');

      await service.saveProfile(
        const LocalUserProfile(
          displayName: 'Melody listener',
          email: 'listener@example.test',
          avatarBase64: 'aW1hZ2U=',
        ),
      );
      await service.setFavorite('ánh nắng của anh', false);
      await service.setFavorite('về nhà', true);
      const song = Song(
        id: 'về nhà',
        name: 'Về Nhà',
        artist: 'Chillies',
        audioUrl: 'https://example.test/ve-nha.mp3',
      );
      await service.recordRecentlyPlayed(song);
      await service.reload();

      final storedProfile = jsonDecode(
        (await storage.readString(StorageService.userProfileKey))!,
      ) as Map<String, dynamic>;
      final storedHistory = jsonDecode(
        (await storage.readString(StorageService.listeningHistoryKey))!,
      ) as List<dynamic>;
      final storedFavorites = jsonDecode(
        (await storage.readString(StorageService.favoriteSongsKey))!,
      ) as List<dynamic>;

      expect(storedProfile['displayName'], 'Melody listener');
      expect(storedProfile['email'], 'listener@example.test');
      expect(service.profile.displayName, 'Melody listener');
      expect(service.profile.email, 'listener@example.test');
      expect(service.favoriteIds, contains('về nhà'));
      expect(service.favoriteIds, isNot(contains('ánh nắng của anh')));
      expect(
        Map<String, dynamic>.from(storedHistory.first as Map)['id'],
        'về nhà',
      );
      expect(storedHistory, hasLength(2));
      expect(
        Map<String, dynamic>.from(storedHistory.last as Map)['id'],
        'legacy-song',
      );
      expect(storedFavorites, contains('về nhà'));
      expect(
        await storage.readLegacyString('melody_playlists_v1'),
        'playlist data must remain unchanged',
      );
      expect(
        await storage.readLegacyString('melody_local_profile_v1'),
        isNotNull,
      );
    },
  );
}
