class DiceContext {
  const DiceContext({
    required this.rollsSinceSix,
    required this.allTokensInBase,
    required this.hasTokenInBase,
    required this.captureRolls,
    required this.escapeRolls,
    required this.turnsWithoutMajorEvent,
  });

  static const int staleMatchThreshold = 8;

  final int rollsSinceSix;
  final bool allTokensInBase;
  final bool hasTokenInBase;
  final Set<int> captureRolls;
  final Set<int> escapeRolls;
  final int turnsWithoutMajorEvent;

  bool get isStaleMatch =>
      turnsWithoutMajorEvent >= staleMatchThreshold;

  Set<int> get actionRolls => <int>{
        ...captureRolls,
        ...escapeRolls,
        if (hasTokenInBase) 6,
      };
}
