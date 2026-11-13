import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/music/library_screen.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/music/song_library_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

class _TestAdminAuthority implements AdminAuthenticationAuthority {
  static final _admin = AdminModel(
    id: 'test-admin',
    name: 'Test Admin',
    email: AdminStorageService.developmentAdminEmail,
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<AdminModel?> authenticateAdmin(String email, String password) async {
    if (email == _admin.email && password == 'test-password') return _admin;
    return null;
  }

  @override
  Future<AdminModel?> restoreAdminSession(String adminId) async =>
      adminId == _admin.id ? _admin : null;
}

void main() {
  testWidgets('Admin uploads shared MP3 and Library updates from same store', (
    tester,
  ) async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({
      StorageService.userAccountsKey: '[]',
      StorageService.sharedSongsKey: '[]',
    });
    final auth = AuthService.instance;
    auth.configureAdminAuthentication(_TestAdminAuthority());
    await auth.login(
      AdminStorageService.developmentAdminEmail,
      'test-password',
    );

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('0 bài hát'), findsOneWidget);

    const header = [0xFF, 0xFB, 0x90, 0x64];
    final frame = <int>[...header, ...List<int>.filled(417 - header.length, 0)];
    final audioBytes = Uint8List.fromList([
      for (var index = 0; index < 40; index++) ...frame,
    ]);
    final library = SongLibraryService.instance;
    final uploadedSong = await library.addSong(
      Song(
        id: 'uploaded-song',
        name: 'Uploaded Song',
        artist: 'Melody Artist',
        album: 'Test Album',
        genre: 'Pop',
        duration: SongLibraryService.readMp3Duration(audioBytes),
        coverUrl: '',
      ),
      audioBytes: audioBytes,
      audioFileName: 'uploaded-song.mp3',
    );
    await tester.pumpAndSettle();

    expect(find.text('Uploaded Song'), findsOneWidget);
    expect(find.text('Melody Artist'), findsOneWidget);
    expect(find.text('0:01'), findsOneWidget);
    expect(uploadedSong.duration, const Duration(milliseconds: 1045));

    final mediaKey = SongLibraryService.audioStorageKey(uploadedSong.audioUrl)!;
    expect(await storage.readBinary(mediaKey), audioBytes);

    final restartedLibrary = SongLibraryService(
      storage: storage,
      authService: auth,
    );
    final restored = (await restartedLibrary.readSongs()).single;
    expect(restored.id, uploadedSong.id);
    expect(restored.audioUrl, uploadedSong.audioUrl);
    expect(await storage.readBinary(mediaKey), audioBytes);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Melody Artist');
    await tester.pumpAndSettle();
    expect(find.text('Uploaded Song'), findsOneWidget);

    await auth.logout();
  });
}
