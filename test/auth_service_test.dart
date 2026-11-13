import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/auth/register_screen.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:lttbdd_nhom8/user/user_storage_service.dart';
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
    expect(storedAccount['role'], 'USER');
    expect(user.role, UserRole.user);
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
    await expectLater(
      restartedService.getAllUsers(),
      throwsA(isA<AuthorizationException>()),
    );
    expect(
      (await restartedService.getUserByEmail('LISTENER@example.test'))?.id,
      user.id,
    );

    await restartedService.logout();
    expect(restartedService.getCurrentUser(), isNull);
    expect(await storage.readString(StorageService.authSessionKey), '');
    expect(
      (jsonDecode((await storage.readString(StorageService.userAccountsKey))!)
          as List),
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

  test(
    'locally stored ADMIN role cannot grant management permissions',
    () async {
      final account = {
        'id': 'local-admin',
        'name': 'Local Admin',
        'email': 'admin@example.test',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'salt': 'MDEyMzQ1Njc4OWFiY2RlZg==',
        'passwordHash': 'RTZCeRbsxNsX/5cC2qwamnVfsX+aVE68Tp3EzhaJES4=',
        'algorithm': 'pbkdf2-hmac-sha256',
        'iterations': 2,
        'role': 'ADMIN',
      };
      storage.setMockInitialValues({
        StorageService.userAccountsKey: jsonEncode([account]),
        StorageService.authSessionKey: 'local-admin',
      });

      final service = AuthService(storage: storage);
      await service.initialize();

      expect(service.getCurrentUser()?.role, UserRole.user);
      expect(service.isAdmin, isFalse);
      expect(await service.login('admin@example.test', 'password'), isTrue);
      expect(service.getCurrentUser()?.role, UserRole.user);
      expect(
        () => service.requireAdmin(),
        throwsA(isA<AuthorizationException>()),
      );
      await expectLater(
        service.getAllUsers(),
        throwsA(isA<AuthorizationException>()),
      );
      await expectLater(
        UserStorageService(storage: storage).readUsers(),
        throwsA(isA<UserStorageAuthorizationException>()),
      );
      await expectLater(
        AdminStorageService(storage: storage).readAdmins(),
        throwsA(isA<AdminStorageAuthorizationException>()),
      );

      final storedAccounts = jsonDecode(
        (await storage.readString(StorageService.userAccountsKey))!,
      ) as List<dynamic>;
      expect((storedAccounts.single as Map<String, dynamic>)['role'], 'USER');
    },
  );

  test('trusted Admin authentication stays separate from User login', () async {
    final admin = AdminModel(
      id: 'trusted-admin',
      name: 'Trusted Admin',
      email: 'admin@example.test',
      createdAt: DateTime.utc(2026),
    );
    storage.setMockInitialValues({
      StorageService.userAccountsKey: jsonEncode([
        {
          'id': 'vector-user',
          'name': 'Regular User',
          'email': 'user@example.test',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'salt': 'MDEyMzQ1Njc4OWFiY2RlZg==',
          'passwordHash': 'RTZCeRbsxNsX/5cC2qwamnVfsX+aVE68Tp3EzhaJES4=',
          'algorithm': 'pbkdf2-hmac-sha256',
          'iterations': 2,
        },
      ]),
      StorageService.authSessionKey: '',
    });
    final adminStorage = AdminStorageService(
      storage: storage,
      authority: _TrustedAdminAuthority(admin, password: 'admin-password'),
    );
    final userStorage = UserStorageService(storage: storage);
    final service = AuthService(
      storage: storage,
      userStorage: userStorage,
      adminStorage: adminStorage,
    );

    await service.initialize();
    expect(await service.login('admin@example.test', 'admin-password'), isTrue);
    expect(service.getCurrentUser()?.role, UserRole.admin);
    expect((await service.getAllAdmins()).single.id, admin.id);

    final storedAdmins = jsonDecode(
      (await storage.readString(StorageService.adminAccountsKey))!,
    ) as List<dynamic>;
    expect(storedAdmins.single['password'], isNull);
    expect(storedAdmins.single['passwordHash'], isNull);
    final secondAdmin = await adminStorage.saveAdmin(
      AdminModel(
        id: 'admin-two',
        name: 'Second Admin',
        email: 'admin-two@example.test',
        createdAt: DateTime.utc(2026),
      ),
    );
    expect(
      (await adminStorage.searchAdmins('second')).single.id,
      secondAdmin.id,
    );
    await adminStorage.updateAdmin(secondAdmin.copyWith(name: 'Updated Admin'));
    expect((await service.getAllAdmins()).last.name, 'Updated Admin');

    final users = await userStorage.readUsers();
    expect(users.single.email, 'user@example.test');
    expect(
      (await userStorage.searchUsers('regular')).single.id,
      users.single.id,
    );
    await userStorage.updateUser(users.single.copyWith(name: 'Updated User'));

    expect(await service.login('user@example.test', 'password'), isTrue);
    expect(service.getCurrentUser()?.role, UserRole.user);
    expect(service.getCurrentUser()?.name, 'Updated User');
    await expectLater(
      service.getAllUsers(),
      throwsA(isA<AuthorizationException>()),
    );
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
    await tester.enterText(find.byType(TextField).at(2), 'secure-passphrase');
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
    await tester.enterText(find.byType(TextField).at(2), 'secure-passphrase');
    await tester.enterText(find.byType(TextField).at(3), 'secure-passphrase');

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

class _TrustedAdminAuthority implements AdminAuthenticationAuthority {
  const _TrustedAdminAuthority(this.admin, {required this.password});

  final AdminModel admin;
  final String password;

  @override
  Future<AdminModel?> authenticateAdmin(String email, String value) async =>
      email == admin.email && value == password ? admin : null;

  @override
  Future<AdminModel?> restoreAdminSession(String adminId) async =>
      adminId == admin.id ? admin : null;
}
