import 'package:flutter/material.dart';
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

  testWidgets('local pass-and-play reaches the playable game board', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now').first);
    await tester.pumpAndSettle();

    expect(find.text('SELECT MATCH TYPE'), findsOneWidget);
    expect(find.text('Local / Pass-and-Play'), findsOneWidget);

    await tester.tap(find.text('Local / Pass-and-Play'));
    await tester.pumpAndSettle();

    expect(find.text('LOCAL PLAYERS'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    final startGame = find.text('Start Game');
    await tester.ensureVisible(startGame);
    await tester.tap(startGame);
    await tester.pumpAndSettle();

    expect(find.text('NORMAL LUDO'), findsOneWidget);
    expect(find.text('LOCAL'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Roll the dice to begin.'), findsNothing);
    expect(find.byKey(const Key('roll_dice_button')), findsOneWidget);
  });

  testWidgets('Power Ludo local flow exposes all four powers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now').at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play Now').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local / Pass-and-Play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    final Finder startGame = find.text('Start Game');
    await tester.ensureVisible(startGame);
    await tester.tap(startGame);
    await tester.pumpAndSettle();

    expect(find.text('POWER LUDO'), findsWidgets);
    expect(find.text('DOUBLE'), findsOneWidget);
    expect(find.text('SHIELD'), findsOneWidget);
    expect(find.text('CONTROL'), findsOneWidget);
    expect(find.text('BONUS'), findsOneWidget);
    expect(find.byKey(const Key('roll_dice_button')), findsOneWidget);
  });
}
