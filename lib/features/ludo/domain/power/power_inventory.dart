import '../entities/power_type.dart';
import 'power_rules.dart';

class PowerInventory {
  const PowerInventory({
    required this.charges,
  });

  factory PowerInventory.initial() {
    return const PowerInventory(
      charges: <PowerType, int>{
        PowerType.doubleDistance: PowerRules.initialChargesPerPower,
        PowerType.shield: PowerRules.initialChargesPerPower,
        PowerType.diceControl: PowerRules.initialChargesPerPower,
        PowerType.bonusRoll: 0,
      },
    );
  }

  final Map<PowerType, int> charges;

  int count(PowerType type) => charges[type] ?? 0;

  bool has(PowerType type) => count(type) > 0;

  PowerInventory add(PowerType type) {
    if (!PowerRules.heldPowerTypes.contains(type)) {
      throw StateError('$type is an immediate board effect, not inventory.');
    }

    return PowerInventory(
      charges: <PowerType, int>{
        ...charges,
        type: count(type) + 1,
      },
    );
  }

  PowerInventory consume(PowerType type) {
    final int current = count(type);
    if (current <= 0) {
      throw StateError('No $type charges remain.');
    }

    return PowerInventory(
      charges: <PowerType, int>{
        ...charges,
        type: current - 1,
      },
    );
  }
}
