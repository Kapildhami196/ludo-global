import '../entities/ludo_game_state.dart';
import '../entities/power_type.dart';
import 'board_power_pickup.dart';
import 'power_inventory.dart';
import 'shield_effect.dart';

class PowerLudoState {
  const PowerLudoState({
    required this.gameState,
    required this.inventories,
    required this.pickups,
    this.shields = const <int, ShieldEffect>{},
    this.turnSerial = 0,
    this.doubleDistancePlayerId,
  });

  final LudoGameState gameState;
  final Map<String, PowerInventory> inventories;
  final Map<PowerType, BoardPowerPickup> pickups;
  final Map<int, ShieldEffect> shields;
  final int turnSerial;
  final String? doubleDistancePlayerId;

  PowerInventory inventoryFor(String playerId) {
    return inventories[playerId] ??
        (throw StateError('No power inventory for $playerId.'));
  }

  bool isShielded(int tokenId) => shields.containsKey(tokenId);

  bool get doubleDistanceArmed =>
      doubleDistancePlayerId == gameState.currentPlayer.id;

  BoardPowerPickup? pickupAtGlobalIndex(int globalIndex) {
    for (final BoardPowerPickup pickup in pickups.values) {
      if (pickup.globalIndex == globalIndex) {
        return pickup;
      }
    }
    return null;
  }

  PowerLudoState copyWith({
    LudoGameState? gameState,
    Map<String, PowerInventory>? inventories,
    Map<PowerType, BoardPowerPickup>? pickups,
    Map<int, ShieldEffect>? shields,
    int? turnSerial,
    String? doubleDistancePlayerId,
    bool clearDoubleDistancePlayerId = false,
  }) {
    return PowerLudoState(
      gameState: gameState ?? this.gameState,
      inventories: inventories ?? this.inventories,
      pickups: pickups ?? this.pickups,
      shields: shields ?? this.shields,
      turnSerial: turnSerial ?? this.turnSerial,
      doubleDistancePlayerId: clearDoubleDistancePlayerId
          ? null
          : doubleDistancePlayerId ?? this.doubleDistancePlayerId,
    );
  }

  Set<PowerType> availablePowersForCurrentPlayer() {
    final PowerInventory inventory =
        inventoryFor(gameState.currentPlayer.id);
    return PowerType.values.where(inventory.has).toSet();
  }
}
