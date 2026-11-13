import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/user/models/local_user_profile.dart';
import 'package:lttbdd_nhom8/music/models/song.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/services/local_profile_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';

void main() {
  test(
    'profiles stay with their account while shared music data is retained',
    () async {
      final storage = StorageService.instance;
      storage.setMockInitialValues({
        StorageService.userAccountsKey: jsonEncode([
          _account(
            id: 'account-one',
            name: 'Account One',
            email: 'one@example.test',
          ),
          _account(
            id: 'account-two',
            name: 'Account Two',
            email: 'two@example.test',
          ),
        ]),
        StorageService.authSessionKey: 'account-one',
        StorageService.userProfileKey: jsonEncode(
          const LocalUserProfile(
            displayName: 'Legacy Profile',
            avatarBase64: 'legacy-avatar',
          ).toMap(),
        ),
      });

      final authService = AuthService.instance;
      await authService.initialize();
      final profileService = LocalProfileService.instance;
      await profileService.load();
      expect(profileService.profile.displayName, 'Account One');
      expect(profileService.profile.avatarBase64, 'legacy-avatar');

      final updatedUser = await authService.updateCurrentUserProfile(
        name: 'Updated One',
        email: 'updated-one@example.test',
      );
      await profileService.reload();
      await profileService.saveProfile(
        profileService.profile.copyWith(avatarBase64: 'one-avatar'),
      );
      expect(profileService.profile.displayName, updatedUser.name);
      expect(profileService.profile.email, updatedUser.email);

      await expectLater(
        authService.updateCurrentUserProfile(
          name: 'Updated One',
          email: 'two@example.test',
        ),
        throwsA(isA<AuthException>()),
      );

      await profileService.setFavorite('shared-song', true);
      const song = Song(
        id: 'shared-song',
        name: 'Shared Song',
        artist: 'Artist',
      );
      await profileService.recordRecentlyPlayed(song);

      await authService.login('two@example.test', 'password');
      await profileService.load();
      expect(profileService.profile.displayName, 'Account Two');
      expect(profileService.profile.email, 'two@example.test');
      expect(profileService.profile.avatarBase64, isNull);
      expect(profileService.favoriteIds, contains('shared-song'));
      expect(profileService.recentlyPlayed.single.id, 'shared-song');

      await profileService.saveProfile(
        profileService.profile.copyWith(avatarBase64: 'two-avatar'),
      );
      await authService.login('updated-one@example.test', 'password');
      await profileService.load();
      expect(profileService.profile.displayName, 'Updated One');
      expect(profileService.profile.email, 'updated-one@example.test');
      expect(profileService.profile.avatarBase64, 'one-avatar');

      await authService.login('two@example.test', 'password');
      await profileService.load();
      expect(profileService.profile.displayName, 'Account Two');
      expect(profileService.profile.avatarBase64, 'two-avatar');

      await expectLater(
        authService.getAllUsers(),
        throwsA(isA<AuthorizationException>()),
      );
    },
  );
}

Map<String, Object> _account({
  required String id,
  required String name,
  required String email,
}) => {
  'id': id,
  'name': name,
  'email': email,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'salt': 'MDEyMzQ1Njc4OWFiY2RlZg==',
  'passwordHash': 'RTZCeRbsxNsX/5cC2qwamnVfsX+aVE68Tp3EzhaJES4=',
  'algorithm': 'pbkdf2-hmac-sha256',
  'iterations': 2,
};
