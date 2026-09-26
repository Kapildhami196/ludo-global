import '../entities/ludo_game_state.dart';
import '../entities/power_type.dart';
import 'power_inventory.dart';
import 'shield_effect.dart';

class PowerLudoState {
  const PowerLudoState({
    required this.gameState,
    required this.inventories,
    this.shields = const <int, ShieldEffect>{},
    this.turnSerial = 0,
    this.doubleDistancePlayerId,
    this.bonusRollPlayerId,
  });

  final LudoGameState gameState;
  final Map<String, PowerInventory> inventories;
  final Map<int, ShieldEffect> shields;
  final int turnSerial;

  /// Player who armed Double Distance for the current selected move.
  final String? doubleDistancePlayerId;

  /// Player whose queued Bonus Roll will preserve their turn when it would
  /// otherwise pass.
  final String? bonusRollPlayerId;

  PowerInventory inventoryFor(String playerId) {
    return inventories[playerId] ??
        (throw StateError('No power inventory for $playerId.'));
  }

  bool isShielded(int tokenId) => shields.containsKey(tokenId);

  bool get doubleDistanceArmed =>
      doubleDistancePlayerId == gameState.currentPlayer.id;

  bool get bonusRollQueued =>
      bonusRollPlayerId == gameState.currentPlayer.id;

  PowerLudoState copyWith({
    LudoGameState? gameState,
    Map<String, PowerInventory>? inventories,
    Map<int, ShieldEffect>? shields,
    int? turnSerial,
    String? doubleDistancePlayerId,
    bool clearDoubleDistancePlayerId = false,
    String? bonusRollPlayerId,
    bool clearBonusRollPlayerId = false,
  }) {
    return PowerLudoState(
      gameState: gameState ?? this.gameState,
      inventories: inventories ?? this.inventories,
      shields: shields ?? this.shields,
      turnSerial: turnSerial ?? this.turnSerial,
      doubleDistancePlayerId: clearDoubleDistancePlayerId
          ? null
          : doubleDistancePlayerId ?? this.doubleDistancePlayerId,
      bonusRollPlayerId: clearBonusRollPlayerId
          ? null
          : bonusRollPlayerId ?? this.bonusRollPlayerId,
    );
  }

  Set<PowerType> availablePowersForCurrentPlayer() {
    final PowerInventory inventory =
        inventoryFor(gameState.currentPlayer.id);
    return PowerType.values.where(inventory.has).toSet();
  }
}
