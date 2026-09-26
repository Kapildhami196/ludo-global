import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_board_map.dart';
import 'package:ludo_global/features/ludo/domain/engine/ludo_game_engine.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';
import 'package:ludo_global/features/ludo/domain/rules/classic_rules.dart';

void main() {
  final LudoGameEngine engine = LudoGameEngine();

  group('LudoBoardMap', () {
    test('contains exactly 52 shared track cells', () {
      expect(
        LudoBoardMap.commonPath.length,
        ClassicRules.commonPathLength,
      );
      expect(LudoBoardMap.commonPath.toSet().length, 52);
    });

    test('maps each color to the correct global start index', () {
      expect(
        LudoBoardMap.globalIndexFor(
          color: PlayerColor.red,
          pathPosition: 0,
        ),
        0,
      );
      expect(
        LudoBoardMap.globalIndexFor(
          color: PlayerColor.green,
          pathPosition: 0,
        ),
        13,
      );
      expect(
        LudoBoardMap.globalIndexFor(
          color: PlayerColor.yellow,
          pathPosition: 0,
        ),
        26,
      );
      expect(
        LudoBoardMap.globalIndexFor(
          color: PlayerColor.blue,
          pathPosition: 0,
        ),
        39,
      );
    });
  });

  group('LudoGameEngine', () {
    test('creates a local game with four tokens per player', () {
      final LudoGameState state = engine.createGame(
        config: const LudoGameConfig(
          mode: LudoGameMode.normal,
          matchType: LudoMatchType.localPassAndPlay,
          playerCount: 4,
        ),
        playerNames: const ['A', 'B', 'C', 'D'],
      );

      expect(state.players.length, 4);
      expect(
        state.players.every(
          (player) =>
              player.tokens.length == ClassicRules.tokensPerPlayer,
        ),
        isTrue,
      );
      expect(state.phase, GamePhase.waitingForRoll);
      expect(state.currentPlayer.color, PlayerColor.red);
    });

    test('a token in base requires a six to enter', () {
      final LudoGameState initial = _newTwoPlayerGame(engine);

      expect(engine.getMovableTokenIds(initial, 5), isEmpty);
      expect(engine.getMovableTokenIds(initial, 6), hasLength(4));
    });

    test('a non-six with no legal move advances the turn', () {
      final LudoGameState initial = _newTwoPlayerGame(engine);

      final result = engine.rollDice(initial, forcedValue: 3);

      expect(result.state.currentPlayerIndex, 1);
      expect(result.state.phase, GamePhase.waitingForRoll);
      expect(result.state.diceValue, isNull);
    });

    test('rolling six releases a token and grants another roll', () {
      final LudoGameState initial = _newTwoPlayerGame(engine);

      final rolled = engine.rollDice(initial, forcedValue: 6);
      final int tokenId = rolled.state.movableTokenIds.first;
      final moved = engine.moveToken(rolled.state, tokenId);

      final LudoToken token = moved.state.players.first.tokens.first;

      expect(token.pathPosition, 0);
      expect(token.status, TokenStatus.active);
      expect(moved.state.currentPlayerIndex, 0);
      expect(moved.state.phase, GamePhase.waitingForRoll);
      expect(moved.state.consecutiveSixes, 1);
    });

    test('third consecutive six forfeits the turn', () {
      LudoGameState state = _newTwoPlayerGame(engine);

      var action = engine.rollDice(state, forcedValue: 6);
      state = engine.moveToken(
        action.state,
        action.state.movableTokenIds.first,
      ).state;

      action = engine.rollDice(state, forcedValue: 6);
      final int activeTokenId = action.state.currentPlayer.tokens
          .firstWhere((token) => token.status == TokenStatus.active)
          .id;
      state = engine.moveToken(action.state, activeTokenId).state;

      action = engine.rollDice(state, forcedValue: 6);

      expect(action.state.currentPlayerIndex, 1);
      expect(action.state.phase, GamePhase.waitingForRoll);
      expect(action.state.consecutiveSixes, 0);
    });

    test('landing on an unsafe opponent token captures it', () {
      final LudoGameState state = _stateWithTokens(
        redProgress: 2,
        greenProgresses: const [44],
      );

      final rolled = engine.rollDice(state, forcedValue: 3);
      final moved = engine.moveToken(
        rolled.state,
        rolled.state.movableTokenIds.single,
      );

      final LudoToken greenToken =
          moved.state.players[1].tokens.first;

      expect(greenToken.status, TokenStatus.base);
      expect(greenToken.pathPosition, -1);
      expect(moved.state.currentPlayerIndex, 0);
    });

    test('safe cells do not capture opponents', () {
      final LudoGameState state = _stateWithTokens(
        redProgress: 5,
        greenProgresses: const [47],
      );

      final rolled = engine.rollDice(state, forcedValue: 3);
      final moved = engine.moveToken(
        rolled.state,
        rolled.state.movableTokenIds.single,
      );

      final LudoToken greenToken =
          moved.state.players[1].tokens.first;

      expect(
        LudoBoardMap.globalIndexFor(
          color: PlayerColor.red,
          pathPosition: 8,
        ),
        8,
      );
      expect(greenToken.status, TokenStatus.active);
      expect(greenToken.pathPosition, 47);
    });

    test('opponent blockade prevents landing or passing', () {
      final LudoGameState state = _stateWithTokens(
        redProgress: 2,
        greenProgresses: const [44, 44],
      );

      expect(
        engine.getMovableTokenIds(state, 3),
        isEmpty,
      );
    });

    test('exact roll is required to finish', () {
      final LudoGameState state = _stateWithTokens(
        redProgress: 55,
        redStatus: TokenStatus.homePath,
      );

      expect(engine.getMovableTokenIds(state, 3), isEmpty);
      expect(engine.getMovableTokenIds(state, 2), hasLength(1));

      final rolled = engine.rollDice(state, forcedValue: 2);
      final moved = engine.moveToken(
        rolled.state,
        rolled.state.movableTokenIds.single,
      );

      expect(
        moved.state.players.first.tokens.first.status,
        TokenStatus.finished,
      );
      expect(
        moved.state.players.first.tokens.first.pathPosition,
        ClassicRules.finishProgress,
      );
    });
  });
}

LudoGameState _newTwoPlayerGame(LudoGameEngine engine) {
  return engine.createGame(
    config: const LudoGameConfig(
      mode: LudoGameMode.normal,
      matchType: LudoMatchType.localPassAndPlay,
      playerCount: 2,
    ),
    playerNames: const ['Red', 'Green'],
  );
}

LudoGameState _stateWithTokens({
  required int redProgress,
  TokenStatus redStatus = TokenStatus.active,
  List<int> greenProgresses = const <int>[],
}) {
  final LudoToken redToken = LudoToken(
    id: 0,
    color: PlayerColor.red,
    pathPosition: redProgress,
    status: redStatus,
  );

  final List<LudoToken> greenTokens = <LudoToken>[
    for (int index = 0; index < greenProgresses.length; index++)
      LudoToken(
        id: 4 + index,
        color: PlayerColor.green,
        pathPosition: greenProgresses[index],
        status: TokenStatus.active,
      ),
  ];

  return LudoGameState(
    players: <LudoPlayer>[
      LudoPlayer(
        id: 'player_0',
        name: 'Red',
        color: PlayerColor.red,
        tokens: <LudoToken>[redToken],
      ),
      LudoPlayer(
        id: 'player_1',
        name: 'Green',
        color: PlayerColor.green,
        tokens: greenTokens,
      ),
    ],
    currentPlayerIndex: 0,
    phase: GamePhase.waitingForRoll,
    mode: LudoGameMode.normal,
  );
}
