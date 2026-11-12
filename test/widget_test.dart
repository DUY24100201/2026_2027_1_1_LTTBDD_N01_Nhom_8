import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/main.dart';
import 'package:lttbdd_nhom8/screens/auth/login/login_screen.dart';
import 'package:lttbdd_nhom8/screens/auth/register/register_screen.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';
import 'package:lttbdd_nhom8/screens/menu/menu_screen.dart';
import 'package:lttbdd_nhom8/screens/playlist/playlist_screen.dart';
import 'package:lttbdd_nhom8/screens/profile/profile_screen.dart';
import 'package:lttbdd_nhom8/screens/auth/welcome/welcome_screen.dart';
import 'package:lttbdd_nhom8/services/music_player_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Melody starts at auth and navigates home after login', (
    WidgetTester tester,
  ) async {
    StorageService.instance.setMockInitialValues({});
    await tester.pumpWidget(
      MelodyApp(onLogin: (email, password) async => true),
    );

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'listener@example.test',
    );
    await tester.enterText(find.byType(TextField).last, 'password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
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

  testWidgets('login does not claim success when auth is not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
      find.byType(TextField).first,
      'listener@example.test',
    );
    await tester.enterText(find.byType(TextField).last, 'password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa cấu hình backend/API xác thực. Không thể đăng nhập.'),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('login stays out of home when the auth handler rejects', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MelodyApp(onLogin: (email, password) async => false),
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'listener@example.test',
    );
    await tester.enterText(find.byType(TextField).last, 'wrong-password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Thông tin đăng nhập không chính xác.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('registration does not claim success without an auth backend', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    for (final (index, value) in [
      (0, 'Listener'),
      (1, 'listener@example.test'),
      (2, 'password'),
      (3, 'password'),
    ]) {
      await tester.enterText(find.byType(TextField).at(index), value);
    }

    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng kí'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa cấu hình backend/API xác thực. Không thể tạo tài khoản.'),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('successful registration returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MelodyApp(onRegister: (name, email, password) async => true),
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    for (final (index, value) in [
      (0, 'Listener'),
      (1, 'listener@example.test'),
      (2, 'password'),
      (3, 'password'),
    ]) {
      await tester.enterText(find.byType(TextField).at(index), value);
    }

    final registerButton = find.widgetWithText(ElevatedButton, 'Đăng kí');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Tạo tài khoản thành công. Vui lòng đăng nhập.'),
      findsOneWidget,
    );
  });

  testWidgets('logout returns to login and removes the home route', (
    WidgetTester tester,
  ) async {
    StorageService.instance.setMockInitialValues({});
    await tester.pumpWidget(
      MelodyApp(onLogin: (email, password) async => true),
    );
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'listener@example.test',
    );
    await tester.enterText(find.byType(TextField).last, 'password');
    final loginButton = find.widgetWithText(ElevatedButton, 'Đăng nhập');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    final continueButton = find.text('TIẾP TỤC');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final logoutOption = find.text('Đăng xuất');
    await tester.ensureVisible(logoutOption);
    await tester.tap(logoutOption);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
