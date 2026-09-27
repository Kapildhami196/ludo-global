import 'dart:math';

import '../entities/ludo_game_state.dart';
import 'dice_policy.dart';
import 'dice_weights.dart';
import 'player_dice_history.dart';
import 'weighted_dice_roller.dart';

class CompetitiveDiceEngine implements DicePolicy {
  CompetitiveDiceEngine({
    Random? random,
    WeightedDiceRoller? roller,
  }) : _roller = roller ?? WeightedDiceRoller(random: random);

  final WeightedDiceRoller _roller;
  final Map<String, PlayerDiceHistory> _historyByPlayer =
      <String, PlayerDiceHistory>{};

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

  DiceWeights weightsFor({
    required LudoGameState state,
    required PlayerDiceHistory history,
  }) {
    // Phase 1 intentionally keeps all faces equally weighted.
    // Phase 2 will apply board- and history-based situation boosts here.
    return DiceWeights.fair();
  }

  void resetPlayer(String playerId) {
    _historyByPlayer.remove(playerId);
  }

  void reset() {
    _historyByPlayer.clear();
  }
}
