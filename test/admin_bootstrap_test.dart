import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

void main() {
  test(
    'development Admin is seeded once with a salted password hash',
    () async {
      final storage = StorageService.instance;
      storage.setMockInitialValues({StorageService.userAccountsKey: '[]'});
      final adminStorage = AdminStorageService(
        storage: storage,
        developmentAdminPassword: 'local-bootstrap-test',
      );
      final authService = AuthService(
        storage: storage,
        adminStorage: adminStorage,
      );

      await authService.initialize();
      final firstStoredJson = (await storage.readString(
        StorageService.adminAccountsKey,
      ))!;
      final firstRead = jsonDecode(firstStoredJson) as List<dynamic>;
      final firstAccount = Map<String, dynamic>.from(firstRead.single as Map);
      final firstSalt = firstAccount['salt'];
      final firstHash = firstAccount['passwordHash'];

      expect(firstAccount['email'], 'admin@melody.local');
      expect(firstAccount['password'], isNull);
      expect(firstStoredJson, isNot(contains('local-bootstrap-test')));
      expect(firstHash, isNot('local-bootstrap-test'));
      expect(firstAccount['algorithm'], 'pbkdf2-hmac-sha256');
      expect(base64.decode(firstSalt as String), hasLength(16));
      expect(firstAccount['iterations'], greaterThanOrEqualTo(600000));

      final otherBootstrap = AdminStorageService(
        storage: storage,
        developmentAdminPassword: 'replacement-bootstrap-test',
      );
      await otherBootstrap.initializeDevelopmentAdmin();
      final secondRead = jsonDecode(
        (await storage.readString(StorageService.adminAccountsKey))!,
      ) as List<dynamic>;
      final secondAccount = Map<String, dynamic>.from(secondRead.single as Map);
      expect(secondAccount['id'], firstAccount['id']);
      expect(secondAccount['passwordHash'], firstHash);

      expect(
        await authService.login(
          '  ADMIN@MELODY.LOCAL ',
          'local-bootstrap-test',
        ),
        isTrue,
      );
      final currentAdmin = authService.getCurrentUser();
      expect(currentAdmin?.email, 'admin@melody.local');
      expect(currentAdmin?.role, UserRole.admin);
      expect(() => authService.requireAdmin(), returnsNormally);

      await authService.logout();
      expect(authService.getCurrentUser(), isNull);
      expect(
        await storage.readString(StorageService.authSessionAccountKey),
        '',
      );
      expect(await storage.readString(StorageService.userAccountsKey), '[]');
      await expectLater(
        authService.login('admin@melody.local', 'wrong-password'),
        throwsA(isA<AuthException>()),
      );

      await authService.register(
        'Regular User',
        'user@example.test',
        'user-password',
      );
      expect(
        await authService.login('user@example.test', 'user-password'),
        isTrue,
      );
      expect(authService.getCurrentUser()?.role, UserRole.user);
      await expectLater(
        adminStorage.saveAdmin(
          AdminModel(
            id: 'forged-admin',
            name: 'Forged Admin',
            email: 'forged@melody.local',
            createdAt: DateTime.utc(2026),
          ),
        ),
        throwsA(isA<AdminStorageAuthorizationException>()),
      );
    },
  );

  test('reports missing debug Admin password configuration', () async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({});
    final authService = AuthService(
      storage: storage,
      adminStorage: AdminStorageService(
        storage: storage,
        developmentAdminPassword: '',
      ),
    );

    await expectLater(
      authService.login('admin@melody.local', 'not-configured'),
      throwsA(isA<AdminStorageException>()),
    );
    expect(await storage.readString(StorageService.adminAccountsKey), isNull);
  });
}
