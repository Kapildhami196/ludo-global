import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/dice/competitive_dice_engine.dart';
import 'package:ludo_global/features/ludo/domain/dice/competitive_dice_tuning.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_decision_snapshot.dart';
import 'package:ludo_global/features/ludo/domain/dice/dice_weights.dart';
import 'package:ludo_global/features/ludo/domain/dice/player_dice_history.dart';
import 'package:ludo_global/features/ludo/domain/dice/weighted_dice_roller.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';

void main() {
  group('Competitive dice Phase 4 calibration', () {
    test('decision snapshot probabilities sum to one and respect cap', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _redCaptureState();

      final DiceDecisionSnapshot decision = dice.decisionFor(
        state: state,
        history: const PlayerDiceHistory(rollsSinceSix: 7),
      );

      final double total = decision.probabilities.values.fold<double>(
        0,
        (double sum, double value) => sum + value,
      );

      expect(total, closeTo(1, 0.0000001));
      expect(
        decision.probabilities.values.every(
          (double value) =>
              value <= dice.tuning.maxSingleFaceProbability + 0.0000001,
        ),
        isTrue,
      );
      expect(decision.context.captureRolls, contains(3));
      expect(decision.context.rollsSinceSix, 7);
    });

    test('custom tuning changes behavior without changing engine code', () {
      const CompetitiveDiceTuning aggressiveCapture =
          CompetitiveDiceTuning(
        captureBoost: 80,
      );
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine(
        tuning: aggressiveCapture,
      );
      final DiceWeights weights = dice.weightsFor(
        state: _redCaptureState(),
        history: const PlayerDiceHistory(),
      );

      expect(weights.weightFor(3), 180);
      expect(weights.weightFor(1), 100);
    });

    test('neutral Monte Carlo remains approximately uniform', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final DiceWeights weights = dice.decisionFor(
        state: _neutralState(),
      ).weights;
      final Map<int, double> frequencies = _sample(
        weights,
        rolls: 60000,
        seed: 20260927,
      );

      for (int face = 1; face <= 6; face++) {
        expect(
          frequencies[face]!,
          inInclusiveRange(0.155, 0.178),
          reason: 'face $face should stay close to 1/6',
        );
      }
    });

    test('capture Monte Carlo raises action rate without dominating', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final DiceDecisionSnapshot decision = dice.decisionFor(
        state: _redCaptureState(),
      );
      final Map<int, double> frequencies = _sample(
        decision.weights,
        rolls: 50000,
        seed: 4815,
      );

      final double captureRate = frequencies[3]!;
      expect(captureRate, inInclusiveRange(0.195, 0.23));
      expect(
        captureRate,
        greaterThan(frequencies[1]! + 0.02),
      );
      expect(
        captureRate,
        lessThan(dice.tuning.maxSingleFaceProbability),
      );
    });

    test('capped Monte Carlo never behaves like a forced outcome', () {
      final DiceWeights capped = DiceWeights.fromValues(
        const <double>[100, 100, 100, 100, 100, 5000],
      ).cappedAtProbability(0.40);

      final Map<int, double> frequencies = _sample(
        capped,
        rolls: 50000,
        seed: 99,
      );

      expect(frequencies[6]!, inInclusiveRange(0.385, 0.415));
      for (int face = 1; face <= 5; face++) {
        expect(frequencies[face]!, greaterThan(0.105));
      }
    });

    test('equivalent red and yellow situations receive equal weights', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();

      final DiceWeights red = dice.decisionFor(
        state: _redCaptureState(),
      ).weights;
      final DiceWeights yellow = dice.decisionFor(
        state: _yellowCaptureState(),
      ).weights;

      for (int face = 1; face <= 6; face++) {
        expect(
          yellow.weightFor(face),
          closeTo(red.weightFor(face), 0.0000001),
          reason: 'face $face must be player-color neutral',
        );
      }
    });

    test('cooldown Monte Carlo measurably reduces capture assistance', () {
      final CompetitiveDiceEngine dice = CompetitiveDiceEngine();
      final LudoGameState state = _redCaptureState();

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

      final Map<int, double> normalFrequency = _sample(
        normal,
        rolls: 40000,
        seed: 17,
      );
      final Map<int, double> cooldownFrequency = _sample(
        cooldown,
        rolls: 40000,
        seed: 17,
      );

      expect(
        normalFrequency[3]!,
        greaterThan(cooldownFrequency[3]! + 0.02),
      );
    });
  });
}

Map<int, double> _sample(
  DiceWeights weights, {
  required int rolls,
  required int seed,
}) {
  final WeightedDiceRoller roller =
      WeightedDiceRoller(random: Random(seed));
  final Map<int, int> counts = <int, int>{
    for (int face = 1; face <= 6; face++) face: 0,
  };

  for (int index = 0; index < rolls; index++) {
    final int value = roller.roll(weights);
    counts[value] = counts[value]! + 1;
  }

  return <int, double>{
    for (int face = 1; face <= 6; face++)
      face: counts[face]! / rolls,
  };
}

LudoGameState _neutralState() {
  return _state(
    currentPlayerIndex: 0,
    redTokens: const <LudoToken>[
      LudoToken(
        id: 0,
        color: PlayerColor.red,
        pathPosition: 10,
        status: TokenStatus.active,
      ),
    ],
    yellowTokens: const <LudoToken>[
      LudoToken(
        id: 4,
        color: PlayerColor.yellow,
        pathPosition: 10,
        status: TokenStatus.active,
      ),
    ],
  );
}

LudoGameState _redCaptureState() {
  return _state(
    currentPlayerIndex: 0,
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
}

LudoGameState _yellowCaptureState() {
  return _state(
    currentPlayerIndex: 1,
    redTokens: const <LudoToken>[
      LudoToken(
        id: 0,
        color: PlayerColor.red,
        pathPosition: 31,
        status: TokenStatus.active,
      ),
      LudoToken(
        id: 1,
        color: PlayerColor.red,
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
        pathPosition: 57,
        status: TokenStatus.finished,
      ),
    ],
  );
}

LudoGameState _state({
  required int currentPlayerIndex,
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
    currentPlayerIndex: currentPlayerIndex,
    phase: GamePhase.waitingForRoll,
    mode: LudoGameMode.normal,
  );
}
