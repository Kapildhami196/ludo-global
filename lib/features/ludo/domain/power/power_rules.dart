abstract final class PowerRules {
  /// Every player starts a Power Ludo match with one charge of each power.
  static const int initialChargesPerPower = 1;

  /// Double Distance can only be used after rolling and only on a token that
  /// has already left base. It doubles movement steps for the selected move.
  static const int doubleDistanceMultiplier = 2;

  /// A shield protects an active shared-track token until the owner next
  /// receives the turn. Home-lane and finished tokens cannot be shielded.
  static const bool shieldExpiresAtOwnersNextTurn = true;

  /// Dice Control may choose any legal die face.
  static const int minimumControlledDiceValue = 1;
  static const int maximumControlledDiceValue = 6;

  /// Bonus Roll is queued before a roll. It is only spent when the current
  /// turn would otherwise pass to the next player. Natural extra turns from
  /// a six or capture happen first and do not waste the queued bonus.
  static const bool bonusWaitsForNaturalExtraTurns = true;
}
