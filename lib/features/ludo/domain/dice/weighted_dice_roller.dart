import 'dart:math';

import 'dice_weights.dart';

class WeightedDiceRoller {
  WeightedDiceRoller({Random? random}) : _random = random ?? Random();

  final Random _random;

  int roll(DiceWeights weights) {
    final double total = weights.totalWeight;
    if (total <= 0) {
      throw StateError(
        'At least one dice face must have a positive weight.',
      );
    }

    final double target = _random.nextDouble() * total;
    double cumulative = 0;

    for (int face = 1; face <= 6; face++) {
      cumulative += weights.weightFor(face);
      if (target < cumulative) {
        return face;
      }
    }

    return 6;
  }
}
