import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/app/ludo_global_app.dart';

void main() {
  testWidgets('Ludo Global splash transitions to premium home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());

    expect(find.text('LUDO'), findsOneWidget);
    expect(find.text('GLOBAL'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    expect(find.text('NORMAL\nLUDO'), findsOneWidget);
    expect(find.text('POWER\nLUDO'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
  });

  testWidgets('Normal mode opens mode selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now').first);
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(find.text('Selected from Home: Normal Ludo'), findsOneWidget);
  });
}
