import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/admin/account_management_screen.dart';
import 'package:lttbdd_nhom8/admin/admin_storage_service.dart';
import 'package:lttbdd_nhom8/admin/models/admin_model.dart';
import 'package:lttbdd_nhom8/admin/song_management_screen.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:lttbdd_nhom8/user/profile_screen.dart';
import 'package:material_ui/material_ui.dart';

class _TrustedAdminAuthority implements AdminAuthenticationAuthority {
  const _TrustedAdminAuthority();

  @override
  Future<AdminModel?> authenticateAdmin(String email, String password) async {
    if (email != 'admin@example.test' || password != 'admin-password') {
      return null;
    }
    return AdminModel(
      id: 'admin-one',
      name: 'Melody Development Admin',
      email: email,
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<AdminModel?> restoreAdminSession(String adminId) async =>
      adminId == 'admin-one'
      ? AdminModel(
          id: 'admin-one',
          name: 'Melody Development Admin',
          email: 'admin@example.test',
          createdAt: DateTime.utc(2026),
        )
      : null;
}

void main() {
  testWidgets('admin profile links are role-gated and routes stay protected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = StorageService.instance;
    storage.setMockInitialValues({
      StorageService.userAccountsKey: '[]',
      StorageService.sharedSongsKey: '[]',
      StorageService.favoriteSongsKey: '[]',
      StorageService.playlistsKey: '[]',
    });
    final auth = AuthService.instance;
    auth.configureAdminAuthentication(const _TrustedAdminAuthority());
    await auth.login('admin@example.test', 'admin-password');

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
    expect(auth.getCurrentUser()?.role, UserRole.admin);
    expect(find.text('Quản lý bài hát'), findsOneWidget);
    expect(find.text('QUẢN TRỊ HỆ THỐNG'), findsOneWidget);
    await tester.ensureVisible(find.text('Quản lý bài hát'));
    await tester.tap(find.text('Quản lý bài hát'));
    await tester.pumpAndSettle();
    expect(find.byType(SongManagementScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SongManagementScreen))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Quản lý tài khoản'));
    await tester.tap(find.text('Quản lý tài khoản'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountManagementScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(AccountManagementScreen))).pop();
    await tester.pumpAndSettle();

    expect(await storage.readString(StorageService.favoriteSongsKey), '[]');
    expect(await storage.readString(StorageService.playlistsKey), '[]');

    await auth.logout();
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(auth.getCurrentUser(), isNull);
    expect(find.text('QUẢN TRỊ HỆ THỐNG'), findsNothing);
    expect(find.text('Quản lý bài hát'), findsNothing);
    expect(find.text('Quản lý tài khoản'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SongManagementScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn không có quyền truy cập chức năng này.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(home: AccountManagementScreen(authService: auth)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn không có quyền thực hiện chức năng quản trị.'),
      findsOneWidget,
    );

    await auth.logout();
  });
}
