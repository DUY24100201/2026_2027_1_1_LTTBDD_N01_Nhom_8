import 'package:material_ui/material_ui.dart';

import 'screens/auth/welcome/welcome_screen.dart';
import 'services/music_player_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MusicPlayerService.instance.initialize();
  runApp(const MelodyApp());
}

class MelodyApp extends StatelessWidget {
  final Future<bool> Function(String email, String password)? onLogin;
  final Future<bool> Function(String name, String email, String password)?
  onRegister;

  const MelodyApp({super.key, this.onLogin, this.onRegister});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melody',
      theme: ThemeData.dark(),
      home: WelcomeScreen(onLogin: onLogin, onRegister: onRegister),
    );
  }
}
