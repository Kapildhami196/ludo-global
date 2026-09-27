import 'dart:math';

import '../engine/ludo_board_map.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/player_color.dart';
import '../entities/token_status.dart';
import '../rules/classic_rules.dart';
import 'dice_context.dart';
import 'player_dice_history.dart';

class MatchSituationAnalyzer {
  const MatchSituationAnalyzer();

  DiceContext analyze({
    required LudoGameState state,
    required PlayerDiceHistory history,
    required int turnsWithoutMajorEvent,
  }) {
    final LudoPlayer player = state.currentPlayer;
    final bool hasTokenInBase =
        player.tokens.any((LudoToken token) => token.isInBase);
    final bool allTokensInBase = player.tokens.isNotEmpty &&
        player.tokens.every((LudoToken token) => token.isInBase);

    final Set<int> captureRolls = <int>{};
    final Set<int> escapeRolls = <int>{};

    for (int face = 1; face <= 6; face++) {
      for (final LudoToken token in player.tokens) {
        if (!_canMove(
          state: state,
          token: token,
          diceValue: face,
        )) {
          continue;
        }

        if (_createsCapture(
          state: state,
          token: token,
          diceValue: face,
        )) {
          captureRolls.add(face);
        }

        if (_escapesToSafety(
          state: state,
          token: token,
          diceValue: face,
        )) {
          escapeRolls.add(face);
        }
      }
    }

    return DiceContext(
      rollsSinceSix: history.rollsSinceSix,
      allTokensInBase: allTokensInBase,
      hasTokenInBase: hasTokenInBase,
      captureRolls: Set<int>.unmodifiable(captureRolls),
      escapeRolls: Set<int>.unmodifiable(escapeRolls),
      turnsWithoutMajorEvent: turnsWithoutMajorEvent,
    );
  }

  bool _canMove({
    required LudoGameState state,
    required LudoToken token,
    required int diceValue,
  }) {
    if (token.isFinished || diceValue < 1 || diceValue > 6) {
      return false;
    }

    if (token.isInBase) {
      return diceValue == ClassicRules.rollRequiredToLeaveBase;
    }

    final int targetPosition = token.pathPosition + diceValue;
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

  bool _createsCapture({
    required LudoGameState state,
    required LudoToken token,
    required int diceValue,
  }) {
    if (token.status != TokenStatus.active) {
      return false;
    }

    final int targetPosition = token.pathPosition + diceValue;
    if (targetPosition >= ClassicRules.commonPathLength) {
      return false;
    }

    final int targetGlobalIndex = LudoBoardMap.globalIndexFor(
      color: token.color,
      pathPosition: targetPosition,
    );

    if (LudoBoardMap.isSafeGlobalIndex(targetGlobalIndex)) {
      return false;
    }

    for (final LudoPlayer opponent in state.players) {
      if (opponent.color == token.color) {
        continue;
      }

      for (final LudoToken opponentToken in opponent.tokens) {
        if (opponentToken.status != TokenStatus.active) {
          continue;
        }

        final int opponentGlobalIndex = LudoBoardMap.globalIndexFor(
          color: opponent.color,
          pathPosition: opponentToken.pathPosition,
        );

        if (opponentGlobalIndex == targetGlobalIndex) {
          return true;
        }
      }
    }

    return false;
  }

  bool _escapesToSafety({
    required LudoGameState state,
    required LudoToken token,
    required int diceValue,
  }) {
    if (token.status != TokenStatus.active ||
        !_isThreatened(state, token)) {
      return false;
    }

    final int targetPosition = token.pathPosition + diceValue;

    if (targetPosition >= ClassicRules.commonPathLength) {
      return targetPosition <= ClassicRules.finishProgress;
    }

    final int targetGlobalIndex = LudoBoardMap.globalIndexFor(
      color: token.color,
      pathPosition: targetPosition,
    );

    return LudoBoardMap.isSafeGlobalIndex(targetGlobalIndex);
  }

  bool _isThreatened(
    LudoGameState state,
    LudoToken target,
  ) {
    final int targetGlobalIndex = LudoBoardMap.globalIndexFor(
      color: target.color,
      pathPosition: target.pathPosition,
    );

    if (LudoBoardMap.isSafeGlobalIndex(targetGlobalIndex)) {
      return false;
    }

    for (final LudoPlayer opponent in state.players) {
      if (opponent.color == target.color) {
        continue;
      }

      for (final LudoToken opponentToken in opponent.tokens) {
        if (opponentToken.status != TokenStatus.active) {
          continue;
        }

        final int opponentGlobalIndex = LudoBoardMap.globalIndexFor(
          color: opponent.color,
          pathPosition: opponentToken.pathPosition,
        );
        final int distance =
            (targetGlobalIndex - opponentGlobalIndex) %
                ClassicRules.commonPathLength;

        if (distance < 1 || distance > 6) {
          continue;
        }

        if (opponentToken.pathPosition + distance >=
            ClassicRules.commonPathLength) {
          continue;
        }

        if (!_crossesOpponentBlockade(
          state: state,
          movingColor: opponent.color,
          fromPosition: opponentToken.pathPosition,
          toPosition: opponentToken.pathPosition + distance,
        )) {
          return true;
        }
      }
    }

    return false;
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

          final int opponentGlobalIndex = LudoBoardMap.globalIndexFor(
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
}
