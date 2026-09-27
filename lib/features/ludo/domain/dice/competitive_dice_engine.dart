import 'dart:math';

import '../entities/ludo_game_event.dart';
import '../entities/ludo_game_state.dart';
import 'dice_context.dart';
import 'dice_policy.dart';
import 'dice_weights.dart';
import 'match_situation_analyzer.dart';
import 'player_dice_history.dart';
import 'weighted_dice_roller.dart';

class CompetitiveDiceEngine implements DicePolicy {
  CompetitiveDiceEngine({
    Random? random,
    WeightedDiceRoller? roller,
    MatchSituationAnalyzer? analyzer,
  })  : _roller = roller ?? WeightedDiceRoller(random: random),
        _analyzer = analyzer ?? const MatchSituationAnalyzer();

  static const double _baseWeight = 100;
  static const double _sixDroughtStartBoost = 15;
  static const double _sixDroughtMediumBoost = 20;
  static const double _sixDroughtLongBoost = 25;
  static const double _allTokensInBaseBoost = 25;
  static const double _captureBoost = 35;
  static const double _escapeBoost = 15;
  static const double _homeEntryBoost = 12;
  static const double _finishBoost = 20;
  static const double _blockadeBoost = 12;
  static const double _staleActionBoost = 15;
  static const double _behindActionBoost = 10;
  static const double _endgameDefenseBoost = 20;
  static const double _endgameFinishBoost = 20;

  static const double maxSingleFaceProbability = 0.40;
  static const double _cooldownBoostMultiplier = 0.35;
  static const int strongAssistCooldownRolls = 2;

  final WeightedDiceRoller _roller;
  final MatchSituationAnalyzer _analyzer;
  final Map<String, PlayerDiceHistory> _historyByPlayer =
      <String, PlayerDiceHistory>{};

  int _turnsWithoutMajorEvent = 0;

  int get turnsWithoutMajorEvent => _turnsWithoutMajorEvent;

  @override
  int roll({
    required LudoGameState state,
  }) {
    final String playerId = state.currentPlayer.id;
    final PlayerDiceHistory history = historyFor(playerId);
    final DiceContext context = contextFor(
      state: state,
      history: history,
    );
    final DiceWeights weights = _weightsForContext(
      context: context,
      history: history,
    );

    final int value = _roller.roll(weights);

    final int nextCooldown;
    if (history.strongAssistCooldown > 0) {
      nextCooldown = history.strongAssistCooldown - 1;
    } else if (_isStrongAssistRoll(value, context)) {
      nextCooldown = strongAssistCooldownRolls;
    } else {
      nextCooldown = 0;
    }

    _historyByPlayer[playerId] = history.recordRoll(
      value,
      strongAssistCooldown: nextCooldown,
    );
    return value;
  }

  PlayerDiceHistory historyFor(String playerId) {
    return _historyByPlayer[playerId] ??
        const PlayerDiceHistory();
  }

  DiceContext contextFor({
    required LudoGameState state,
    PlayerDiceHistory? history,
  }) {
    return _analyzer.analyze(
      state: state,
      history: history ?? historyFor(state.currentPlayer.id),
      turnsWithoutMajorEvent: _turnsWithoutMajorEvent,
    );
  }

  DiceWeights weightsFor({
    required LudoGameState state,
    required PlayerDiceHistory history,
  }) {
    return _weightsForContext(
      context: contextFor(
        state: state,
        history: history,
      ),
      history: history,
    );
  }

  DiceWeights _weightsForContext({
    required DiceContext context,
    required PlayerDiceHistory history,
  }) {
    DiceWeights weights = DiceWeights.fair(
      baseWeight: _baseWeight,
    );
    final double scale = history.strongAssistCooldown > 0
        ? _cooldownBoostMultiplier
        : 1;

    if (context.rollsSinceSix >= 3) {
      weights = _boost(
        weights,
        6,
        _sixDroughtStartBoost,
        scale,
      );
    }
    if (context.rollsSinceSix >= 5) {
      weights = _boost(
        weights,
        6,
        _sixDroughtMediumBoost,
        scale,
      );
    }
    if (context.rollsSinceSix >= 7) {
      weights = _boost(
        weights,
        6,
        _sixDroughtLongBoost,
        scale,
      );
    }

    if (context.allTokensInBase) {
      weights = _boost(
        weights,
        6,
        _allTokensInBaseBoost,
        scale,
      );
    }

    for (final int face in context.captureRolls) {
      weights = _boost(weights, face, _captureBoost, scale);
    }

    for (final int face in context.escapeRolls) {
      weights = _boost(weights, face, _escapeBoost, scale);
    }

    for (final int face in context.homeEntryRolls) {
      weights = _boost(weights, face, _homeEntryBoost, scale);
    }

    for (final int face in context.finishRolls) {
      weights = _boost(weights, face, _finishBoost, scale);
    }

    for (final int face in context.blockadeRolls) {
      weights = _boost(weights, face, _blockadeBoost, scale);
    }

    if (context.isStaleMatch) {
      for (final int face in context.actionRolls) {
        weights = _boost(
          weights,
          face,
          _staleActionBoost,
          scale,
        );
      }
    }

    if (context.isSignificantlyBehind) {
      for (final int face in context.actionRolls) {
        weights = _boost(
          weights,
          face,
          _behindActionBoost,
          scale,
        );
      }
    }

    if (context.opponentNearWin) {
      for (final int face in context.defensiveEndgameRolls) {
        weights = _boost(
          weights,
          face,
          _endgameDefenseBoost,
          scale,
        );
      }
    }

    if (context.currentPlayerNearWin) {
      for (final int face in context.finishRolls) {
        weights = _boost(
          weights,
          face,
          _endgameFinishBoost,
          scale,
        );
      }
    }

    return weights.cappedAtProbability(
      maxSingleFaceProbability,
    );
  }

  DiceWeights _boost(
    DiceWeights weights,
    int face,
    double amount,
    double scale,
  ) {
    return weights.withAddedWeight(
      face,
      amount * scale,
    );
  }

  bool _isStrongAssistRoll(
    int value,
    DiceContext context,
  ) {
    if (context.captureRolls.contains(value) ||
        context.finishRolls.contains(value)) {
      return true;
    }

    if (value == 6 &&
        (context.allTokensInBase ||
            context.rollsSinceSix >= 5)) {
      return true;
    }

    if (context.opponentNearWin &&
        context.defensiveEndgameRolls.contains(value)) {
      return true;
    }

    return false;
  }

  void recordGameEvents(List<LudoGameEvent> events) {
    final bool resolvedAction = events.any(
      (LudoGameEvent event) =>
          event.type == LudoGameEventType.tokenMoved ||
          event.type == LudoGameEventType.tokenReleased ||
          event.type == LudoGameEventType.noLegalMove ||
          event.type == LudoGameEventType.threeSixesForfeit,
    );

    if (!resolvedAction) {
      return;
    }

    final bool majorEvent = events.any(
      (LudoGameEvent event) =>
          event.type == LudoGameEventType.tokenReleased ||
          event.type == LudoGameEventType.tokenCaptured ||
          event.type == LudoGameEventType.tokenFinished ||
          event.type == LudoGameEventType.playerWon,
    );

    _turnsWithoutMajorEvent =
        majorEvent ? 0 : _turnsWithoutMajorEvent + 1;
  }

  void resetPlayer(String playerId) {
    _historyByPlayer.remove(playerId);
  }

  void reset() {
    _historyByPlayer.clear();
    _turnsWithoutMajorEvent = 0;
  }
}
