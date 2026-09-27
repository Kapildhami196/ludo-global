class DiceContext {
  const DiceContext({
    required this.rollsSinceSix,
    required this.allTokensInBase,
    required this.hasTokenInBase,
    required this.captureRolls,
    required this.escapeRolls,
    required this.homeEntryRolls,
    required this.finishRolls,
    required this.blockadeRolls,
    required this.turnsWithoutMajorEvent,
    required this.relativeProgressDelta,
    required this.currentPlayerNearWin,
    required this.opponentNearWin,
  });

  static const int staleMatchThreshold = 8;
  static const double significantProgressGap = 0.25;

  final int rollsSinceSix;
  final bool allTokensInBase;
  final bool hasTokenInBase;
  final Set<int> captureRolls;
  final Set<int> escapeRolls;
  final Set<int> homeEntryRolls;
  final Set<int> finishRolls;
  final Set<int> blockadeRolls;
  final int turnsWithoutMajorEvent;

  /// Current player's normalized progress minus the average normalized
  /// progress of all opponents. Negative means the player is behind.
  final double relativeProgressDelta;

  final bool currentPlayerNearWin;
  final bool opponentNearWin;

  bool get isStaleMatch =>
      turnsWithoutMajorEvent >= staleMatchThreshold;

  bool get isSignificantlyBehind =>
      relativeProgressDelta <= -significantProgressGap;

  bool get isSignificantlyAhead =>
      relativeProgressDelta >= significantProgressGap;

  Set<int> get actionRolls => <int>{
        ...captureRolls,
        ...escapeRolls,
        ...homeEntryRolls,
        ...finishRolls,
        ...blockadeRolls,
        if (hasTokenInBase) 6,
      };

  Set<int> get defensiveEndgameRolls => <int>{
        ...captureRolls,
        ...blockadeRolls,
      };
}
