import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/services/storage_service.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('intro is shown once and persisted for nested pages', (
    tester,
  ) async {
    final storage = StorageService.instance;
    storage.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: IntroDialogPage(
          screenId: 'welcome',
          child: IntroDialogPage(
            screenId: 'welcome',
            child: Scaffold(body: Text('Welcome screen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MÔN HỌC: LẬP TRÌNH THIẾT BỊ DI ĐỘNG'), findsOneWidget);
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome screen'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsNothing);
    expect(
      await storage.readString(
        '${StorageService.introDialogSeenKeyPrefix}_welcome',
      ),
      'true',
    );
  });
}
