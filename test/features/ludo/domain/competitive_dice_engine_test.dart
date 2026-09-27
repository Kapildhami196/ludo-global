import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/dice/competitive_dice_engine.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_policy.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_weights.dart';
import 'package:ludo_global/features/ludo/domain/dice/player_dice_history.dart';
import 'package:ludo_global/features/ludo/domain/dice/weighted_dice_roller.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_game_engine.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';

void main() {
  group('DiceWeights', () {
    test('fair weights give every face equal probability', () {
      final DiceWeights weights = DiceWeights.fair();

      for (int face = 1; face <= 6; face++) {
        expect(weights.weightFor(face), 100);
        expect(
          weights.probabilityFor(face),
          closeTo(1 / 6, 0.0000001),
        );
      }
    });

    test('weight adjustments are immutable', () {
      final DiceWeights fair = DiceWeights.fair();
      final DiceWeights boosted = fair.withAddedWeight(4, 50);

      expect(fair.weightFor(4), 100);
      expect(boosted.weightFor(4), 150);
      expect(boosted.weightFor(1), 100);
    });
  });

  group('WeightedDiceRoller', () {
    test('returns the only face with positive weight', () {
      final WeightedDiceRoller roller =
          WeightedDiceRoller(random: Random(7));
      final DiceWeights weights = DiceWeights.fromValues(
        const <double>[0, 0, 0, 1, 0, 0],
      );

      for (int index = 0; index < 50; index++) {
        expect(roller.roll(weights), 4);
      }
    });

    test('always returns a valid dice face', () {
      final WeightedDiceRoller roller =
          WeightedDiceRoller(random: Random(11));
      final DiceWeights weights = DiceWeights.fair();

      for (int index = 0; index < 1000; index++) {
        expect(roller.roll(weights), inInclusiveRange(1, 6));
      }
    });
  });

  group('PlayerDiceHistory', () {
    test('tracks rolls since six and resets after a six', () {
      PlayerDiceHistory history = const PlayerDiceHistory();

      history = history.recordRoll(2);
      history = history.recordRoll(5);
      expect(history.rollsSinceSix, 2);

      history = history.recordRoll(6);
      expect(history.rollsSinceSix, 0);
      expect(history.recentRolls, const <int>[2, 5, 6]);
    });

    test('keeps only the most recent rolls', () {
      PlayerDiceHistory history = const PlayerDiceHistory();

      for (int value = 0;
          value < PlayerDiceHistory.maxRecentRolls + 5;
          value++) {
        history = history.recordRoll((value % 6) + 1);
      }

      expect(
        history.recentRolls.length,
        PlayerDiceHistory.maxRecentRolls,
      );
    });
  });

  group('CompetitiveDiceEngine Phase 1', () {
    test('starts from fair weights', () {
      final CompetitiveDiceEngine dice =
          CompetitiveDiceEngine(random: Random(3));
      final LudoGameState state = _newGame();

      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: dice.historyFor(state.currentPlayer.id),
      );

      for (int face = 1; face <= 6; face++) {
        expect(
          weights.probabilityFor(face),
          closeTo(1 / 6, 0.0000001),
        );
      }
    });

    test('records history independently for each player', () {
      final CompetitiveDiceEngine dice =
          CompetitiveDiceEngine(random: Random(5));
      final LudoGameState redTurn = _newGame();
      final String redId = redTurn.currentPlayer.id;
      final String yellowId = redTurn.players[1].id;

      dice.roll(state: redTurn);

      expect(dice.historyFor(redId).recentRolls, hasLength(1));
      expect(dice.historyFor(yellowId).recentRolls, isEmpty);

      final LudoGameState yellowTurn = redTurn.copyWith(
        currentPlayerIndex: 1,
      );
      dice.roll(state: yellowTurn);

      expect(dice.historyFor(redId).recentRolls, hasLength(1));
      expect(dice.historyFor(yellowId).recentRolls, hasLength(1));
    });
  });

  group('LudoGameEngine dice policy integration', () {
    test('uses injected dice policy for a normal roll', () {
      final _FixedDicePolicy dice = _FixedDicePolicy(6);
      final LudoGameEngine engine = LudoGameEngine(
        dicePolicy: dice,
        random: Random(1),
      );
      final LudoGameState state = _newGame(engine: engine);

      final result = engine.rollDice(state);

      expect(dice.callCount, 1);
      expect(result.state.diceValue, 6);
      expect(result.state.movableTokenIds, hasLength(4));
    });

    test('forced value bypasses the dice policy', () {
      final _FixedDicePolicy dice = _FixedDicePolicy(2);
      final LudoGameEngine engine = LudoGameEngine(
        dicePolicy: dice,
        random: Random(1),
      );
      final LudoGameState state = _newGame(engine: engine);

      final result = engine.rollDice(
        state,
        forcedValue: 6,
      );

      expect(dice.callCount, 0);
      expect(result.state.diceValue, 6);
    });
  });
}

LudoGameState _newGame({
  LudoGameEngine? engine,
}) {
  final LudoGameEngine gameEngine =
      engine ?? LudoGameEngine(random: Random(1));

  return gameEngine.createGame(
    config: const LudoGameConfig(
      mode: LudoGameMode.normal,
      matchType: LudoMatchType.localPassAndPlay,
      playerCount: 2,
    ),
    playerNames: const <String>['Red', 'Yellow'],
    startingPlayerIndex: 0,
  );
}

class _FixedDicePolicy implements DicePolicy {
  _FixedDicePolicy(this.value);

  final int value;
  int callCount = 0;

  @override
  int roll({
    required LudoGameState state,
  }) {
    callCount++;
    return value;
  }
}
