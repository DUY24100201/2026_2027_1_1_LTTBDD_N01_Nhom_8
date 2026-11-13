import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/admin/account_management_screen.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'lists stored users, searches and refreshes without credentials',
    (tester) async {
      final storage = StorageService.instance;
      final firstAccount = _account(
        id: 'user-one',
        name: 'Nguyễn An',
        email: 'an@example.test',
      );
      final secondAccount = _account(
        id: 'user-two',
        name: 'Trần Bình',
        email: 'binh@example.test',
      );
      final encodedHash = firstAccount['passwordHash'] as String;

      storage.setMockInitialValues({
        StorageService.userAccountsKey: jsonEncode([firstAccount]),
        StorageService.authSessionKey: '',
      });
      final adminStorage = AdminStorageService(
        storage: storage,
        authority: _TrustedAdminAuthority(),
      );
      final authService = AuthService(
        storage: storage,
        adminStorage: adminStorage,
      );
      await authService.initialize();
      await authService.login('admin@example.test', 'admin-password');

      await tester.pumpWidget(
        MaterialApp(home: AccountManagementScreen(authService: authService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn An'), findsOneWidget);
      expect(find.text('an@example.test'), findsOneWidget);
      expect(find.text('user-one'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);
      expect(find.text(encodedHash), findsNothing);

      storage.setMockInitialValues({
        StorageService.userAccountsKey: jsonEncode([
          firstAccount,
          secondAccount,
        ]),
      });
      await tester.tap(find.byTooltip('Làm mới danh sách'));
      await tester.pumpAndSettle();

      expect(find.text('Trần Bình'), findsOneWidget);
      expect(find.text('binh@example.test'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'binh@EXAMPLE.test');
      await tester.pump();
      expect(find.text('Trần Bình'), findsOneWidget);
      expect(find.text('Nguyễn An'), findsNothing);
    },
  );

  testWidgets('a USER cannot access account management directly', (
    tester,
  ) async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({
      StorageService.userAccountsKey: jsonEncode([
        _account(id: 'user-one', name: 'Nguyễn An', email: 'an@example.test'),
      ]),
      StorageService.authSessionKey: 'user-one',
    });
    final authService = AuthService(storage: storage);
    await authService.initialize();

    await tester.pumpWidget(
      MaterialApp(home: AccountManagementScreen(authService: authService)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn không có quyền thực hiện chức năng quản trị.'),
      findsOneWidget,
    );
    expect(find.text('Nguyễn An'), findsNothing);
    await expectLater(
      authService.getAllUsers(),
      throwsA(isA<AuthorizationException>()),
    );
  });
}

class _TrustedAdminAuthority implements AdminAuthenticationAuthority {
  const _TrustedAdminAuthority();

  @override
  Future<AdminModel?> authenticateAdmin(String email, String password) async {
    if (email != 'admin@example.test' || password != 'admin-password') {
      return null;
    }
    return AdminModel(
      id: 'admin-one',
      name: 'Melody Admin',
      email: email,
      createdAt: DateTime.utc(2025, 5, 4),
    );
  }

  @override
  Future<AdminModel?> restoreAdminSession(String adminId) async =>
      adminId == 'admin-one'
      ? AdminModel(
          id: 'admin-one',
          name: 'Melody Admin',
          email: 'admin@example.test',
          createdAt: DateTime.utc(2025, 5, 4),
        )
      : null;
}

Map<String, Object> _account({
  required String id,
  required String name,
  required String email,
}) {
  return {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': DateTime.utc(2025, 5, 4, 10, 30).toIso8601String(),
    'salt': base64.encode(List<int>.filled(16, 0x42)),
    'passwordHash': base64.encode(List<int>.filled(32, 0xA5)),
    'algorithm': 'pbkdf2-hmac-sha256',
    'iterations': 600000,
  };
}
