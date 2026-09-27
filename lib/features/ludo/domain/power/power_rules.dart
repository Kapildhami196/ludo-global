import '../entities/power_type.dart';

abstract final class PowerRules {
  /// Power Ludo V2 starts with no held powers. Players earn them by landing
  /// exactly on a power pickup on the shared track.
  static const int initialChargesPerPower = 0;

  static const Set<PowerType> heldPowerTypes = <PowerType>{
    PowerType.doubleDistance,
    PowerType.shield,
    PowerType.diceControl,
  };

  static const Set<PowerType> boardPickupTypes = <PowerType>{
    PowerType.doubleDistance,
    PowerType.shield,
    PowerType.diceControl,
    PowerType.bonusRoll,
  };

  /// Pre-approved neutral shared-track cells. These deliberately exclude all
  /// safe/star cells and all four player start cells.
  static const List<int> pickupEligibleGlobalIndices = <int>[
    4,
    6,
    10,
    15,
    18,
    24,
    29,
    32,
    37,
    42,
    45,
    50,
  ];

  static const int doubleDistanceMultiplier = 2;

  /// Shield protects an active shared-track token until that player receives
  /// the turn again. Other colors may land on the same square while protected;
  /// the shielded token is simply not captured.
  static const bool shieldExpiresAtOwnersNextTurn = true;

  static const int minimumControlledDiceValue = 1;
  static const int maximumControlledDiceValue = 6;

  /// Bonus Roll is not stored in inventory. Landing exactly on its board
  /// pickup grants an immediate extra roll. Extra-roll reasons never stack.
  static const bool bonusRollIsImmediatePickup = true;
}
