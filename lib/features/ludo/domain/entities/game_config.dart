enum LudoGameMode {
  normal,
  power,
}

enum LudoMatchType {
  localPassAndPlay,
  computer,
  online,
  privateRoom,
  friends,
}

class LudoGameConfig {
  const LudoGameConfig({
    required this.mode,
    required this.matchType,
    required this.playerCount,
  }) : assert(
          playerCount >= 2 && playerCount <= 4,
          'Ludo supports 2 to 4 players.',
        );

  final LudoGameMode mode;
  final LudoMatchType matchType;
  final int playerCount;

  bool get powersEnabled => mode == LudoGameMode.power;

  bool get isSameDevice =>
      matchType == LudoMatchType.localPassAndPlay;
}
