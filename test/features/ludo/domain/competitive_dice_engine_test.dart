import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/dice/competitive_dice_engine.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_policy.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_weights.dart';
import 'package:ludo_global/features/ludo/domain/dice/player_dice_history.dart';
import 'package:ludo_global/features/ludo/domain/dice/weighted_dice_roller.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_game_engine.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_event.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';

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

  group('CompetitiveDiceEngine Phases 2 and 3', () {
    test('neutral board keeps all faces equally weighted', () {
      final CompetitiveDiceEngine dice =
          CompetitiveDiceEngine(random: Random(3));
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 10,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[],
      );

      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
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

    test('six drought progressively increases face six weight', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 10,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[],
      );

      final DiceWeights afterThree = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(rollsSinceSix: 3),
      );
      final DiceWeights afterFive = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(rollsSinceSix: 5),
      );
      final DiceWeights afterSeven = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(rollsSinceSix: 7),
      );

      expect(afterThree.weightFor(6), 115);
      expect(afterFive.weightFor(6), 135);
      expect(afterSeven.weightFor(6), 160);
      expect(afterSeven.weightFor(1), 100);
    });

    test('all tokens in base gives six an additional boost', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _newGame();

      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(weights.weightFor(6), 125);
      expect(weights.weightFor(1), 100);
    });

    test('capture opportunity boosts the exact capture roll', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 2,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 31,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 5,
            color: PlayerColor.yellow,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.captureRolls, contains(3));
      expect(weights.weightFor(3), 135);
      expect(weights.weightFor(2), 100);
    });

    test('escape to safe cell boosts the required roll', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 5,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 28,
            status: TokenStatus.active,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.escapeRolls, contains(3));
      expect(weights.weightFor(3), 125);
    });

    test('stale match adds an action boost to useful rolls', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 10,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
          ),
        ],
        yellowTokens: const <LudoToken>[],
      );

      for (int index = 0; index < 8; index++) {
        dice.recordGameEvents(
          const <LudoGameEvent>[
            LudoGameEvent(
              type: LudoGameEventType.tokenMoved,
              playerId: 'player_0',
            ),
          ],
        );
      }

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.isStaleMatch, isTrue);
      expect(context.actionRolls, contains(6));
      expect(weights.weightFor(6), 115);
    });

    test('major event resets stale-match counter', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();

      for (int index = 0; index < 8; index++) {
        dice.recordGameEvents(
          const <LudoGameEvent>[
            LudoGameEvent(
              type: LudoGameEventType.tokenMoved,
              playerId: 'player_0',
            ),
          ],
        );
      }

      expect(dice.turnsWithoutMajorEvent, 8);

      dice.recordGameEvents(
        const <LudoGameEvent>[
          LudoGameEvent(
            type: LudoGameEventType.tokenMoved,
            playerId: 'player_0',
          ),
          LudoGameEvent(
            type: LudoGameEventType.tokenCaptured,
            playerId: 'player_0',
          ),
        ],
      );

      expect(dice.turnsWithoutMajorEvent, 0);
    });

    test('home-entry opportunity boosts the exact roll', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 50,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 50,
            status: TokenStatus.active,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.homeEntryRolls, contains(2));
      expect(weights.weightFor(2), 112);
    });

    test('exact finish receives finish and endgame pressure boosts', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 2,
            color: PlayerColor.red,
            pathPosition: 55,
            status: TokenStatus.homePath,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(id: 4, color: PlayerColor.yellow),
          LudoToken(id: 5, color: PlayerColor.yellow),
          LudoToken(id: 6, color: PlayerColor.yellow),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.currentPlayerNearWin, isTrue);
      expect(context.finishRolls, contains(2));
      expect(weights.weightFor(2), 140);
    });

    test('blockade creation boosts the required roll', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 2,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 5,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 2,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 5,
            color: PlayerColor.yellow,
            pathPosition: 5,
            status: TokenStatus.active,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.blockadeRolls, contains(3));
      expect(weights.weightFor(3), 112);
    });

    test('significantly behind player gets small useful-action boost', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 10,
            status: TokenStatus.active,
          ),
          LudoToken(id: 1, color: PlayerColor.red),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 50,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 5,
            color: PlayerColor.yellow,
            pathPosition: 50,
            status: TokenStatus.active,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.isSignificantlyBehind, isTrue);
      expect(context.actionRolls, contains(6));
      expect(weights.weightFor(6), 110);
    });

    test('opponent near win increases defensive capture pressure', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 2,
            color: PlayerColor.red,
            pathPosition: 20,
            status: TokenStatus.active,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 5,
            color: PlayerColor.yellow,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
          LudoToken(
            id: 6,
            color: PlayerColor.yellow,
            pathPosition: 49,
            status: TokenStatus.active,
          ),
        ],
      );

      final context = dice.contextFor(state: state);
      final DiceWeights weights = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );

      expect(context.opponentNearWin, isTrue);
      expect(context.captureRolls, contains(3));
      expect(weights.weightFor(3), 155);
    });

    test('probability cap prevents a face exceeding forty percent', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final DiceWeights weights = DiceWeights.fromValues(
        const <double>[100, 100, 100, 100, 100, 1000],
      ).cappedAtProbability(
        dice.tuning.maxSingleFaceProbability,
      );

      expect(
        weights.probabilityFor(6),
        closeTo(0.40, 0.0000001),
      );
    });

    test('assist cooldown dampens adaptive boosts', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 2,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 31,
            status: TokenStatus.active,
          ),
          LudoToken(id: 5, color: PlayerColor.yellow),
        ],
      );

      final DiceWeights normal = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(),
      );
      final DiceWeights cooldown = dice.weightsFor(
        state: state,
        history: const PlayerDiceHistory(
          strongAssistCooldown: 2,
        ),
      );

      expect(normal.weightFor(3), 135);
      expect(cooldown.weightFor(3), closeTo(112.25, 0.0001));
    });

    test('strong assisted roll starts then decrements cooldown', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine(
        roller: _FixedWeightedDiceRoller(3),
      );
      final LudoGameState state = _stateWithTokens(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 2,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 57,
            status: TokenStatus.finished,
          ),
        ],
        yellowTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.yellow,
            pathPosition: 31,
            status: TokenStatus.active,
          ),
          LudoToken(id: 5, color: PlayerColor.yellow),
        ],
      );

      dice.roll(state: state);
      expect(
        dice.historyFor('player_0').strongAssistCooldown,
        dice.tuning.strongAssistCooldownRolls,
      );

      dice.roll(state: state);
      expect(
        dice.historyFor('player_0').strongAssistCooldown,
        dice.tuning.strongAssistCooldownRolls - 1,
      );
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

LudoGameState _stateWithTokens({
  required List<LudoToken> redTokens,
  required List<LudoToken> yellowTokens,
}) {
  return LudoGameState(
    players: <LudoPlayer>[
      LudoPlayer(
        id: 'player_0',
        name: 'Red',
        color: PlayerColor.red,
        tokens: redTokens,
      ),
      LudoPlayer(
        id: 'player_1',
        name: 'Yellow',
        color: PlayerColor.yellow,
        tokens: yellowTokens,
      ),
    ],
    currentPlayerIndex: 0,
    phase: GamePhase.waitingForRoll,
    mode: LudoGameMode.normal,
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

class _FixedWeightedDiceRoller extends WeightedDiceRoller {
  _FixedWeightedDiceRoller(this.value);

  final int value;

  @override
  int roll(DiceWeights weights) => value;
}
