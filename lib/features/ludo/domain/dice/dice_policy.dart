import '../entities/ludo_game_state.dart';

abstract interface class DicePolicy {
  int roll({
    required LudoGameState state,
  });
}
