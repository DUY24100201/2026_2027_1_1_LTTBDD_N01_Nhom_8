import 'package:flutter_test/flutter_test.dart';
import 'package:lttbdd_nhom8/main.dart';
import 'package:lttbdd_nhom8/screens/home/home_screen.dart';

void main() {
  testWidgets('Melody app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MelodyApp());

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Melody'), findsOneWidget);
  });
}
