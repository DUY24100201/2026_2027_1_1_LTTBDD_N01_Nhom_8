import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/music/player_screen.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('player controls include Stop and show Play without loading', (
    tester,
  ) async {
    StorageService.instance.setMockInitialValues({
      StorageService.appSettingsKey: '{}',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: PlayerScreen(
          songName: 'Test Song',
          artist: 'Test Artist',
          coverColor: Color(0xFF8052CC),
          coverIcon: Icons.music_note,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
