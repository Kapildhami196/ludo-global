import 'dice_context.dart';
import 'dice_weights.dart';
import 'player_dice_history.dart';

class DiceDecisionSnapshot {
  const DiceDecisionSnapshot({
    required this.context,
    required this.history,
    required this.weights,
  });

  final DiceContext context;
  final PlayerDiceHistory history;
  final DiceWeights weights;

  bool get cooldownActive => history.strongAssistCooldown > 0;

  Map<int, double> get probabilities => <int, double>{
        for (int face = 1; face <= 6; face++)
          face: weights.probabilityFor(face),
      };
}
