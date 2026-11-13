import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/screens/auth/register/register_screen.dart';
import 'package:lttbdd_nhom8/services/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final storage = StorageService.instance;

  setUp(() {
    storage.setMockInitialValues({});
  });

  test('accounts and sessions persist without storing raw passwords', () async {
    storage.setMockInitialValues({
      StorageService.userProfileKey: 'existing profile',
      StorageService.playlistsKey: 'existing playlists',
    });
    final service = AuthService(storage: storage);
    await service.initialize();

    final user = await service.register(
      '  Melody Listener  ',
      '  Listener@Example.test ',
      'secure-passphrase',
    );

    expect(user.name, 'Melody Listener');
    expect(user.email, 'listener@example.test');
    expect(service.getCurrentUser(), isNull);

    final storedAccounts = jsonDecode(
      (await storage.readString(StorageService.userAccountsKey))!,
    ) as List<dynamic>;
    final storedAccount = Map<String, dynamic>.from(
      storedAccounts.single as Map,
    );
    expect(storedAccount['id'], user.id);
    expect(storedAccount.containsKey('password'), isFalse);
    expect(storedAccount['passwordHash'], isNot('secure-passphrase'));
    expect(storedAccount['algorithm'], 'pbkdf2-hmac-sha256');
    expect(base64.decode(storedAccount['salt'] as String), hasLength(16));
    expect(storedAccount['iterations'], greaterThanOrEqualTo(600000));
    expect(user.toMap().containsKey('passwordHash'), isFalse);

    expect(await service.isEmailExists(' LISTENER@example.test '), isTrue);
    await expectLater(
      service.register(
        'Other Name',
        'listener@EXAMPLE.test',
        'secure-passphrase',
      ),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      service.register('Other Name', 'invalid-email', 'secure-passphrase'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      service.register('Other Name', 'other@example.test', 'short'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      service.login('missing@example.test', 'secure-passphrase'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      service.login('listener@example.test', 'wrong-passphrase'),
      throwsA(isA<AuthException>()),
    );

    expect(
      await service.login(' LISTENER@example.test ', 'secure-passphrase'),
      isTrue,
    );
    final restartedService = AuthService(storage: storage);
    await restartedService.initialize();
    expect(restartedService.getCurrentUser()?.id, user.id);
    expect((await restartedService.getAllUsers()).single.id, user.id);
    expect(
      (await restartedService.getUserByEmail('LISTENER@example.test'))?.id,
      user.id,
    );

    await restartedService.logout();
    expect(restartedService.getCurrentUser(), isNull);
    expect(await storage.readString(StorageService.authSessionKey), '');
    expect(
      (jsonDecode(
        (await storage.readString(StorageService.userAccountsKey))!,
      ) as List),
      hasLength(1),
    );
    expect(
      await storage.readString(StorageService.userProfileKey),
      'existing profile',
    );
    expect(
      await storage.readString(StorageService.playlistsKey),
      'existing playlists',
    );
  });

  test('password verification matches PBKDF2-HMAC-SHA256', () async {
    storage.setMockInitialValues({
      StorageService.userAccountsKey: jsonEncode([
        {
          'id': 'vector-user',
          'name': 'PBKDF2 vector',
          'email': 'vector@example.test',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'salt': 'MDEyMzQ1Njc4OWFiY2RlZg==',
          'passwordHash': 'RTZCeRbsxNsX/5cC2qwamnVfsX+aVE68Tp3EzhaJES4=',
          'algorithm': 'pbkdf2-hmac-sha256',
          'iterations': 2,
        },
      ]),
      StorageService.authSessionKey: '',
    });

    final service = AuthService(storage: storage);
    await service.initialize();

    expect(await service.login('vector@example.test', 'password'), isTrue);
    expect(service.getCurrentUser()?.id, 'vector-user');
  });

  testWidgets('registration rejects mismatched password confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'Melody Listener');
    await tester.enterText(
      find.byType(TextField).at(1),
      'listener@example.test',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'secure-passphrase',
    );
    await tester.enterText(
      find.byType(TextField).at(3),
      'different-passphrase',
    );
    final registerButton = find.byType(ElevatedButton).last;
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu không khớp!'), findsOneWidget);
  });

  testWidgets('registration stops loading after failure and rejects repeats', (
    tester,
  ) async {
    final registration = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (name, email, password) {
            calls++;
            return registration.future;
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Melody Listener');
    await tester.enterText(
      find.byType(TextField).at(1),
      'listener@example.test',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      'secure-passphrase',
    );
    await tester.enterText(
      find.byType(TextField).at(3),
      'secure-passphrase',
    );

    final registerButton = find.byType(ElevatedButton).last;
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();
    await tester.tap(registerButton);
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    registration.completeError(const AuthException('Lỗi lưu tài khoản.'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Đăng ký thất bại: Lỗi lưu tài khoản.'), findsOneWidget);
  });
}
