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
    this.consecutiveSixes = 0,
    this.winnerPlayerId,
  });

  final List<LudoPlayer> players;
  final int currentPlayerIndex;
  final int? diceValue;
  final List<int> movableTokenIds;
  final GamePhase phase;
  final LudoGameMode mode;
  final int consecutiveSixes;
  final String? winnerPlayerId;

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  bool get isGameOver => phase == GamePhase.gameOver;

  LudoGameState copyWith({
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    int? diceValue,
    bool clearDiceValue = false,
    List<int>? movableTokenIds,
    GamePhase? phase,
    int? consecutiveSixes,
    String? winnerPlayerId,
    bool clearWinnerPlayerId = false,
  }) {
    return LudoGameState(
      players: players ?? this.players,
      currentPlayerIndex:
          currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: clearDiceValue ? null : diceValue ?? this.diceValue,
      movableTokenIds: movableTokenIds ?? this.movableTokenIds,
      phase: phase ?? this.phase,
      mode: mode,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      winnerPlayerId:
          clearWinnerPlayerId ? null : winnerPlayerId ?? this.winnerPlayerId,
    );
  }
}
