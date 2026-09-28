import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/core/assets/game_asset_paths.dart';
import 'package:ludo_global/core/widgets/game_asset_picture.dart';

void main() {
  testWidgets('all gameplay image assets load successfully', (
    WidgetTester tester,
  ) async {
    const List<String> assets = <String>[
      GameAssetPaths.pawnRed,
      GameAssetPaths.pawnGreen,
      GameAssetPaths.pawnYellow,
      GameAssetPaths.pawnBlue,
      GameAssetPaths.dice1,
      GameAssetPaths.dice2,
      GameAssetPaths.dice3,
      GameAssetPaths.dice4,
      GameAssetPaths.dice5,
      GameAssetPaths.dice6,
      GameAssetPaths.doubleDistance,
      GameAssetPaths.shield,
      GameAssetPaths.diceControl,
      GameAssetPaths.bonusRoll,
      GameAssetPaths.ludoBoard,
      GameAssetPaths.safeStar,
      GameAssetPaths.directionArrow,
      GameAssetPaths.centerGoal,
    ];

    for (final String asset in assets) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GameAssetPicture.asset(
                asset,
                width: 96,
                height: 96,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GameAssetPicture), findsOneWidget);
    }
  });
}
