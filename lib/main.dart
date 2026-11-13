import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/core/constants/app_colors.dart';
import 'package:lttbdd_nhom8/core/app_theme.dart';
import 'package:lttbdd_nhom8/auth/welcome_screen.dart';
import 'package:lttbdd_nhom8/user/home_screen.dart';
import 'package:lttbdd_nhom8/auth/auth_service.dart';
import 'package:lttbdd_nhom8/music/music_player_service.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_observer.dart';

final _introDialogObserver = IntroDialogObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.initialize();
  final authService = AuthService.instance;
  await authService.initialize();
  await MusicPlayerService.instance.initialize();
  runApp(
    MelodyApp(
      initialUser: authService.getCurrentUser(),
      onLogin: authService.login,
      onRegister: (name, email, password) async {
        await authService.register(name, email, password);
        return true;
      },
      onLogout: authService.logout,
    ),
  );
}

class MelodyApp extends StatelessWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
  onRegister;
  final Future<void> Function()? onLogout;
  final AuthUser? initialUser;

  const MelodyApp({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melody',
      theme: AppTheme.melody,
      navigatorObservers: [_introDialogObserver],
      builder: (context, child) => ColoredBox(
        color: AppColors.outerBackground,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: IntroDialogPage(
        screenId: initialUser == null ? 'welcome' : 'home',
        child: initialUser == null
            ? WelcomeScreen(
                onLogin: onLogin,
                onRegister: onRegister,
                onLogout: onLogout,
              )
            : _AuthenticatedHome(
                onLogin: onLogin,
                onRegister: onRegister,
                onLogout: onLogout,
              ),
      ),
    );
  }
}

class _AuthenticatedHome extends StatelessWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
  onRegister;
  final Future<void> Function()? onLogout;

  const _AuthenticatedHome({
    required this.onLogin,
    required this.onRegister,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onLogout: () async {
        final logout = onLogout;
        if (logout != null) await logout();
        if (!context.mounted) return;
        await Navigator.of(context).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => IntroDialogPage(
              screenId: 'welcome',
              child: WelcomeScreen(
                onLogin: onLogin,
                onRegister: onRegister,
                onLogout: onLogout,
              ),
            ),
          ),
          (_) => false,
        );
      },
    );
  }
}
