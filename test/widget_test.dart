import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/main.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';
import 'package:lttbdd_nhom8/screens/intro/intro_screen.dart';
import 'package:lttbdd_nhom8/screens/menu/menu_screen.dart';
import 'package:lttbdd_nhom8/screens/playlist/playlist_screen.dart';
import 'package:lttbdd_nhom8/screens/profile/profile_screen.dart';
import 'package:lttbdd_nhom8/services/music_player_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Melody app starts on intro screen then navigates home', (
    WidgetTester tester,
  ) async {
    StorageService.instance.setMockInitialValues({});
    await tester.pumpWidget(const MelodyApp());

    expect(find.byType(IntroScreen), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);

    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Melody'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);

    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playlist').last);
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistScreen), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsNothing);
    expect(find.text('Người nghe nhạc'), findsOneWidget);

    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Người nghe thử');
    await tester.enterText(
      find.byType(TextFormField).last,
      'listener@example.test',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Người nghe thử'), findsOneWidget);
    expect(find.text('listener@example.test'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsNothing);
    expect(find.text('MENU'), findsOneWidget);
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('Lịch sử nghe nhạc'), findsOneWidget);

    final shuffleSwitch = find.byType(Switch);
    await tester.ensureVisible(shuffleSwitch);
    await tester.tap(shuffleSwitch);
    await tester.pumpAndSettle();
    expect(MusicPlayerService.instance.isShuffle, isTrue);
    final settings = jsonDecode(
      (await StorageService.instance.readString(
        StorageService.appSettingsKey,
      ))!,
    ) as Map<String, dynamic>;
    expect(settings['shuffle'], isTrue);

    final sleepTimerTile = find.text('Hẹn giờ tắt nhạc');
    await tester.ensureVisible(sleepTimerTile);
    await tester.tap(sleepTimerTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 phút'));
    await tester.pumpAndSettle();
    expect(MusicPlayerService.instance.sleepTimerDeadline, isNotNull);

    await tester.tap(sleepTimerTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy hẹn giờ hiện tại'));
    await tester.pumpAndSettle();
    expect(MusicPlayerService.instance.sleepTimerDeadline, isNull);
  });
}
