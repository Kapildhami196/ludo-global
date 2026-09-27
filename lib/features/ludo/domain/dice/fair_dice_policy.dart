import 'dart:math';

import '../entities/ludo_game_state.dart';
import 'dice_policy.dart';

class FairDicePolicy implements DicePolicy {
  FairDicePolicy({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  int roll({
    required LudoGameState state,
  }) {
    return _random.nextInt(6) + 1;
  }
}
