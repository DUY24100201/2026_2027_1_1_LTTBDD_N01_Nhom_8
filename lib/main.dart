import 'package:material_ui/material_ui.dart';

import 'screens/home/home_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'widgets/intro_dialog_page.dart';
import 'services/music_player_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MusicPlayerService.instance.initialize();

  runApp(const MelodyApp());
}

class MelodyApp extends StatelessWidget {
  const MelodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroScreen(
        destination: IntroDialogPage(child: const HomeScreen()),
      ),
    );
  }
}
