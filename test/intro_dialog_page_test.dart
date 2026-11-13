import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_page.dart';
import 'package:lttbdd_nhom8/widgets/intro_dialog_observer.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('intro is shown for each page visit without stacking', (
    tester,
  ) async {
    final observer = IntroDialogObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: IntroDialogPage(
          screenId: 'welcome',
          child: IntroDialogPage(
            screenId: 'welcome',
            child: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    const Text('Welcome screen'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => Scaffold(
                              body: Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Second screen'),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open second screen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final introTitle = find.text('MÔN HỌC: LẬP TRÌNH THIẾT BỊ DI ĐỘNG');
    expect(introTitle, findsOneWidget);
    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome screen'), findsOneWidget);
    await tester.tap(find.text('Open second screen'));
    await tester.pumpAndSettle();
    expect(find.text('Second screen'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);
    expect(introTitle, findsOneWidget);

    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second screen'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome screen'), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);
    expect(introTitle, findsOneWidget);
  });
}
