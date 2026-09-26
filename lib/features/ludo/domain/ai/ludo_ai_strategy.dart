import 'dart:math';

import '../engine/ludo_board_map.dart';
import '../engine/ludo_game_engine.dart';
import '../entities/ludo_game_event.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/token_status.dart';
import '../rules/classic_rules.dart';
import 'ai_difficulty.dart';
import 'ai_move_decision.dart';

class LudoAiStrategy {
  LudoAiStrategy({Random? random}) : _random = random ?? Random();

  final Random _random;

  AiMoveDecision chooseMove({
    required LudoGameState state,
    required LudoGameEngine engine,
    required AiDifficulty difficulty,
    int? movementDistance,
    Set<int> protectedTokenIds = const <int>{},
  }) {
    if (state.movableTokenIds.isEmpty) {
      throw StateError('AI cannot choose a move without legal tokens.');
    }

    if (difficulty == AiDifficulty.easy) {
      final int tokenId = state.movableTokenIds[
          _random.nextInt(state.movableTokenIds.length)];
      return AiMoveDecision(
        tokenId: tokenId,
        score: 0,
        reason: 'Random legal move',
      );
    }

    final List<AiMoveDecision> decisions = state.movableTokenIds
        .map(
          (int tokenId) => evaluateMove(
            state: state,
            engine: engine,
            tokenId: tokenId,
            difficulty: difficulty,
            movementDistance: movementDistance,
            protectedTokenIds: protectedTokenIds,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));

    final double bestScore = decisions.first.score;
    final List<AiMoveDecision> best = decisions
        .where(
          (decision) => (decision.score - bestScore).abs() < 0.001,
        )
        .toList(growable: false);

    return best[_random.nextInt(best.length)];
  }

  AiMoveDecision evaluateMove({
    required LudoGameState state,
    required LudoGameEngine engine,
    required int tokenId,
    required AiDifficulty difficulty,
    int? movementDistance,
    Set<int> protectedTokenIds = const <int>{},
  }) {
    final LudoToken before = state.currentPlayer.tokens.firstWhere(
      (token) => token.id == tokenId,
    );

    final result = engine.moveToken(
      state,
      tokenId,
      movementDistance: movementDistance,
      protectedTokenIds: protectedTokenIds,
    );

    final LudoToken after = result.state.players
        .expand((player) => player.tokens)
        .firstWhere((token) => token.id == tokenId);

    double score = 0;
    final List<String> reasons = <String>[];

    final bool won = result.events.any(
      (event) => event.type == LudoGameEventType.playerWon,
    );
    final bool finished = result.events.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    );
    final bool captured = result.events.any(
      (event) => event.type == LudoGameEventType.tokenCaptured,
    );

    if (won) {
      score += 10000;
      reasons.add('wins match');
    }

    if (finished) {
      score += 1500;
      reasons.add('finishes token');
    }

    if (captured) {
      final LudoGameEvent event = result.events.firstWhere(
        (event) => event.type == LudoGameEventType.tokenCaptured,
      );
      score += 850 + (event.otherTokenIds.length * 120);
      reasons.add('captures opponent');
    }

    if (before.isInBase && after.status == TokenStatus.active) {
      score += 230;
      reasons.add('releases token');
    }

    if (before.status == TokenStatus.active &&
        after.status == TokenStatus.homePath) {
      score += 420;
      reasons.add('enters home lane');
    }

    if (after.status == TokenStatus.homePath) {
      score += 180;
    }

    if (after.status == TokenStatus.active) {
      final int globalIndex = LudoBoardMap.globalIndexFor(
        color: after.color,
        pathPosition: after.pathPosition,
      );

      if (LudoBoardMap.isSafeGlobalIndex(globalIndex)) {
        score += 170;
        reasons.add('lands safe');
      } else if (difficulty == AiDifficulty.hard) {
        final int threats = _countImmediateThreats(
          result.state,
          tokenId,
        );
        if (threats > 0) {
          score -= threats * 185;
          reasons.add('avoids capture risk');
        }

        final int friendlyStack = result.state.currentPlayer.tokens
            .where(
              (token) =>
                  token.id != tokenId &&
                  token.status == TokenStatus.active &&
                  LudoBoardMap.globalIndexFor(
                        color: token.color,
                        pathPosition: token.pathPosition,
                      ) ==
                      globalIndex,
            )
            .length;

        if (friendlyStack > 0) {
          score += 125;
          reasons.add('builds stack');
        }
      }
    }

    final int progressGain = after.pathPosition - before.pathPosition;
    if (progressGain > 0) {
      score += progressGain * (difficulty == AiDifficulty.hard ? 6 : 4);
    }

    if (difficulty == AiDifficulty.hard) {
      score += _homePressureScore(after);
    }

    return AiMoveDecision(
      tokenId: tokenId,
      score: score,
      reason: reasons.isEmpty ? 'advances token' : reasons.join(', '),
    );
  }

  int _countImmediateThreats(
    LudoGameState state,
    int tokenId,
  ) {
    final LudoToken target = state.players
        .expand((player) => player.tokens)
        .firstWhere((token) => token.id == tokenId);

    if (target.status != TokenStatus.active) {
      return 0;
    }

    final int targetGlobal = LudoBoardMap.globalIndexFor(
      color: target.color,
      pathPosition: target.pathPosition,
    );

    if (LudoBoardMap.isSafeGlobalIndex(targetGlobal)) {
      return 0;
    }

    int threats = 0;

    for (final LudoPlayer opponent in state.players) {
      if (opponent.color == target.color) {
        continue;
      }

      for (final LudoToken token in opponent.tokens) {
        if (token.status != TokenStatus.active) {
          continue;
        }

        final int opponentGlobal = LudoBoardMap.globalIndexFor(
          color: opponent.color,
          pathPosition: token.pathPosition,
        );
        final int distance = (targetGlobal - opponentGlobal) %
            ClassicRules.commonPathLength;

        if (distance >= 1 && distance <= 6) {
          threats++;
        }
      }
    }

    return threats;
  }

  double _homePressureScore(LudoToken token) {
    if (token.isFinished) {
      return 0;
    }

    if (token.status == TokenStatus.homePath) {
      final int remaining =
          ClassicRules.finishProgress - token.pathPosition;
      return (ClassicRules.homeLaneLength + 1 - remaining) * 32;
    }

    if (token.status == TokenStatus.active &&
        token.pathPosition >= 40) {
      return (token.pathPosition - 39) * 10;
    }

    return 0;
  }
}
