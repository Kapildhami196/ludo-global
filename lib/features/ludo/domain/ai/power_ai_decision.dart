import '../entities/power_type.dart';

enum PowerAiPreRollActionType {
  normalRoll,
  shield,
  diceControl,
  bonusRoll,
}

class PowerAiPreRollDecision {
  const PowerAiPreRollDecision({
    required this.type,
    this.tokenId,
    this.diceValue,
    this.score = 0,
    this.reason = '',
  });

  final PowerAiPreRollActionType type;
  final int? tokenId;
  final int? diceValue;
  final double score;
  final String reason;

  PowerType? get powerType => switch (type) {
        PowerAiPreRollActionType.normalRoll => null,
        PowerAiPreRollActionType.shield => PowerType.shield,
        PowerAiPreRollActionType.diceControl => PowerType.diceControl,
        PowerAiPreRollActionType.bonusRoll => PowerType.bonusRoll,
      };
}

class PowerAiDoubleDecision {
  const PowerAiDoubleDecision({
    required this.shouldUse,
    this.scoreGain = 0,
    this.reason = '',
  });

  final bool shouldUse;
  final double scoreGain;
  final String reason;
}
