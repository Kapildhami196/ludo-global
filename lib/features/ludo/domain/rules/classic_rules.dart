abstract final class ClassicRules {
  static const int tokensPerPlayer = 4;
  static const int commonPathLength = 52;
  static const int homeLaneLength = 5;
  static const int finishProgress = 57;
  static const int rollRequiredToLeaveBase = 6;
  static const int consecutiveSixLimit = 3;

  // Gameplay Rules V2.
  static const bool extraTurnOnSix = true;
  static const bool extraTurnOnCapture = true;
  static const bool extraTurnOnFinish = true;
  static const bool exactRollToFinish = true;
  static const bool autoMoveSingleLegalToken = true;
  static const Duration singleLegalTokenAutoMoveDelay =
      Duration(milliseconds: 700);
  static const Duration onlineTurnDuration = Duration(seconds: 20);

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
