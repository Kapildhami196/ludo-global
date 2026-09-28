import 'dart:math';

import '../engine/ludo_board_map.dart';
import '../engine/ludo_game_engine.dart';
import '../entities/game_config.dart';
import '../entities/game_phase.dart';
import '../entities/ludo_game_action_result.dart';
import '../entities/ludo_game_event.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_token.dart';
import '../entities/power_type.dart';
import '../entities/token_status.dart';
import '../rules/classic_rules.dart';
import 'board_power_pickup.dart';
import 'power_game_event.dart';
import 'power_inventory.dart';
import 'power_ludo_action_result.dart';
import 'power_ludo_state.dart';
import 'power_rules.dart';
import 'shield_effect.dart';

class PowerLudoEngine {
  PowerLudoEngine({
    LudoGameEngine? classicEngine,
    Random? random,
  })  : _classic = classicEngine ?? LudoGameEngine(),
        _random = random ?? Random();

  final LudoGameEngine _classic;
  final Random _random;

  PowerLudoState createGame({
    required LudoGameConfig config,
    required List<String> playerNames,
    int? startingPlayerIndex,
  }) {
    if (config.mode != LudoGameMode.power) {
      throw ArgumentError(
        'PowerLudoEngine requires LudoGameMode.power.',
      );
    }

    final LudoGameState gameState = _classic.createGame(
      config: config,
      playerNames: playerNames,
      startingPlayerIndex: startingPlayerIndex,
    );

    return PowerLudoState(
      gameState: gameState,
      inventories: <String, PowerInventory>{
        for (final player in gameState.players)
          player.id: PowerInventory.initial(),
      },
      pickups: _createInitialPickups(),
    );
  }

  PowerLudoActionResult rollDice(PowerLudoState state) {
    _requirePowerMode(state);
    return _resolveClassicAction(
      before: state,
      baseResult: _classic.rollDice(state.gameState),
    );
  }

  PowerLudoActionResult useDiceControl(
    PowerLudoState state,
    int value,
  ) {
    _requirePowerMode(state);
    _requirePhase(state.gameState, GamePhase.waitingForRoll);

    if (value < PowerRules.minimumControlledDiceValue ||
        value > PowerRules.maximumControlledDiceValue) {
      throw ArgumentError.value(
        value,
        'value',
        'Dice Control value must be from 1 through 6.',
      );
    }

    final String playerId = state.gameState.currentPlayer.id;
    final PowerLudoState consumed = _consume(
      state,
      playerId,
      PowerType.diceControl,
    );

    final LudoGameActionResult result = _classic.rollDice(
      consumed.gameState,
      forcedValue: value,
    );

    return _resolveClassicAction(
      before: consumed,
      baseResult: result,
      powerEvents: <PowerGameEvent>[
        PowerGameEvent(
          type: PowerGameEventType.powerActivated,
          playerId: playerId,
          powerType: PowerType.diceControl,
          value: value,
        ),
        PowerGameEvent(
          type: PowerGameEventType.diceControlled,
          playerId: playerId,
          powerType: PowerType.diceControl,
          value: value,
        ),
      ],
    );
  }

  PowerLudoActionResult armDoubleDistance(
    PowerLudoState state,
  ) {
    _requirePowerMode(state);
    _requirePhase(state.gameState, GamePhase.selectingToken);

    final String playerId = state.gameState.currentPlayer.id;
    if (state.doubleDistanceArmed) {
      throw StateError('Double Distance is already armed.');
    }

    final int diceValue = state.gameState.diceValue ??
        (throw StateError('Roll the dice before using Double Distance.'));
    final int distance =
        diceValue * PowerRules.doubleDistanceMultiplier;

    final List<int> eligibleTokenIds = state
        .gameState.currentPlayer.tokens
        .where(
          (LudoToken token) =>
              !token.isInBase &&
              !token.isFinished &&
              _classic.canMoveToken(
                state: state.gameState,
                token: token,
                diceValue: diceValue,
                movementDistance: distance,
              ),
        )
        .map((LudoToken token) => token.id)
        .toList(growable: false);

    if (eligibleTokenIds.isEmpty) {
      throw StateError(
        'No token can legally use Double Distance for this roll.',
      );
    }

    final PowerLudoState consumed = _consume(
      state,
      playerId,
      PowerType.doubleDistance,
    );

    final PowerLudoState next = consumed.copyWith(
      gameState: consumed.gameState.copyWith(
        movableTokenIds: eligibleTokenIds,
      ),
      doubleDistancePlayerId: playerId,
    );

    return PowerLudoActionResult(
      state: next,
      powerEvents: <PowerGameEvent>[
        PowerGameEvent(
          type: PowerGameEventType.powerActivated,
          playerId: playerId,
          powerType: PowerType.doubleDistance,
          value: distance,
        ),
        PowerGameEvent(
          type: PowerGameEventType.doubleDistanceArmed,
          playerId: playerId,
          powerType: PowerType.doubleDistance,
          value: distance,
        ),
      ],
    );
  }

  PowerLudoActionResult applyShield(
    PowerLudoState state,
    int tokenId,
  ) {
    _requirePowerMode(state);
    _requirePhase(state.gameState, GamePhase.waitingForRoll);

    final String playerId = state.gameState.currentPlayer.id;
    final LudoToken token = state.gameState.currentPlayer.tokens.firstWhere(
      (LudoToken candidate) => candidate.id == tokenId,
      orElse: () => throw StateError(
        'Token $tokenId does not belong to the current player.',
      ),
    );

    if (token.status != TokenStatus.active) {
      throw StateError(
        'Shield can only protect a token on the shared track.',
      );
    }

    if (state.isShielded(tokenId)) {
      throw StateError('Token $tokenId is already shielded.');
    }

    final PowerLudoState consumed = _consume(
      state,
      playerId,
      PowerType.shield,
    );

    final Map<int, ShieldEffect> shields =
        Map<int, ShieldEffect>.of(consumed.shields)
          ..[tokenId] = ShieldEffect(
            tokenId: tokenId,
            ownerPlayerId: playerId,
            activatedAtTurnSerial: state.turnSerial,
          );

    return PowerLudoActionResult(
      state: consumed.copyWith(shields: shields),
      powerEvents: <PowerGameEvent>[
        PowerGameEvent(
          type: PowerGameEventType.powerActivated,
          playerId: playerId,
          powerType: PowerType.shield,
          tokenId: tokenId,
        ),
        PowerGameEvent(
          type: PowerGameEventType.shieldApplied,
          playerId: playerId,
          powerType: PowerType.shield,
          tokenId: tokenId,
        ),
      ],
    );
  }

  PowerLudoActionResult moveToken(
    PowerLudoState state,
    int tokenId,
  ) {
    _requirePowerMode(state);
    _requirePhase(state.gameState, GamePhase.selectingToken);

    final int actingPlayerIndex = state.gameState.currentPlayerIndex;
    final String playerId = state.gameState.currentPlayer.id;
    final int diceValue = state.gameState.diceValue ??
        (throw StateError('A token cannot move without a dice value.'));

    final bool doubleArmed = state.doubleDistanceArmed;
    final int? movementDistance = doubleArmed
        ? diceValue * PowerRules.doubleDistanceMultiplier
        : null;

    LudoGameActionResult gameResult = _classic.moveToken(
      state.gameState,
      tokenId,
      movementDistance: movementDistance,
      protectedTokenIds: state.shields.keys.toSet(),
    );

    final List<PowerGameEvent> powerEvents = <PowerGameEvent>[];
    PowerLudoState working = doubleArmed
        ? state.copyWith(clearDoubleDistancePlayerId: true)
        : state;

    if (doubleArmed) {
      powerEvents.add(
        PowerGameEvent(
          type: PowerGameEventType.doubleDistanceUsed,
          playerId: playerId,
          powerType: PowerType.doubleDistance,
          tokenId: tokenId,
          value: movementDistance,
        ),
      );
    }

    final LudoGameEvent moveEvent = gameResult.events.firstWhere(
      (LudoGameEvent event) =>
          event.type == LudoGameEventType.tokenMoved ||
          event.type == LudoGameEventType.tokenReleased,
    );

    final int? toPosition = moveEvent.toPosition;
    if (toPosition != null &&
        toPosition >= 0 &&
        toPosition < ClassicRules.sharedPathProgressLength) {
      final int globalIndex = LudoBoardMap.globalIndexFor(
        color: state.gameState.currentPlayer.color,
        pathPosition: toPosition,
      );
      final BoardPowerPickup? pickup =
          working.pickupAtGlobalIndex(globalIndex);

      if (pickup != null) {
        final Map<PowerType, BoardPowerPickup> relocated =
            _relocatePickup(
          working.pickups,
          pickup.type,
        );

        powerEvents.add(
          PowerGameEvent(
            type: PowerGameEventType.powerCollected,
            playerId: playerId,
            powerType: pickup.type,
            tokenId: tokenId,
            globalIndex: globalIndex,
          ),
        );

        powerEvents.add(
          PowerGameEvent(
            type: PowerGameEventType.powerRelocated,
            playerId: playerId,
            powerType: pickup.type,
            previousGlobalIndex: globalIndex,
            globalIndex: relocated[pickup.type]!.globalIndex,
          ),
        );

        if (pickup.type == PowerType.bonusRoll) {
          powerEvents.add(
            PowerGameEvent(
              type: PowerGameEventType.bonusRollTriggered,
              playerId: playerId,
              powerType: PowerType.bonusRoll,
              tokenId: tokenId,
              globalIndex: globalIndex,
            ),
          );

          gameResult = _grantImmediateBonusRoll(
            baseResult: gameResult,
            actingPlayerIndex: actingPlayerIndex,
            actingPlayerId: playerId,
          );
          working = working.copyWith(pickups: relocated);
        } else {
          final PowerInventory inventory =
              working.inventoryFor(playerId).add(pickup.type);
          working = working.copyWith(
            inventories: <String, PowerInventory>{
              ...working.inventories,
              playerId: inventory,
            },
            pickups: relocated,
          );
        }
      }
    }

    return _resolveClassicAction(
      before: working,
      baseResult: gameResult,
      powerEvents: powerEvents,
    );
  }

  bool canUseDoubleDistance(PowerLudoState state) {
    if (!_hasCharge(
          state,
          state.gameState.currentPlayer.id,
          PowerType.doubleDistance,
        ) ||
        state.gameState.phase != GamePhase.selectingToken ||
        state.doubleDistanceArmed) {
      return false;
    }

    final int? diceValue = state.gameState.diceValue;
    if (diceValue == null) {
      return false;
    }

    final int distance =
        diceValue * PowerRules.doubleDistanceMultiplier;

    return state.gameState.currentPlayer.tokens.any(
      (LudoToken token) =>
          !token.isInBase &&
          !token.isFinished &&
          _classic.canMoveToken(
            state: state.gameState,
            token: token,
            diceValue: diceValue,
            movementDistance: distance,
          ),
    );
  }

  bool canUseShield(PowerLudoState state) {
    return state.gameState.phase == GamePhase.waitingForRoll &&
        _hasCharge(
          state,
          state.gameState.currentPlayer.id,
          PowerType.shield,
        ) &&
        state.gameState.currentPlayer.tokens.any(
          (LudoToken token) =>
              token.status == TokenStatus.active &&
              !state.isShielded(token.id),
        );
  }

  bool canUseDiceControl(PowerLudoState state) {
    return state.gameState.phase == GamePhase.waitingForRoll &&
        _hasCharge(
          state,
          state.gameState.currentPlayer.id,
          PowerType.diceControl,
        );
  }

  Map<PowerType, BoardPowerPickup> _createInitialPickups() {
    final List<int> cells =
        List<int>.of(PowerRules.pickupEligibleGlobalIndices)
          ..shuffle(_random);

    return <PowerType, BoardPowerPickup>{
      for (int index = 0;
          index < PowerType.values.length;
          index++)
        PowerType.values[index]: BoardPowerPickup(
          type: PowerType.values[index],
          globalIndex: cells[index],
        ),
    };
  }

  Map<PowerType, BoardPowerPickup> _relocatePickup(
    Map<PowerType, BoardPowerPickup> pickups,
    PowerType type,
  ) {
    final BoardPowerPickup current = pickups[type] ??
        (throw StateError('Missing pickup for $type.'));

    final Set<int> occupiedByOthers = pickups.entries
        .where((entry) => entry.key != type)
        .map((entry) => entry.value.globalIndex)
        .toSet();

    final List<int> available = PowerRules
        .pickupEligibleGlobalIndices
        .where(
          (index) =>
              index != current.globalIndex &&
              !occupiedByOthers.contains(index),
        )
        .toList(growable: false);

    if (available.isEmpty) {
      throw StateError('No eligible cell is available for $type.');
    }

    final int nextIndex =
        available[_random.nextInt(available.length)];

    return <PowerType, BoardPowerPickup>{
      ...pickups,
      type: BoardPowerPickup(
        type: type,
        globalIndex: nextIndex,
      ),
    };
  }

  LudoGameActionResult _grantImmediateBonusRoll({
    required LudoGameActionResult baseResult,
    required int actingPlayerIndex,
    required String actingPlayerId,
  }) {
    if (baseResult.state.isGameOver ||
        baseResult.state.currentPlayerIndex == actingPlayerIndex) {
      return baseResult;
    }

    final List<LudoGameEvent> events = baseResult.events
        .where(
          (LudoGameEvent event) =>
              event.type != LudoGameEventType.turnChanged,
        )
        .toList(growable: true);

    if (!events.any(
      (event) => event.type == LudoGameEventType.extraTurn,
    )) {
      events.add(
        LudoGameEvent(
          type: LudoGameEventType.extraTurn,
          playerId: actingPlayerId,
        ),
      );
    }

    return LudoGameActionResult(
      state: baseResult.state.copyWith(
        currentPlayerIndex: actingPlayerIndex,
        phase: GamePhase.waitingForRoll,
        clearDiceValue: true,
        movableTokenIds: const <int>[],
        consecutiveSixes: 0,
      ),
      events: events,
    );
  }

  PowerLudoActionResult _resolveClassicAction({
    required PowerLudoState before,
    required LudoGameActionResult baseResult,
    List<PowerGameEvent> powerEvents = const <PowerGameEvent>[],
  }) {
    final int actingPlayerIndex = before.gameState.currentPlayerIndex;
    final bool changedPlayer =
        baseResult.state.currentPlayerIndex != actingPlayerIndex;

    PowerLudoState next = before.copyWith(
      gameState: baseResult.state,
      clearDoubleDistancePlayerId: true,
    );

    final List<PowerGameEvent> resolvedPowerEvents =
        List<PowerGameEvent>.of(powerEvents);

    if (changedPlayer) {
      final int nextTurnSerial = before.turnSerial + 1;
      final String nextPlayerId =
          baseResult.state.currentPlayer.id;
      final Map<int, ShieldEffect> shields =
          Map<int, ShieldEffect>.of(before.shields);

      final List<int> expiredTokenIds = <int>[];
      for (final MapEntry<int, ShieldEffect> entry
          in before.shields.entries) {
        final ShieldEffect effect = entry.value;
        if (effect.ownerPlayerId == nextPlayerId &&
            nextTurnSerial > effect.activatedAtTurnSerial) {
          expiredTokenIds.add(entry.key);
        }
      }

      for (final int tokenId in expiredTokenIds) {
        final ShieldEffect effect = shields.remove(tokenId)!;
        resolvedPowerEvents.add(
          PowerGameEvent(
            type: PowerGameEventType.shieldExpired,
            playerId: effect.ownerPlayerId,
            powerType: PowerType.shield,
            tokenId: tokenId,
          ),
        );
      }

      next = next.copyWith(
        turnSerial: nextTurnSerial,
        shields: shields,
      );
    }

    return PowerLudoActionResult(
      state: next,
      gameEvents: baseResult.events,
      powerEvents: resolvedPowerEvents,
    );
  }

  PowerLudoState _consume(
    PowerLudoState state,
    String playerId,
    PowerType type,
  ) {
    if (!PowerRules.heldPowerTypes.contains(type)) {
      throw StateError('$type is not a manually activated power.');
    }

    final PowerInventory inventory = state.inventoryFor(playerId);
    if (!inventory.has(type)) {
      throw StateError('Collect $type from the board first.');
    }

    return state.copyWith(
      inventories: <String, PowerInventory>{
        ...state.inventories,
        playerId: inventory.consume(type),
      },
    );
  }

  bool _hasCharge(
    PowerLudoState state,
    String playerId,
    PowerType type,
  ) {
    return state.inventoryFor(playerId).has(type);
  }

  void _requirePowerMode(PowerLudoState state) {
    if (state.gameState.mode != LudoGameMode.power) {
      throw StateError('Power action attempted outside Power Ludo.');
    }
  }

  void _requirePhase(
    LudoGameState state,
    GamePhase expected,
  ) {
    if (state.phase != expected) {
      throw StateError(
        'Expected game phase $expected but was ${state.phase}.',
      );
    }
  }
}
