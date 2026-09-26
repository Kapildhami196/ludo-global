import 'dart:math';

import '../engine/ludo_board_map.dart';
import '../engine/ludo_game_engine.dart';
import '../entities/game_phase.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_player.dart';
import '../entities/ludo_token.dart';
import '../entities/token_status.dart';
import '../power/power_ludo_engine.dart';
import '../power/power_ludo_state.dart';
import '../rules/classic_rules.dart';
import 'ai_difficulty.dart';
import 'ludo_ai_strategy.dart';
import 'power_ai_decision.dart';

class PowerLudoAiStrategy {
  PowerLudoAiStrategy({
    Random? random,
    LudoAiStrategy? classicStrategy,
    LudoGameEngine? classicEngine,
  })  : _random = random ?? Random(),
        _classicStrategy = classicStrategy ?? LudoAiStrategy(),
        _classicEngine = classicEngine ?? LudoGameEngine();

  final Random _random;
  final LudoAiStrategy _classicStrategy;
  final LudoGameEngine _classicEngine;

  PowerAiPreRollDecision choosePreRollAction({
    required PowerLudoState state,
    required PowerLudoEngine engine,
    required AiDifficulty difficulty,
  }) {
    if (state.gameState.phase != GamePhase.waitingForRoll) {
      return const PowerAiPreRollDecision(
        type: PowerAiPreRollActionType.normalRoll,
      );
    }

    if (difficulty == AiDifficulty.easy) {
      return _easyPreRollAction(state, engine);
    }

    final PowerAiPreRollDecision? diceControl =
        _bestDiceControlDecision(state, engine, difficulty);

    final PowerAiPreRollDecision? shield =
        _bestShieldDecision(state, engine);

    if (difficulty == AiDifficulty.hard) {
      if (diceControl != null && diceControl.score >= 230) {
        return diceControl;
      }
      if (shield != null) {
        return shield;
      }
      if (_shouldQueueBonus(state, engine, difficulty)) {
        return const PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.bonusRoll,
          score: 120,
          reason: 'extends a productive turn',
        );
      }
      if (diceControl != null && diceControl.score > 60) {
        return diceControl;
      }
    } else {
      if (diceControl != null && diceControl.score >= 650) {
        return diceControl;
      }
      if (shield != null && shield.score >= 300) {
        return shield;
      }
      if (_shouldQueueBonus(state, engine, difficulty)) {
        return const PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.bonusRoll,
          score: 80,
          reason: 'adds another chance to move',
        );
      }
    }

    return const PowerAiPreRollDecision(
      type: PowerAiPreRollActionType.normalRoll,
      reason: 'keeps powers for a stronger opportunity',
    );
  }

  PowerAiDoubleDecision shouldUseDoubleDistance({
    required PowerLudoState state,
    required PowerLudoEngine engine,
    required AiDifficulty difficulty,
  }) {
    if (!engine.canUseDoubleDistance(state)) {
      return const PowerAiDoubleDecision(shouldUse: false);
    }

    if (difficulty == AiDifficulty.easy) {
      final bool use = _random.nextInt(100) < 22;
      return PowerAiDoubleDecision(
        shouldUse: use,
        reason: use ? 'tries a random power' : 'saves the power',
      );
    }

    final int diceValue = state.gameState.diceValue!;
    final Set<int> protectedIds = state.shields.keys.toSet();

    final double normalScore = _classicStrategy
        .chooseMove(
          state: state.gameState,
          engine: _classicEngine,
          difficulty: difficulty,
          protectedTokenIds: protectedIds,
        )
        .score;

    final armed = engine.armDoubleDistance(state);
    final int doubledDistance = diceValue * 2;

    final double doubledScore = _classicStrategy
        .chooseMove(
          state: armed.state.gameState,
          engine: _classicEngine,
          difficulty: difficulty,
          movementDistance: doubledDistance,
          protectedTokenIds: protectedIds,
        )
        .score;

    final double gain = doubledScore - normalScore;
    final double threshold =
        difficulty == AiDifficulty.hard ? 70 : 190;

    return PowerAiDoubleDecision(
      shouldUse: gain >= threshold || doubledScore >= 1200,
      scoreGain: gain,
      reason: doubledScore >= 1200
          ? 'creates a major tactical move'
          : 'improves move score by ${gain.round()}',
    );
  }

  int chooseShieldToken(PowerLudoState state) {
    final List<LudoToken> eligible = state.gameState.currentPlayer.tokens
        .where(
          (token) =>
              token.status == TokenStatus.active &&
              !state.isShielded(token.id),
        )
        .toList(growable: false);

    if (eligible.isEmpty) {
      throw StateError('No token is eligible for Shield.');
    }

    eligible.sort(
      (a, b) => _shieldPriority(state.gameState, b)
          .compareTo(_shieldPriority(state.gameState, a)),
    );

    return eligible.first.id;
  }

  int chooseMove({
    required PowerLudoState state,
    required AiDifficulty difficulty,
  }) {
    final int? movementDistance = state.doubleDistanceArmed
        ? state.gameState.diceValue! * 2
        : null;

    return _classicStrategy
        .chooseMove(
          state: state.gameState,
          engine: _classicEngine,
          difficulty: difficulty,
          movementDistance: movementDistance,
          protectedTokenIds: state.shields.keys.toSet(),
        )
        .tokenId;
  }

  PowerAiPreRollDecision _easyPreRollAction(
    PowerLudoState state,
    PowerLudoEngine engine,
  ) {
    if (_random.nextInt(100) >= 22) {
      return const PowerAiPreRollDecision(
        type: PowerAiPreRollActionType.normalRoll,
        reason: 'easy AI usually rolls normally',
      );
    }

    final List<PowerAiPreRollDecision> available =
        <PowerAiPreRollDecision>[];

    if (engine.canUseShield(state)) {
      available.add(
        PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.shield,
          tokenId: chooseShieldToken(state),
          reason: 'random Shield use',
        ),
      );
    }

    if (engine.canUseDiceControl(state)) {
      available.add(
        PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.diceControl,
          diceValue: _random.nextInt(6) + 1,
          reason: 'random controlled die',
        ),
      );
    }

    if (engine.canUseBonusRoll(state)) {
      available.add(
        const PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.bonusRoll,
          reason: 'random Bonus Roll use',
        ),
      );
    }

    if (available.isEmpty) {
      return const PowerAiPreRollDecision(
        type: PowerAiPreRollActionType.normalRoll,
      );
    }

    return available[_random.nextInt(available.length)];
  }

  PowerAiPreRollDecision? _bestDiceControlDecision(
    PowerLudoState state,
    PowerLudoEngine engine,
    AiDifficulty difficulty,
  ) {
    if (!engine.canUseDiceControl(state)) {
      return null;
    }

    PowerAiPreRollDecision? best;

    for (int value = 1; value <= 6; value++) {
      final result = engine.useDiceControl(state, value);
      double score = 0;

      if (result.state.gameState.currentPlayer.id ==
              state.gameState.currentPlayer.id &&
          result.state.gameState.phase == GamePhase.selectingToken) {
        score = _classicStrategy
            .chooseMove(
              state: result.state.gameState,
              engine: _classicEngine,
              difficulty: difficulty,
              protectedTokenIds: result.state.shields.keys.toSet(),
            )
            .score;
      } else if (value == 6 &&
          result.state.gameState.currentPlayer.id ==
              state.gameState.currentPlayer.id) {
        score = 45;
      }

      final bool hasBaseToken = state.gameState.currentPlayer.tokens.any(
        (token) => token.isInBase,
      );
      if (value == 6 && hasBaseToken) {
        score += 85;
      }

      if (best == null || score > best.score) {
        best = PowerAiPreRollDecision(
          type: PowerAiPreRollActionType.diceControl,
          diceValue: value,
          score: score,
          reason: 'chooses die $value for tactical value',
        );
      }
    }

    return best;
  }

  PowerAiPreRollDecision? _bestShieldDecision(
    PowerLudoState state,
    PowerLudoEngine engine,
  ) {
    if (!engine.canUseShield(state)) {
      return null;
    }

    final int tokenId = chooseShieldToken(state);
    final LudoToken token = state.gameState.currentPlayer.tokens.firstWhere(
      (candidate) => candidate.id == tokenId,
    );

    final int threats = _countThreats(state.gameState, token);
    if (threats == 0) {
      return null;
    }

    return PowerAiPreRollDecision(
      type: PowerAiPreRollActionType.shield,
      tokenId: tokenId,
      score: 250 + (threats * 100) + token.pathPosition.toDouble(),
      reason: 'protects a threatened advanced token',
    );
  }

  bool _shouldQueueBonus(
    PowerLudoState state,
    PowerLudoEngine engine,
    AiDifficulty difficulty,
  ) {
    if (!engine.canUseBonusRoll(state)) {
      return false;
    }

    final bool hasActiveToken = state.gameState.currentPlayer.tokens.any(
      (token) =>
          token.status == TokenStatus.active ||
          token.status == TokenStatus.homePath,
    );

    if (!hasActiveToken) {
      return false;
    }

    if (difficulty == AiDifficulty.hard) {
      return state.turnSerial >= 1;
    }

    return _random.nextInt(100) < 28;
  }

  double _shieldPriority(
    LudoGameState state,
    LudoToken token,
  ) {
    final int threats = _countThreats(state, token);
    final double progress = token.pathPosition.toDouble();
    final bool safe = LudoBoardMap.isSafeGlobalIndex(
      LudoBoardMap.globalIndexFor(
        color: token.color,
        pathPosition: token.pathPosition,
      ),
    );

    return (threats * 350) + progress - (safe ? 500 : 0);
  }

  int _countThreats(
    LudoGameState state,
    LudoToken target,
  ) {
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
        final int distance =
            (targetGlobal - opponentGlobal) %
                ClassicRules.commonPathLength;

        if (distance >= 1 && distance <= 6) {
          threats++;
        }
      }
    }

    return threats;
  }
}
