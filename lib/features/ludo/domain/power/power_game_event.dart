import '../entities/power_type.dart';

enum PowerGameEventType {
  powerActivated,
  doubleDistanceArmed,
  doubleDistanceUsed,
  shieldApplied,
  shieldExpired,
  diceControlled,
  bonusRollQueued,
  bonusRollGranted,
}

class PowerGameEvent {
  const PowerGameEvent({
    required this.type,
    required this.playerId,
    this.powerType,
    this.tokenId,
    this.value,
  });

  final PowerGameEventType type;
  final String playerId;
  final PowerType? powerType;
  final int? tokenId;
  final int? value;
}
