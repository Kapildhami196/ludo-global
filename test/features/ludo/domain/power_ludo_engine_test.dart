import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/power_type.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';
import 'package:ludo_global/features/ludo/domain/power/power_inventory.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_engine.dart';
import 'package:ludo_global/features/ludo/domain/power/power_ludo_state.dart';
import 'package:ludo_global/features/ludo/domain/power/power_rules.dart';
import 'package:ludo_global/features/ludo/domain/power/shield_effect.dart';

void main() {
  final PowerLudoEngine engine = PowerLudoEngine();

  group('PowerLudoEngine', () {
    test('starts every player with one charge of every power', () {
      final PowerLudoState state = engine.createGame(
        config: const LudoGameConfig(
          mode: LudoGameMode.power,
          matchType: LudoMatchType.localPassAndPlay,
          playerCount: 2,
        ),
        playerNames: const <String>['Red', 'Green'],
      );

      for (final player in state.gameState.players) {
        final PowerInventory inventory =
            state.inventoryFor(player.id);
        for (final PowerType type in PowerType.values) {
          expect(
            inventory.count(type),
            PowerRules.initialChargesPerPower,
          );
        }
      }
    });

    test('Dice Control forces the selected value and consumes charge', () {
      final PowerLudoState initial = _newTwoPlayerGame(engine);

      final result = engine.useDiceControl(initial, 6);

      expect(result.state.gameState.diceValue, 6);
      expect(
        result.state.gameState.phase,
        GamePhase.selectingToken,
      );
      expect(
        result.state
            .inventoryFor('player_0')
            .count(PowerType.diceControl),
        0,
      );
    });

    test('Double Distance moves an active token twice the die value', () {
      final PowerLudoState initial = _powerStateWithTokens(
        currentPlayerIndex: 0,
        redProgresses: const <int>[5],
        greenProgresses: const <int>[],
        phase: GamePhase.selectingToken,
        diceValue: 3,
        movableTokenIds: const <int>[0],
      );

      final armed = engine.armDoubleDistance(initial);
      expect(armed.state.doubleDistanceArmed, isTrue);

      final moved = engine.moveToken(armed.state, 0);

      expect(
        moved.state.gameState.players.first.tokens.first.pathPosition,
        11,
      );
      expect(
        moved.state
            .inventoryFor('player_0')
            .count(PowerType.doubleDistance),
        0,
      );
      expect(moved.state.doubleDistanceArmed, isFalse);
    });

    test('Double Distance cannot be used only to release a base token', () {
      final PowerLudoState initial = _powerStateWithTokens(
        currentPlayerIndex: 0,
        redProgresses: const <int>[-1],
        greenProgresses: const <int>[],
        phase: GamePhase.selectingToken,
        diceValue: 6,
        movableTokenIds: const <int>[0],
      );

      expect(engine.canUseDoubleDistance(initial), isFalse);
      expect(
        () => engine.armDoubleDistance(initial),
        throwsStateError,
      );
    });

    test('Shield prevents capture of the protected token', () {
      final PowerLudoState initial = _powerStateWithTokens(
        currentPlayerIndex: 0,
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

      final moved = engine.moveToken(initial, 0);
      final LudoToken green =
          moved.state.gameState.players[1].tokens.first;

      expect(green.status, TokenStatus.active);
      expect(green.pathPosition, 44);
    });

    test('Shield expires when its owner next receives the turn', () {
      PowerLudoState state = _powerStateWithTokens(
        currentPlayerIndex: 1,
        redProgresses: const <int>[-1],
        greenProgresses: const <int>[10],
        phase: GamePhase.waitingForRoll,
      );

      final shielded = engine.applyShield(state, 4);
      state = shielded.state;
      expect(state.isShielded(4), isTrue);

      final greenEndsTurn = engine.useDiceControl(state, 1);
      state = greenEndsTurn.state;
      expect(state.gameState.currentPlayerIndex, 0);
      expect(state.isShielded(4), isTrue);

      final redEndsTurn = engine.useDiceControl(state, 1);
      state = redEndsTurn.state;
      expect(state.gameState.currentPlayerIndex, 1);
      expect(state.isShielded(4), isFalse);
    });

    test('Bonus Roll preserves a turn that would otherwise pass', () {
      PowerLudoState state = _newTwoPlayerGame(engine);

      state = engine.queueBonusRoll(state).state;
      expect(state.bonusRollQueued, isTrue);

      final result = engine.useDiceControl(state, 1);

      expect(result.state.gameState.currentPlayerIndex, 0);
      expect(
        result.state.gameState.phase,
        GamePhase.waitingForRoll,
      );
      expect(result.state.bonusRollQueued, isFalse);
      expect(
        result.state
            .inventoryFor('player_0')
            .count(PowerType.bonusRoll),
        0,
      );
    });

    test('each power charge can only be consumed once', () {
      PowerLudoState state = _newTwoPlayerGame(engine);

      state = engine.queueBonusRoll(state).state;

      expect(
        () => engine.queueBonusRoll(state),
        throwsStateError,
      );
    });
  });
}

PowerLudoState _newTwoPlayerGame(PowerLudoEngine engine) {
  return engine.createGame(
    config: const LudoGameConfig(
      mode: LudoGameMode.power,
      matchType: LudoMatchType.localPassAndPlay,
      playerCount: 2,
    ),
    playerNames: const <String>['Red', 'Green'],
  );
}

PowerLudoState _powerStateWithTokens({
  required int currentPlayerIndex,
  required List<int> redProgresses,
  required List<int> greenProgresses,
  required GamePhase phase,
  int? diceValue,
  List<int> movableTokenIds = const <int>[],
  Map<int, ShieldEffect> shields = const <int, ShieldEffect>{},
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
              : progresses[index] < 52
                  ? TokenStatus.active
                  : progresses[index] < 57
                      ? TokenStatus.homePath
                      : TokenStatus.finished,
        ),
    ];
  }

  final LudoGameState gameState = LudoGameState(
    players: <LudoPlayer>[
      LudoPlayer(
        id: 'player_0',
        name: 'Red',
        color: PlayerColor.red,
        tokens: buildTokens(
          PlayerColor.red,
          0,
          redProgresses,
        ),
      ),
      LudoPlayer(
        id: 'player_1',
        name: 'Green',
        color: PlayerColor.green,
        tokens: buildTokens(
          PlayerColor.green,
          4,
          greenProgresses,
        ),
      ),
    ],
    currentPlayerIndex: currentPlayerIndex,
    diceValue: diceValue,
    movableTokenIds: movableTokenIds,
    phase: phase,
    mode: LudoGameMode.power,
  );

  return PowerLudoState(
    gameState: gameState,
    inventories: <String, PowerInventory>{
      'player_0': PowerInventory.initial(),
      'player_1': PowerInventory.initial(),
    },
    shields: shields,
  );
}
