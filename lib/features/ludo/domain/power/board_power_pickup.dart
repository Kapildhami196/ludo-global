import '../entities/power_type.dart';

class BoardPowerPickup {
  const BoardPowerPickup({
    required this.type,
    required this.globalIndex,
  });

  final PowerType type;
  final int globalIndex;

  BoardPowerPickup copyWith({
    PowerType? type,
    int? globalIndex,
  }) {
    return BoardPowerPickup(
      type: type ?? this.type,
      globalIndex: globalIndex ?? this.globalIndex,
    );
  }
}
