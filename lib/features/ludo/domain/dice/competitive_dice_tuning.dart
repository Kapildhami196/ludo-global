class CompetitiveDiceTuning {
  const CompetitiveDiceTuning({
    this.baseWeight = 100,
    this.sixDroughtStartBoost = 15,
    this.sixDroughtMediumBoost = 20,
    this.sixDroughtLongBoost = 25,
    this.allTokensInBaseBoost = 25,
    this.captureBoost = 35,
    this.escapeBoost = 15,
    this.homeEntryBoost = 12,
    this.finishBoost = 20,
    this.blockadeBoost = 12,
    this.staleActionBoost = 15,
    this.behindActionBoost = 10,
    this.endgameDefenseBoost = 20,
    this.endgameFinishBoost = 20,
    this.maxSingleFaceProbability = 0.40,
    this.cooldownBoostMultiplier = 0.35,
    this.strongAssistCooldownRolls = 2,
  });

  static const CompetitiveDiceTuning balanced =
      CompetitiveDiceTuning();

  final double baseWeight;
  final double sixDroughtStartBoost;
  final double sixDroughtMediumBoost;
  final double sixDroughtLongBoost;
  final double allTokensInBaseBoost;
  final double captureBoost;
  final double escapeBoost;
  final double homeEntryBoost;
  final double finishBoost;
  final double blockadeBoost;
  final double staleActionBoost;
  final double behindActionBoost;
  final double endgameDefenseBoost;
  final double endgameFinishBoost;
  final double maxSingleFaceProbability;
  final double cooldownBoostMultiplier;
  final int strongAssistCooldownRolls;
}
