import '../entities/power_type.dart';

enum PowerGameEventType {
  powerActivated,
  powerCollected,
  powerRelocated,
  doubleDistanceArmed,
  doubleDistanceUsed,
  shieldApplied,
  shieldExpired,
  diceControlled,
  bonusRollTriggered,
}

class PowerGameEvent {
  const PowerGameEvent({
    required this.type,
    required this.playerId,
    this.powerType,
    this.tokenId,
    this.value,
    this.globalIndex,
    this.previousGlobalIndex,
  });

  final PowerGameEventType type;
  final String playerId;
  final PowerType? powerType;
  final int? tokenId;
  final int? value;
  final int? globalIndex;
  final int? previousGlobalIndex;
}
