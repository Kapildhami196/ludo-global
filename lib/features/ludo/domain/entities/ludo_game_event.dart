enum LudoGameEventType {
  diceRolled,
  threeSixesForfeit,
  noLegalMove,
  tokenReleased,
  tokenMoved,
  tokenCaptured,
  tokenFinished,
  extraTurn,
  turnChanged,
  playerWon,
}

class LudoGameEvent {
  const LudoGameEvent({
    required this.type,
    this.playerId,
    this.tokenId,
    this.otherTokenIds = const <int>[],
    this.value,
    this.fromPosition,
    this.toPosition,
  });

  final LudoGameEventType type;
  final String? playerId;
  final int? tokenId;
  final List<int> otherTokenIds;
  final int? value;
  final int? fromPosition;
  final int? toPosition;
}
