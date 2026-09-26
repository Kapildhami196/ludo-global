import 'dart:math';

import '../entities/game_config.dart';
import '../entities/game_phase.dart';
import '../entities/ludo_game_action_result.dart';
import '../entities/ludo_game_event.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/player_color.dart';
import '../entities/token_status.dart';
import '../rules/classic_rules.dart';
import 'ludo_board_map.dart';

class LudoGameEngine {
  LudoGameEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  LudoGameState createGame({
    required LudoGameConfig config,
    required List<String> playerNames,
  }) {
    if (playerNames.length != config.playerCount) {
      throw ArgumentError(
        'Expected ${config.playerCount} player names, '
        'received ${playerNames.length}.',
      );
    }

    const List<PlayerColor> colors = <PlayerColor>[
      PlayerColor.red,
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
    ];

    final List<LudoPlayer> players = List<LudoPlayer>.generate(
      config.playerCount,
      (int playerIndex) {
        final PlayerColor color = colors[playerIndex];

        return LudoPlayer(
          id: 'player_$playerIndex',
          name: playerNames[playerIndex],
          color: color,
          tokens: List<LudoToken>.generate(
            ClassicRules.tokensPerPlayer,
            (int tokenIndex) => LudoToken(
              id: (playerIndex * ClassicRules.tokensPerPlayer) + tokenIndex,
              color: color,
            ),
            growable: false,
          ),
        );
      },
      growable: false,
    );

    return LudoGameState(
      players: players,
      currentPlayerIndex: 0,
      phase: GamePhase.waitingForRoll,
      mode: config.mode,
    );
  }

  LudoGameActionResult rollDice(
    LudoGameState state, {
    int? forcedValue,
  }) {
    _requirePhase(state, GamePhase.waitingForRoll);

    final int diceValue = forcedValue ?? (_random.nextInt(6) + 1);
    if (diceValue < 1 || diceValue > 6) {
      throw ArgumentError.value(
        diceValue,
        'forcedValue',
        'Dice value must be from 1 through 6.',
      );
    }

    final int consecutiveSixes = diceValue == 6
        ? state.consecutiveSixes + 1
        : 0;

    final List<LudoGameEvent> events = <LudoGameEvent>[
      LudoGameEvent(
        type: LudoGameEventType.diceRolled,
        playerId: state.currentPlayer.id,
        value: diceValue,
      ),
    ];

    if (diceValue == 6 &&
        consecutiveSixes >= ClassicRules.consecutiveSixLimit) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.threeSixesForfeit,
          playerId: state.currentPlayer.id,
          value: diceValue,
        ),
      );

      return LudoGameActionResult(
        state: _advanceTurn(
          state.copyWith(
            diceValue: diceValue,
            movableTokenIds: const <int>[],
            consecutiveSixes: consecutiveSixes,
          ),
        ),
        events: <LudoGameEvent>[
          ...events,
          LudoGameEvent(
            type: LudoGameEventType.turnChanged,
            playerId: _nextPlayer(state).id,
          ),
        ],
      );
    }

    final List<int> movableTokenIds = getMovableTokenIds(
      state,
      diceValue,
    );

    if (movableTokenIds.isEmpty) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.noLegalMove,
          playerId: state.currentPlayer.id,
          value: diceValue,
        ),
      );

      if (diceValue == 6 && ClassicRules.extraTurnOnSix) {
        events.add(
          LudoGameEvent(
            type: LudoGameEventType.extraTurn,
            playerId: state.currentPlayer.id,
          ),
        );

        return LudoGameActionResult(
          state: state.copyWith(
            clearDiceValue: true,
            movableTokenIds: const <int>[],
            phase: GamePhase.waitingForRoll,
            consecutiveSixes: consecutiveSixes,
          ),
          events: events,
        );
      }

      final LudoGameState next = _advanceTurn(state);
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.turnChanged,
          playerId: next.currentPlayer.id,
        ),
      );

      return LudoGameActionResult(
        state: next,
        events: events,
      );
    }

    return LudoGameActionResult(
      state: state.copyWith(
        diceValue: diceValue,
        movableTokenIds: movableTokenIds,
        phase: GamePhase.selectingToken,
        consecutiveSixes: consecutiveSixes,
      ),
      events: events,
    );
  }

  LudoGameActionResult moveToken(
    LudoGameState state,
    int tokenId, {
    int? movementDistance,
    Set<int> protectedTokenIds = const <int>{},
  }) {
    _requirePhase(state, GamePhase.selectingToken);

    final int diceValue = state.diceValue ??
        (throw StateError('A token cannot move without a dice value.'));

    if (!state.movableTokenIds.contains(tokenId)) {
      throw StateError('Token $tokenId is not a legal move.');
    }

    final int playerIndex = state.currentPlayerIndex;
    final LudoPlayer player = state.players[playerIndex];
    final int tokenIndex =
        player.tokens.indexWhere((LudoToken token) => token.id == tokenId);

    if (tokenIndex < 0) {
      throw StateError('Token $tokenId does not belong to current player.');
    }

    final LudoToken token = player.tokens[tokenIndex];
    final int steps = movementDistance ?? diceValue;
    if (steps < 1) {
      throw ArgumentError.value(
        steps,
        'movementDistance',
        'Movement distance must be positive.',
      );
    }

    if (!canMoveToken(
      state: state,
      token: token,
      diceValue: diceValue,
      movementDistance: steps,
    )) {
      throw StateError(
        'Token $tokenId cannot legally move $steps spaces.',
      );
    }

    final int fromPosition = token.pathPosition;
    final int toPosition = token.isInBase
        ? 0
        : token.pathPosition + steps;

    final TokenStatus targetStatus = _statusForProgress(toPosition);
    final LudoToken movedToken = token.copyWith(
      pathPosition: toPosition,
      status: targetStatus,
    );

    final List<LudoToken> currentTokens =
        List<LudoToken>.of(player.tokens);
    currentTokens[tokenIndex] = movedToken;

    final List<LudoPlayer> players =
        List<LudoPlayer>.of(state.players);
    players[playerIndex] = player.copyWith(tokens: currentTokens);

    final List<int> capturedTokenIds = <int>[];
    if (targetStatus == TokenStatus.active) {
      final int globalIndex = LudoBoardMap.globalIndexFor(
        color: player.color,
        pathPosition: toPosition,
      );

      if (!LudoBoardMap.isSafeGlobalIndex(globalIndex)) {
        for (int otherPlayerIndex = 0;
            otherPlayerIndex < players.length;
            otherPlayerIndex++) {
          if (otherPlayerIndex == playerIndex) {
            continue;
          }

          final LudoPlayer opponent = players[otherPlayerIndex];
          bool changed = false;
          final List<LudoToken> opponentTokens =
              List<LudoToken>.of(opponent.tokens);

          for (int otherTokenIndex = 0;
              otherTokenIndex < opponentTokens.length;
              otherTokenIndex++) {
            final LudoToken opponentToken =
                opponentTokens[otherTokenIndex];

            if (opponentToken.status != TokenStatus.active ||
                protectedTokenIds.contains(opponentToken.id)) {
              continue;
            }

            final int opponentGlobalIndex =
                LudoBoardMap.globalIndexFor(
              color: opponent.color,
              pathPosition: opponentToken.pathPosition,
            );

            if (opponentGlobalIndex == globalIndex) {
              capturedTokenIds.add(opponentToken.id);
              opponentTokens[otherTokenIndex] =
                  opponentToken.copyWith(
                pathPosition: -1,
                status: TokenStatus.base,
              );
              changed = true;
            }
          }

          if (changed) {
            players[otherPlayerIndex] =
                opponent.copyWith(tokens: opponentTokens);
          }
        }
      }
    }

    final List<LudoGameEvent> events = <LudoGameEvent>[
      LudoGameEvent(
        type: fromPosition < 0
            ? LudoGameEventType.tokenReleased
            : LudoGameEventType.tokenMoved,
        playerId: player.id,
        tokenId: tokenId,
        fromPosition: fromPosition,
        toPosition: toPosition,
        value: diceValue,
      ),
    ];

    if (capturedTokenIds.isNotEmpty) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.tokenCaptured,
          playerId: player.id,
          tokenId: tokenId,
          otherTokenIds: capturedTokenIds,
        ),
      );
    }

    if (targetStatus == TokenStatus.finished) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.tokenFinished,
          playerId: player.id,
          tokenId: tokenId,
        ),
      );
    }

    final LudoPlayer updatedCurrentPlayer = players[playerIndex];
    if (updatedCurrentPlayer.hasFinished) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.playerWon,
          playerId: updatedCurrentPlayer.id,
        ),
      );

      return LudoGameActionResult(
        state: state.copyWith(
          players: players,
          phase: GamePhase.gameOver,
          clearDiceValue: true,
          movableTokenIds: const <int>[],
          winnerPlayerId: updatedCurrentPlayer.id,
        ),
        events: events,
      );
    }

    final bool getsExtraTurn =
        (diceValue == 6 && ClassicRules.extraTurnOnSix) ||
            (capturedTokenIds.isNotEmpty &&
                ClassicRules.extraTurnOnCapture);

    if (getsExtraTurn) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.extraTurn,
          playerId: player.id,
        ),
      );

      return LudoGameActionResult(
        state: state.copyWith(
          players: players,
          phase: GamePhase.waitingForRoll,
          clearDiceValue: true,
          movableTokenIds: const <int>[],
          consecutiveSixes:
              diceValue == 6 ? state.consecutiveSixes : 0,
        ),
        events: events,
      );
    }

    final LudoGameState next = _advanceTurn(
      state.copyWith(players: players),
    );

    events.add(
      LudoGameEvent(
        type: LudoGameEventType.turnChanged,
        playerId: next.currentPlayer.id,
      ),
    );

    return LudoGameActionResult(
      state: next,
      events: events,
    );
  }

  List<int> getMovableTokenIds(
    LudoGameState state,
    int diceValue,
  ) {
    if (diceValue < 1 || diceValue > 6) {
      return const <int>[];
    }

    return state.currentPlayer.tokens
        .where(
          (LudoToken token) => canMoveToken(
            state: state,
            token: token,
            diceValue: diceValue,
          ),
        )
        .map((LudoToken token) => token.id)
        .toList(growable: false);
  }

  bool canMoveToken({
    required LudoGameState state,
    required LudoToken token,
    required int diceValue,
    int? movementDistance,
  }) {
    if (token.isFinished || diceValue < 1 || diceValue > 6) {
      return false;
    }

    if (token.isInBase) {
      return diceValue == ClassicRules.rollRequiredToLeaveBase;
    }

    final int steps = movementDistance ?? diceValue;
    if (steps < 1) {
      return false;
    }

    final int targetPosition = token.pathPosition + steps;
    if (targetPosition > ClassicRules.finishProgress) {
      return false;
    }

    return !_crossesOpponentBlockade(
      state: state,
      movingColor: token.color,
      fromPosition: token.pathPosition,
      toPosition: targetPosition,
    );
  }

  TokenStatus _statusForProgress(int progress) {
    if (progress < 0) {
      return TokenStatus.base;
    }
    if (progress < ClassicRules.commonPathLength) {
      return TokenStatus.active;
    }
    if (progress < ClassicRules.finishProgress) {
      return TokenStatus.homePath;
    }
    return TokenStatus.finished;
  }

  bool _crossesOpponentBlockade({
    required LudoGameState state,
    required PlayerColor movingColor,
    required int fromPosition,
    required int toPosition,
  }) {
    final int lastSharedPosition = min(
      toPosition,
      ClassicRules.commonPathLength - 1,
    );

    if (fromPosition >= lastSharedPosition) {
      return false;
    }

    for (int progress = fromPosition + 1;
        progress <= lastSharedPosition;
        progress++) {
      final int globalIndex = LudoBoardMap.globalIndexFor(
        color: movingColor,
        pathPosition: progress,
      );

      if (LudoBoardMap.isSafeGlobalIndex(globalIndex)) {
        continue;
      }

      for (final LudoPlayer opponent in state.players) {
        if (opponent.color == movingColor) {
          continue;
        }

        int count = 0;
        for (final LudoToken token in opponent.tokens) {
          if (token.status != TokenStatus.active) {
            continue;
          }

          final int opponentGlobalIndex =
              LudoBoardMap.globalIndexFor(
            color: opponent.color,
            pathPosition: token.pathPosition,
          );

          if (opponentGlobalIndex == globalIndex) {
            count++;
          }
        }

        if (count >= 2) {
          return true;
        }
      }
    }

    return false;
  }

  LudoGameState _advanceTurn(LudoGameState state) {
    final int nextIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    return state.copyWith(
      currentPlayerIndex: nextIndex,
      phase: GamePhase.waitingForRoll,
      clearDiceValue: true,
      movableTokenIds: const <int>[],
      consecutiveSixes: 0,
    );
  }

  LudoPlayer _nextPlayer(LudoGameState state) {
    return state.players[
        (state.currentPlayerIndex + 1) % state.players.length];
  }

  void _requirePhase(
    LudoGameState state,
    GamePhase expected,
  ) {
    if (state.phase != expected) {
      throw StateError(
        'Expected game phase $expected but was ${state.phase}.',
      );
    }
  }
}
