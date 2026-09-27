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
  static const double _staleActionBoost = 15;

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
    final DiceWeights weights = weightsFor(
      state: state,
      history: history,
    );

    final int value = _roller.roll(weights);
    _historyByPlayer[playerId] = history.recordRoll(value);
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
    final DiceContext context = contextFor(
      state: state,
      history: history,
    );

    DiceWeights weights = DiceWeights.fair(
      baseWeight: _baseWeight,
    );

    if (context.rollsSinceSix >= 3) {
      weights = weights.withAddedWeight(
        6,
        _sixDroughtStartBoost,
      );
    }
    if (context.rollsSinceSix >= 5) {
      weights = weights.withAddedWeight(
        6,
        _sixDroughtMediumBoost,
      );
    }
    if (context.rollsSinceSix >= 7) {
      weights = weights.withAddedWeight(
        6,
        _sixDroughtLongBoost,
      );
    }

    if (context.allTokensInBase) {
      weights = weights.withAddedWeight(
        6,
        _allTokensInBaseBoost,
      );
    }

    for (final int face in context.captureRolls) {
      weights = weights.withAddedWeight(
        face,
        _captureBoost,
      );
    }

    for (final int face in context.escapeRolls) {
      weights = weights.withAddedWeight(
        face,
        _escapeBoost,
      );
    }

    if (context.isStaleMatch) {
      for (final int face in context.actionRolls) {
        weights = weights.withAddedWeight(
          face,
          _staleActionBoost,
        );
      }
    }

    return weights;
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
