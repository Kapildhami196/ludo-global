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
    final Set<int> homeEntryRolls = <int>{};
    final Set<int> finishRolls = <int>{};
    final Set<int> blockadeRolls = <int>{};

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

        if (_entersHomeLane(token, face)) {
          homeEntryRolls.add(face);
        }

        if (_finishesToken(token, face)) {
          finishRolls.add(face);
        }

        if (_createsBlockade(
          state: state,
          token: token,
          diceValue: face,
        )) {
          blockadeRolls.add(face);
        }
      }
    }

    final double playerProgress = _normalizedProgress(player);
    final List<double> opponentProgress = state.players
        .where((LudoPlayer opponent) => opponent.id != player.id)
        .map(_normalizedProgress)
        .toList(growable: false);
    final double averageOpponentProgress = opponentProgress.isEmpty
        ? playerProgress
        : opponentProgress.reduce((a, b) => a + b) /
            opponentProgress.length;

    return DiceContext(
      rollsSinceSix: history.rollsSinceSix,
      allTokensInBase: allTokensInBase,
      hasTokenInBase: hasTokenInBase,
      captureRolls: Set<int>.unmodifiable(captureRolls),
      escapeRolls: Set<int>.unmodifiable(escapeRolls),
      homeEntryRolls: Set<int>.unmodifiable(homeEntryRolls),
      finishRolls: Set<int>.unmodifiable(finishRolls),
      blockadeRolls: Set<int>.unmodifiable(blockadeRolls),
      turnsWithoutMajorEvent: turnsWithoutMajorEvent,
      relativeProgressDelta:
          playerProgress - averageOpponentProgress,
      currentPlayerNearWin: _isNearWin(player),
      opponentNearWin: state.players
          .where((LudoPlayer opponent) => opponent.id != player.id)
          .any(_isNearWin),
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
    if (targetPosition >= ClassicRules.sharedPathProgressLength) {
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

    if (targetPosition >= ClassicRules.sharedPathProgressLength) {
      return targetPosition <= ClassicRules.finishProgress;
    }

    final int targetGlobalIndex = LudoBoardMap.globalIndexFor(
      color: token.color,
      pathPosition: targetPosition,
    );

    return LudoBoardMap.isSafeGlobalIndex(targetGlobalIndex);
  }

  bool _entersHomeLane(
    LudoToken token,
    int diceValue,
  ) {
    if (token.status != TokenStatus.active) {
      return false;
    }

    final int targetPosition = token.pathPosition + diceValue;
    return targetPosition >= ClassicRules.sharedPathProgressLength &&
        targetPosition < ClassicRules.finishProgress;
  }

  bool _finishesToken(
    LudoToken token,
    int diceValue,
  ) {
    if (token.isInBase || token.isFinished) {
      return false;
    }

    return token.pathPosition + diceValue ==
        ClassicRules.finishProgress;
  }

  bool _createsBlockade({
    required LudoGameState state,
    required LudoToken token,
    required int diceValue,
  }) {
    if (token.status != TokenStatus.active) {
      return false;
    }

    final int targetPosition = token.pathPosition + diceValue;
    if (targetPosition >= ClassicRules.sharedPathProgressLength) {
      return false;
    }

    final int targetGlobalIndex = LudoBoardMap.globalIndexFor(
      color: token.color,
      pathPosition: targetPosition,
    );

    if (LudoBoardMap.isSafeGlobalIndex(targetGlobalIndex)) {
      return false;
    }

    return state.currentPlayer.tokens.any(
      (LudoToken friendly) =>
          friendly.id != token.id &&
          friendly.status == TokenStatus.active &&
          LudoBoardMap.globalIndexFor(
                color: friendly.color,
                pathPosition: friendly.pathPosition,
              ) ==
              targetGlobalIndex,
    );
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
            ClassicRules.sharedPathProgressLength) {
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

  double _normalizedProgress(LudoPlayer player) {
    if (player.tokens.isEmpty) {
      return 0;
    }

    final double progress = player.tokens.fold<double>(
      0,
      (double total, LudoToken token) {
        if (token.isInBase) {
          return total;
        }

        final int boundedProgress = min(
          token.pathPosition + 1,
          ClassicRules.finishProgress + 1,
        );
        return total + boundedProgress;
      },
    );

    final double maximum =
        player.tokens.length * (ClassicRules.finishProgress + 1);
    return progress / maximum;
  }

  bool _isNearWin(LudoPlayer player) {
    if (player.tokens.length < 2) {
      return false;
    }

    final int finished = player.tokens
        .where((LudoToken token) => token.isFinished)
        .length;
    return finished >= player.tokens.length - 1;
  }

  bool _crossesOpponentBlockade({
    required LudoGameState state,
    required PlayerColor movingColor,
    required int fromPosition,
    required int toPosition,
  }) {
    final int lastSharedPosition = min(
      toPosition,
      ClassicRules.sharedPathProgressLength - 1,
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
