abstract final class ClassicRules {
  static const int tokensPerPlayer = 4;
  static const int commonPathLength = 52;
  static const int homeLaneLength = 5;
  static const int finishProgress = 57;
  static const int rollRequiredToLeaveBase = 6;
  static const int consecutiveSixLimit = 3;

  static const bool extraTurnOnSix = true;
  static const bool extraTurnOnCapture = true;
  static const bool exactRollToFinish = true;

  /// Global common-track indices that cannot capture.
  ///
  /// These are the four starting cells and the four star/safe cells.
  static const Set<int> safeGlobalIndices = <int>{
    0,
    8,
    13,
    21,
    26,
    34,
    39,
    47,
  };
}
