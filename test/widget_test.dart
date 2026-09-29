import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/app/ludo_global_app.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/matchmaking/presentation/computer_setup_screen.dart';

void main() {
  testWidgets('Ludo Global splash transitions to premium home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());

    expect(find.text('LUDO'), findsOneWidget);
    expect(find.text('GLOBAL'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await _pumpUi(tester);

    expect(find.text('NORMAL\nLUDO'), findsOneWidget);
    expect(find.text('POWER\nLUDO'), findsOneWidget);
    expect(
      find.byKey(const Key('rewarded_ad_free_button')),
      findsOneWidget,
    );
    expect(find.text('Lv. 1'), findsNothing);
    expect(find.text('12,500'), findsNothing);
    expect(find.text('320'), findsNothing);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('Friends'), findsNothing);
    expect(find.text('Missions'), findsNothing);
    expect(find.text('Events'), findsNothing);
    expect(find.text('Computer'), findsNothing);
    expect(find.text('Local'), findsNothing);
  });

  testWidgets('Normal mode opens match type directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await _pumpUi(tester);

    await tester.tap(find.text('Play Now').first);
    await _pumpUi(tester);

    expect(find.text('SELECT MATCH TYPE'), findsOneWidget);
    expect(find.text('Normal Ludo'), findsOneWidget);
    expect(find.text('CHOOSE YOUR MODE'), findsNothing);
  });

  testWidgets('local pass-and-play reaches the playable game board', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await _pumpUi(tester);

    await tester.tap(find.text('Play Now').first);
    await _pumpUi(tester);

    expect(find.text('SELECT MATCH TYPE'), findsOneWidget);
    expect(find.text('Local / Pass-and-Play'), findsOneWidget);

    await tester.tap(find.text('Local / Pass-and-Play'));
    await _pumpUi(tester);

    expect(find.text('LOCAL PLAYERS'), findsOneWidget);

    await tester.tap(find.text('2'));
    await _pumpUi(tester);

    final startGame = find.text('Start Game');
    await tester.ensureVisible(startGame);
    await tester.tap(startGame);
    await _pumpUi(tester);

    expect(find.text('NORMAL LUDO'), findsOneWidget);
    expect(find.text('LOCAL'), findsOneWidget);
    expect(find.text('Roll the dice to begin.'), findsNothing);
    expect(find.byKey(const Key('roll_dice_button')), findsOneWidget);
  });

  testWidgets('Power Ludo local flow exposes collected power controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LudoGlobalApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await _pumpUi(tester);

    final Finder powerPlay = find.text('Play Now').at(1);
    await tester.ensureVisible(powerPlay);
    await tester.tap(powerPlay);
    await _pumpUi(tester);

    expect(find.text('SELECT MATCH TYPE'), findsOneWidget);
    expect(find.text('Power Ludo'), findsOneWidget);

    await tester.tap(find.text('Local / Pass-and-Play'));
    await _pumpUi(tester);

    await tester.tap(find.text('2'));
    await _pumpUi(tester);

    final Finder startGame = find.text('Start Game');
    await tester.ensureVisible(startGame);
    await tester.tap(startGame);
    await _pumpUi(tester);

    expect(find.text('POWER LUDO'), findsWidgets);
    expect(find.text('DOUBLE'), findsOneWidget);
    expect(find.text('SHIELD'), findsOneWidget);
    expect(find.text('CONTROL'), findsOneWidget);
    expect(find.text('BONUS'), findsNothing);
    expect(find.byKey(const Key('roll_dice_button')), findsOneWidget);
  });

  testWidgets('computer setup launches an offline AI match', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ComputerSetupScreen(
          mode: LudoGameMode.normal,
        ),
      ),
    );

    expect(find.text('PLAY WITH COMPUTER'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);

    final Finder start = find.text('Start vs Computer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await _pumpUi(tester);

    expect(find.text('VS COMPUTER'), findsOneWidget);
    expect(find.byKey(const Key('roll_dice_button')), findsOneWidget);

    // The computer can be randomly selected to start. Dispose the match,
    // then advance fake time so any in-flight AI delay can finish its
    // mounted check without leaving a pending timer behind.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}


Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 650));
}
