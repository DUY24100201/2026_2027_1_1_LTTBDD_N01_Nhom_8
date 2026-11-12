import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/main.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';
import 'package:lttbdd_nhom8/screens/intro/intro_screen.dart';

void main() {
  testWidgets('Melody app starts on intro screen then navigates home', (WidgetTester tester) async {
    await tester.pumpWidget(const MelodyApp());

    expect(find.byType(IntroScreen), findsOneWidget);
    expect(find.text('TIẾP TỤC'), findsOneWidget);

    await tester.tap(find.text('TIẾP TỤC'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Melody'), findsOneWidget);
  });
}
