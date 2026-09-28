import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/ai/ai_difficulty.dart';
import 'package:ludo_global/features/ludo/domain/ai/ludo_ai_strategy.dart';
import 'package:ludo_global/features/ludo/domain/ai/power_ai_decision.dart';
import 'package:ludo_global/features/ludo/domain/ai/power_ludo_ai_strategy.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_game_engine.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/power_type.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';
import 'package:ludo_global/features/ludo/domain/power/board_power_pickup.dart';
import 'package:ludo_global/features/ludo/domain/power/power_inventory.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_engine.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_state.dart';

void main() {
  group('LudoAiStrategy', () {
    test('easy AI always returns a legal token', () {
      final strategy = LudoAiStrategy(random: Random(4));
      final engine = LudoGameEngine(random: Random(4));
      final state = _normalState(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 4,
            status: TokenStatus.active,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 12,
            status: TokenStatus.active,
          ),
        ],
        greenTokens: const <LudoToken>[],
        diceValue: 2,
        movableTokenIds: const <int>[0, 1],
      );

      final decision = strategy.chooseMove(
        state: state,
        engine: engine,
        difficulty: AiDifficulty.easy,
      );

      expect(state.movableTokenIds, contains(decision.tokenId));
    });

    test('medium AI prefers a capture over a plain move', () {
      final strategy = LudoAiStrategy(random: Random(1));
      final engine = LudoGameEngine(random: Random(1));
      final state = _normalState(
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
            pathPosition: 12,
            status: TokenStatus.active,
          ),
        ],
        greenTokens: const <LudoToken>[
          LudoToken(
            id: 4,
            color: PlayerColor.green,
            pathPosition: 44,
            status: TokenStatus.active,
          ),
        ],
        diceValue: 3,
        movableTokenIds: const <int>[0, 1],
      );

      final decision = strategy.chooseMove(
        state: state,
        engine: engine,
        difficulty: AiDifficulty.medium,
      );

      expect(decision.tokenId, 0);
      expect(decision.reason, contains('captures opponent'));
    });

    test('hard AI prioritizes finishing a token', () {
      final strategy = LudoAiStrategy(random: Random(2));
      final engine = LudoGameEngine(random: Random(2));
      final state = _normalState(
        redTokens: const <LudoToken>[
          LudoToken(
            id: 0,
            color: PlayerColor.red,
            pathPosition: 55,
            status: TokenStatus.homePath,
          ),
          LudoToken(
            id: 1,
            color: PlayerColor.red,
            pathPosition: 10,
            status: TokenStatus.active,
          ),
        ],
        greenTokens: const <LudoToken>[],
        diceValue: 1,
        movableTokenIds: const <int>[0, 1],
      );

      final decision = strategy.chooseMove(
        state: state,
        engine: engine,
        difficulty: AiDifficulty.hard,
      );

      expect(decision.tokenId, 0);
      expect(decision.reason, contains('finishes token'));
    });
  });

  group('PowerLudoAiStrategy', () {
    test('hard AI uses Dice Control to release a base token', () {
      final engine = PowerLudoEngine(
        classicEngine: LudoGameEngine(random: Random(3)),
      );
      final strategy = PowerLudoAiStrategy(random: Random(3));
      final initial = engine.createGame(
        config: const LudoGameConfig(
          mode: LudoGameMode.power,
          matchType: LudoMatchType.computer,
          playerCount: 2,
        ),
        playerNames: const <String>['You', 'Computer 1'],
        startingPlayerIndex: 0,
      );
      final state = initial.copyWith(
        inventories: <String, PowerInventory>{
          ...initial.inventories,
          'player_0': _inventory(diceControl: 1),
        },
      );

      final decision = strategy.choosePreRollAction(
        state: state,
        engine: engine,
        difficulty: AiDifficulty.hard,
      );

      expect(
        decision.type,
        PowerAiPreRollActionType.diceControl,
      );
      expect(decision.diceValue, 6);
    });

    test('hard AI uses Double Distance when it creates a capture', () {
      final engine = PowerLudoEngine(
        classicEngine: LudoGameEngine(random: Random(5)),
      );
      final strategy = PowerLudoAiStrategy(random: Random(5));

      final state = PowerLudoState(
        gameState: _normalState(
          mode: LudoGameMode.power,
          redTokens: const <LudoToken>[
            LudoToken(
              id: 0,
              color: PlayerColor.red,
              pathPosition: 5,
              status: TokenStatus.active,
            ),
          ],
          greenTokens: const <LudoToken>[
            LudoToken(
              id: 4,
              color: PlayerColor.green,
              pathPosition: 50,
              status: TokenStatus.active,
            ),
          ],
          diceValue: 3,
          movableTokenIds: const <int>[0],
        ),
        inventories: <String, PowerInventory>{
          'player_0': _inventory(doubleDistance: 1),
          'player_1': PowerInventory.initial(),
        },
        pickups: _pickups(),
      );

      final decision = strategy.shouldUseDoubleDistance(
        state: state,
        engine: engine,
        difficulty: AiDifficulty.hard,
      );

      expect(decision.shouldUse, isTrue);
      expect(decision.scoreGain, greaterThan(0));
    });
  });
}

LudoGameState _normalState({
  LudoGameMode mode = LudoGameMode.normal,
  required List<LudoToken> redTokens,
  required List<LudoToken> greenTokens,
  required int diceValue,
  required List<int> movableTokenIds,
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
        name: 'Green',
        color: PlayerColor.green,
        tokens: greenTokens,
      ),
    ],
    currentPlayerIndex: 0,
    diceValue: diceValue,
    movableTokenIds: movableTokenIds,
    phase: GamePhase.selectingToken,
    mode: mode,
  );
}


PowerInventory _inventory({
  int doubleDistance = 0,
  int shield = 0,
  int diceControl = 0,
}) {
  return PowerInventory(
    charges: <PowerType, int>{
      PowerType.doubleDistance: doubleDistance,
      PowerType.shield: shield,
      PowerType.diceControl: diceControl,
      PowerType.bonusRoll: 0,
    },
  );
}

Map<PowerType, BoardPowerPickup> _pickups() {
  return const <PowerType, BoardPowerPickup>{
    PowerType.doubleDistance: BoardPowerPickup(
      type: PowerType.doubleDistance,
      globalIndex: 4,
    ),
    PowerType.shield: BoardPowerPickup(
      type: PowerType.shield,
      globalIndex: 10,
    ),
    PowerType.diceControl: BoardPowerPickup(
      type: PowerType.diceControl,
      globalIndex: 15,
    ),
    PowerType.bonusRoll: BoardPowerPickup(
      type: PowerType.bonusRoll,
      globalIndex: 18,
    ),
  };
}
