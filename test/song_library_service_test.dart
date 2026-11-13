import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/music/song_library_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

void main() {
  const frameHeader = [0xFF, 0xFB, 0x90, 0x64];
  final frame = [
    ...frameHeader,
    ...List<int>.filled(417 - frameHeader.length, 0),
  ];
  final validMp3 = [...frame, ...frame];

  test('only Admin can add, update, and delete shared songs', () async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({
      StorageService.userAccountsKey: '[]',
      StorageService.sharedSongsKey: '[]',
    });
    final admins = AdminStorageService(
      storage: storage,
      developmentAdminPassword: 'local-bootstrap-test',
    );
    final auth = AuthService(storage: storage, adminStorage: admins);
    final library = SongLibraryService(storage: storage, authService: auth);
    await auth.initialize();

    final song = Song(
      id: 'song-1',
      name: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      genre: 'Pop',
    );

    await expectLater(
      library.addSong(
        song,
        audioBytes: Uint8List.fromList(validMp3),
        audioFileName: 'track.mp3',
      ),
      throwsA(isA<AuthorizationException>()),
    );
    await expectLater(
      library.updateSong(song),
      throwsA(isA<AuthorizationException>()),
    );
    await expectLater(
      library.deleteSong(song.id),
      throwsA(isA<AuthorizationException>()),
    );

    await auth.login('  ADMIN@MELODY.LOCAL ', 'local-bootstrap-test');
    final added = await library.addSong(
      song,
      audioBytes: Uint8List.fromList(validMp3),
      audioFileName: 'track.mp3',
    );
    expect(added.genre, 'Pop');
    final storedSong = (await library.readSongs()).single;
    expect(storedSong.id, song.id);
    expect(
      SongLibraryService.isStoredAudioReference(storedSong.audioUrl),
      isTrue,
    );
    expect(storedSong.audioUrl, isNot(contains(base64Encode(validMp3))));
    expect(storedSong.album, song.album);
    final originalKey = SongLibraryService.audioStorageKey(
      storedSong.audioUrl,
    )!;
    expect(await storage.readBinary(originalKey), validMp3);
    expect(
      (await SongLibraryService(
        storage: storage,
        authService: auth,
      ).readSongs()).single.audioUrl,
      storedSong.audioUrl,
    );

    final updated = await library.updateSong(
      Song(
        id: song.id,
        name: 'Updated Song',
        artist: song.artist,
        album: song.album,
        genre: song.genre,
      ),
    );
    expect(updated.name, 'Updated Song');
    expect((await library.readSongs()).single.name, 'Updated Song');

    final replaced = await library.updateSong(
      updated,
      audioBytes: Uint8List.fromList([...validMp3, 0x06]),
      audioFileName: 'replacement.mp3',
    );
    final replacementKey = SongLibraryService.audioStorageKey(
      replaced.audioUrl,
    )!;
    expect(await storage.readBinary(originalKey), isNull);
    expect(await storage.readBinary(replacementKey), [...validMp3, 0x06]);

    await storage.writeString(
      StorageService.playlistsKey,
      'preserve-playlists',
    );
    await storage.writeString(
      StorageService.favoriteSongsKey,
      'preserve-favorites',
    );
    await storage.writeString(
      StorageService.listeningHistoryKey,
      'preserve-history',
    );
    await library.deleteSong(song.id);
    expect(await library.readSongs(), isEmpty);
    expect(await storage.readBinary(replacementKey), isNull);
    expect(
      await storage.readString(StorageService.playlistsKey),
      'preserve-playlists',
    );
    expect(
      await storage.readString(StorageService.favoriteSongsKey),
      'preserve-favorites',
    );
    expect(
      await storage.readString(StorageService.listeningHistoryKey),
      'preserve-history',
    );
    expect(await storage.readString(StorageService.userAccountsKey), '[]');

    await auth.logout();
    await auth.register('Regular User', 'user@example.test', 'user-password');
    await auth.login('user@example.test', 'user-password');
    await expectLater(
      library.addSong(
        song,
        audioBytes: Uint8List.fromList(validMp3),
        audioFileName: 'track.mp3',
      ),
      throwsA(isA<AuthorizationException>()),
    );
  });

  test('legacy inline MP3 data migrates to binary storage', () async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({
      StorageService.sharedSongsKey: jsonEncode([
        {
          'id': 'legacy-song',
          'name': 'Legacy Song',
          'artist': 'Legacy Artist',
          'audioUrl': 'data:audio/mpeg;base64,${base64Encode(validMp3)}',
        },
      ]),
    });
    final library = SongLibraryService(storage: storage);

    final song = (await library.readSongs()).single;
    final key = SongLibraryService.audioStorageKey(song.audioUrl)!;
    expect(await storage.readBinary(key), validMp3);
    expect(
      (jsonDecode(
        (await storage.readString(StorageService.sharedSongsKey))!,
      ) as List).single['audioUrl'],
      song.audioUrl,
    );
  });

  test('legacy songs without genre deserialize as before', () {
    final song = Song.fromMap({
      'id': 'legacy',
      'name': 'Legacy Song',
      'artist': 'Legacy Artist',
    }, 'legacy');

    expect(song.genre, isEmpty);
    expect(song.toMap()['genre'], isEmpty);
  });

  test(
    'legacy sample catalog is migrated into the shared song store once',
    () async {
      final storage = StorageService.instance;
      storage.setMockInitialValues({});
      final library = SongLibraryService(storage: storage);

      final songs = await library.readSongs();
      expect(songs, hasLength(5));
      expect(songs.every((song) => song.audioUrl.isEmpty), isTrue);
      expect(
        (jsonDecode((await storage.readString(StorageService.sharedSongsKey))!)
            as List),
        hasLength(5),
      );
      expect(await library.readSongs(), hasLength(5));
    },
  );

  test('MP3 duration is calculated from MPEG frames', () {
    final duration = SongLibraryService.readMp3Duration(
      Uint8List.fromList([...frame, ...frame]),
    );

    expect(duration.inMilliseconds, closeTo(52, 1));
  });

  test('MP3 upload rejects invalid files and accepts MP3 signatures', () {
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'track.wav',
        bytes: const [0x49, 0x44, 0x33],
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'empty.mp3',
        bytes: const [],
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'invalid.mp3',
        bytes: const [0x00, 0x01, 0x02],
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'tag-only.mp3',
        bytes: const [0x49, 0x44, 0x33, 0x04, 0, 0, 0, 0, 0, 0],
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'truncated.mp3',
        bytes: const [0xFF, 0xFB, 0x90, 0x64],
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => SongLibraryService.validateMp3(
        fileName: 'valid.mp3',
        bytes: validMp3,
      ),
      returnsNormally,
    );
  });
}
