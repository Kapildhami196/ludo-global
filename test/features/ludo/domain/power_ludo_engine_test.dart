import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_board_map.dart';
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
import 'package:ludo_global/features/ludo/domain/power/power_game_event.dart';
import 'package:ludo_global/features/ludo/domain/power/power_inventory.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_engine.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_state.dart';
import 'package:ludo_global/features/ludo/domain/power/power_rules.dart';
import 'package:ludo_global/features/ludo/domain/power/shield_effect.dart';
import 'package:ludo_global/features/ludo/domain/rules/classic_rules.dart';

void main() {
  final PowerLudoEngine engine = PowerLudoEngine(
    classicEngine: LudoGameEngine(random: Random(1)),
    random: Random(1),
  );

  group('Power Ludo V2 pickups', () {
    test('starts with zero held powers and four unique board pickups', () {
      final PowerLudoState state = engine.createGame(
        config: const LudoGameConfig(
          mode: LudoGameMode.power,
          matchType: LudoMatchType.localPassAndPlay,
          playerCount: 2,
        ),
        playerNames: const <String>['Red', 'Yellow'],
        startingPlayerIndex: 0,
      );

      for (final player in state.gameState.players) {
        for (final PowerType type in PowerRules.heldPowerTypes) {
          expect(state.inventoryFor(player.id).count(type), 0);
        }
      }

      expect(state.pickups.length, 4);
      expect(
        state.pickups.values.map((pickup) => pickup.globalIndex).toSet().length,
        4,
      );

      for (final pickup in state.pickups.values) {
        expect(
          PowerRules.pickupEligibleGlobalIndices,
          contains(pickup.globalIndex),
        );
        expect(
          LudoBoardMap.isSafeGlobalIndex(pickup.globalIndex),
          isFalse,
        );
      }
    });

    test('landing exactly on held power collects and relocates it', () {
      final int landingGlobalIndex = LudoBoardMap.globalIndexFor(
        color: PlayerColor.red,
        pathPosition: 5,
      );
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[2],
        greenProgresses: const <int>[],
        phase: GamePhase.selectingToken,
        diceValue: 3,
        movableTokenIds: const <int>[0],
        pickups: _pickups(
          doubleDistance: landingGlobalIndex,
          shield: 10,
          diceControl: 15,
          bonusRoll: 18,
        ),
      );

      final result = engine.moveToken(state, 0);

      expect(
        result.state
            .inventoryFor('player_0')
            .count(PowerType.doubleDistance),
        1,
      );
      expect(
        result.state.pickups[PowerType.doubleDistance]!.globalIndex,
        isNot(landingGlobalIndex),
      );
      expect(
        result.powerEvents.any(
          (event) =>
              event.type == PowerGameEventType.powerCollected &&
              event.powerType == PowerType.doubleDistance,
        ),
        isTrue,
      );
    });

    test('passing over a pickup does not collect it', () {
      final int passingGlobalIndex = LudoBoardMap.globalIndexFor(
        color: PlayerColor.red,
        pathPosition: 4,
      );
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[2],
        greenProgresses: const <int>[],
        phase: GamePhase.selectingToken,
        diceValue: 3,
        movableTokenIds: const <int>[0],
        pickups: _pickups(
          doubleDistance: passingGlobalIndex,
          shield: 10,
          diceControl: 15,
          bonusRoll: 18,
        ),
      );

      final result = engine.moveToken(state, 0);

      expect(
        result.state
            .inventoryFor('player_0')
            .count(PowerType.doubleDistance),
        0,
      );
      expect(
        result.state.pickups[PowerType.doubleDistance]!.globalIndex,
        passingGlobalIndex,
      );
    });

    test('Bonus Roll triggers immediately on exact landing and relocates', () {
      final int landingGlobalIndex = LudoBoardMap.globalIndexFor(
        color: PlayerColor.red,
        pathPosition: 5,
      );
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[2],
        greenProgresses: const <int>[-1],
        phase: GamePhase.selectingToken,
        diceValue: 3,
        movableTokenIds: const <int>[0],
        pickups: _pickups(
          doubleDistance: 10,
          shield: 15,
          diceControl: 18,
          bonusRoll: landingGlobalIndex,
        ),
      );

      final result = engine.moveToken(state, 0);

      expect(result.state.gameState.currentPlayerIndex, 0);
      expect(result.state.gameState.phase, GamePhase.waitingForRoll);
      expect(
        result.state.inventoryFor('player_0').count(PowerType.bonusRoll),
        0,
      );
      expect(
        result.state.pickups[PowerType.bonusRoll]!.globalIndex,
        isNot(landingGlobalIndex),
      );
      expect(
        result.powerEvents.any(
          (event) => event.type == PowerGameEventType.bonusRollTriggered,
        ),
        isTrue,
      );
    });
  });

  group('Power Ludo V2 held powers', () {
    test('Dice Control behaves like a natural six', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[-1],
        greenProgresses: const <int>[-1],
        phase: GamePhase.waitingForRoll,
        redInventory: _inventory(diceControl: 1),
      );

      final rolled = engine.useDiceControl(state, 6);
      expect(rolled.state.gameState.diceValue, 6);
      expect(rolled.state.gameState.phase, GamePhase.selectingToken);

      final moved = engine.moveToken(
        rolled.state,
        rolled.state.gameState.movableTokenIds.first,
      );

      expect(moved.state.gameState.currentPlayerIndex, 0);
      expect(moved.state.gameState.phase, GamePhase.waitingForRoll);
      expect(moved.state.gameState.consecutiveSixes, 1);
      expect(
        moved.state
            .inventoryFor('player_0')
            .count(PowerType.diceControl),
        0,
      );
    });

    test('Double Distance is armed before roll and doubles movement', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[5],
        greenProgresses: const <int>[],
        phase: GamePhase.waitingForRoll,
        redInventory: _inventory(doubleDistance: 1),
      );

      final armed = engine.armDoubleDistance(state);
      expect(armed.state.doubleDistanceArmed, isTrue);
      expect(
        armed.state
            .inventoryFor('player_0')
            .count(PowerType.doubleDistance),
        0,
      );

      final rolled = engine.rollDice(armed.state, forcedValue: 3);
      expect(rolled.state.gameState.diceValue, 3);
      expect(rolled.state.gameState.movableTokenIds, contains(0));
      expect(rolled.state.doubleDistanceArmed, isTrue);

      final moved = engine.moveToken(rolled.state, 0);
      expect(
        moved.state.gameState.players.first.tokens.first.pathPosition,
        11,
      );
      expect(moved.state.doubleDistanceArmed, isFalse);
    });

    test('Double Distance cannot be armed with only base tokens', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[-1],
        greenProgresses: const <int>[],
        phase: GamePhase.waitingForRoll,
        redInventory: _inventory(doubleDistance: 1),
      );

      expect(engine.canUseDoubleDistance(state), isFalse);
      expect(() => engine.armDoubleDistance(state), throwsStateError);
    });

    test('Double Distance roll cannot release a base token', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[5, -1],
        greenProgresses: const <int>[],
        phase: GamePhase.waitingForRoll,
        redInventory: _inventory(doubleDistance: 1),
      );

      final armed = engine.armDoubleDistance(state);
      final rolled = engine.rollDice(armed.state, forcedValue: 6);

      expect(rolled.state.gameState.movableTokenIds, contains(0));
      expect(rolled.state.gameState.movableTokenIds, isNot(contains(1)));
    });

    test('Shield protects all eligible track pawns with one charge', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[2, 5, -1],
        greenProgresses: const <int>[],
        phase: GamePhase.waitingForRoll,
        redInventory: _inventory(shield: 1),
      );

      final result = engine.applyShield(state);

      expect(result.state.isShielded(0), isTrue);
      expect(result.state.isShielded(1), isTrue);
      expect(result.state.isShielded(2), isFalse);
      expect(
        result.state.inventoryFor('player_0').count(PowerType.shield),
        0,
      );
      expect(
        result.powerEvents
            .where((event) => event.type == PowerGameEventType.shieldApplied)
            .length,
        2,
      );
    });

    test('shielded enemy can share unsafe square without capture', () {
      final PowerLudoState state = _stateWithTokens(
        redProgresses: const <int>[2],
        greenProgresses: const <int>[44],
        phase: GamePhase.selectingToken,
        diceValue: 3,
        movableTokenIds: const <int>[0],
        shields: const <int, ShieldEffect>{
          4: ShieldEffect(
            tokenId: 4,
            ownerPlayerId: 'player_1',
            activatedAtTurnSerial: 0,
          ),
        },
      );

      final moved = engine.moveToken(state, 0);
      final LudoToken red = moved.state.gameState.players[0].tokens.first;
      final LudoToken green = moved.state.gameState.players[1].tokens.first;

      expect(red.pathPosition, 5);
      expect(green.pathPosition, 44);
      expect(green.status, TokenStatus.active);
      expect(
        LudoBoardMap.globalIndexFor(
          color: red.color,
          pathPosition: red.pathPosition,
        ),
        LudoBoardMap.globalIndexFor(
          color: green.color,
          pathPosition: green.pathPosition,
        ),
      );
    });

    test('Shield expires when owner next receives the turn', () {
      PowerLudoState state = _stateWithTokens(
        currentPlayerIndex: 1,
        redProgresses: const <int>[-1],
        greenProgresses: const <int>[10],
        phase: GamePhase.waitingForRoll,
        greenInventory: _inventory(shield: 1, diceControl: 1),
        redInventory: _inventory(diceControl: 1),
      );

      state = engine.applyShield(state).state;
      expect(state.isShielded(4), isTrue);

      state = engine.useDiceControl(state, 1).state;
      state = engine.moveToken(state, 4).state;
      expect(state.gameState.currentPlayerIndex, 0);
      expect(state.isShielded(4), isTrue);

      state = engine.useDiceControl(state, 1).state;
      expect(state.gameState.currentPlayerIndex, 1);
      expect(state.isShielded(4), isFalse);
    });
  });
}

Map<PowerType, BoardPowerPickup> _pickups({
  int doubleDistance = 4,
  int shield = 10,
  int diceControl = 15,
  int bonusRoll = 18,
}) {
  return <PowerType, BoardPowerPickup>{
    PowerType.doubleDistance: BoardPowerPickup(
      type: PowerType.doubleDistance,
      globalIndex: doubleDistance,
    ),
    PowerType.shield: BoardPowerPickup(
      type: PowerType.shield,
      globalIndex: shield,
    ),
    PowerType.diceControl: BoardPowerPickup(
      type: PowerType.diceControl,
      globalIndex: diceControl,
    ),
    PowerType.bonusRoll: BoardPowerPickup(
      type: PowerType.bonusRoll,
      globalIndex: bonusRoll,
    ),
  };
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

PowerLudoState _stateWithTokens({
  int currentPlayerIndex = 0,
  required List<int> redProgresses,
  required List<int> greenProgresses,
  required GamePhase phase,
  int? diceValue,
  List<int> movableTokenIds = const <int>[],
  PowerInventory? redInventory,
  PowerInventory? greenInventory,
  Map<int, ShieldEffect> shields = const <int, ShieldEffect>{},
  Map<PowerType, BoardPowerPickup>? pickups,
}) {
  List<LudoToken> buildTokens(
    PlayerColor color,
    int idStart,
    List<int> progresses,
  ) {
    return <LudoToken>[
      for (int index = 0; index < progresses.length; index++)
        LudoToken(
          id: idStart + index,
          color: color,
          pathPosition: progresses[index],
          status: progresses[index] < 0
              ? TokenStatus.base
              : progresses[index] < ClassicRules.sharedPathProgressLength
                  ? TokenStatus.active
                  : progresses[index] < ClassicRules.finishProgress
                      ? TokenStatus.homePath
                      : TokenStatus.finished,
        ),
    ];
  }

  return PowerLudoState(
    gameState: LudoGameState(
      players: <LudoPlayer>[
        LudoPlayer(
          id: 'player_0',
          name: 'Red',
          color: PlayerColor.red,
          tokens: buildTokens(PlayerColor.red, 0, redProgresses),
        ),
        LudoPlayer(
          id: 'player_1',
          name: 'Green',
          color: PlayerColor.green,
          tokens: buildTokens(PlayerColor.green, 4, greenProgresses),
        ),
      ],
      currentPlayerIndex: currentPlayerIndex,
      diceValue: diceValue,
      movableTokenIds: movableTokenIds,
      phase: phase,
      mode: LudoGameMode.power,
    ),
    inventories: <String, PowerInventory>{
      'player_0': redInventory ?? PowerInventory.initial(),
      'player_1': greenInventory ?? PowerInventory.initial(),
    },
    pickups: pickups ?? _pickups(),
    shields: shields,
  );
}
