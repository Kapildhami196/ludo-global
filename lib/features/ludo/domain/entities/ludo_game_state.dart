import 'game_config.dart';
import 'game_phase.dart';
import 'ludo_player.dart';

class LudoGameState {
  const LudoGameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.mode,
    this.diceValue,
    this.movableTokenIds = const <int>[],
  });

  final List<LudoPlayer> players;
  final int currentPlayerIndex;
  final int? diceValue;
  final List<int> movableTokenIds;
  final GamePhase phase;
  final LudoGameMode mode;
}
