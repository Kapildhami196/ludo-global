class PlayerDiceHistory {
  const PlayerDiceHistory({
    this.rollsSinceSix = 0,
    this.recentRolls = const <int>[],
    this.strongAssistCooldown = 0,
  });

  static const int maxRecentRolls = 12;

  final int rollsSinceSix;
  final List<int> recentRolls;
  final int strongAssistCooldown;

  PlayerDiceHistory recordRoll(
    int value, {
    int? strongAssistCooldown,
  }) {
    if (value < 1 || value > 6) {
      throw ArgumentError.value(
        value,
        'value',
        'Dice value must be from 1 through 6.',
      );
    }

    final List<int> updatedRolls = <int>[
      ...recentRolls,
      value,
    ];

    final List<int> trimmedRolls = updatedRolls.length <= maxRecentRolls
        ? updatedRolls
        : updatedRolls.sublist(
            updatedRolls.length - maxRecentRolls,
          );

    return PlayerDiceHistory(
      rollsSinceSix: value == 6 ? 0 : rollsSinceSix + 1,
      recentRolls: List<int>.unmodifiable(trimmedRolls),
      strongAssistCooldown:
          strongAssistCooldown ?? this.strongAssistCooldown,
    );
  }

  PlayerDiceHistory tickAssistCooldown() {
    if (strongAssistCooldown <= 0) {
      return this;
    }

    return PlayerDiceHistory(
      rollsSinceSix: rollsSinceSix,
      recentRolls: recentRolls,
      strongAssistCooldown: strongAssistCooldown - 1,
    );
  }

  PlayerDiceHistory withStrongAssistCooldown(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Cooldown cannot be negative.',
      );
    }

    return PlayerDiceHistory(
      rollsSinceSix: rollsSinceSix,
      recentRolls: recentRolls,
      strongAssistCooldown: value,
    );
  }
}
