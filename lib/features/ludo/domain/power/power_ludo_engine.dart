import '../engine/ludo_game_engine.dart';
import '../entities/game_config.dart';
import '../entities/game_phase.dart';
import '../entities/ludo_game_action_result.dart';
import '../entities/ludo_game_event.dart';
import '../entities/ludo_game_state.dart';
import '../entities/ludo_token.dart';
import '../entities/power_type.dart';
import '../entities/token_status.dart';
import 'power_game_event.dart';
import 'power_inventory.dart';
import 'power_ludo_action_result.dart';
import 'power_ludo_state.dart';
import 'power_rules.dart';
import 'shield_effect.dart';

class PowerLudoEngine {
  PowerLudoEngine({
    LudoGameEngine? classicEngine,
  }) : _classic = classicEngine ?? LudoGameEngine();

  final LudoGameEngine _classic;

  PowerLudoState createGame({
    required LudoGameConfig config,
    required List<String> playerNames,
  }) {
    if (config.mode != LudoGameMode.power) {
      throw ArgumentError(
        'PowerLudoEngine requires LudoGameMode.power.',
      );
    }

    final LudoGameState gameState = _classic.createGame(
      config: config,
      playerNames: playerNames,
    );

    return PowerLudoState(
      gameState: gameState,
      inventories: <String, PowerInventory>{
        for (final player in gameState.players)
          player.id: PowerInventory.initial(),
      },
    );
  }

  PowerLudoActionResult rollDice(PowerLudoState state) {
    _requirePowerMode(state);
    final LudoGameActionResult result =
        _classic.rollDice(state.gameState);

    return _resolveClassicAction(
      before: state,
      baseResult: result,
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

    final LudoGameState filteredGameState =
        consumed.gameState.copyWith(
      movableTokenIds: eligibleTokenIds,
    );

    final PowerLudoState next = consumed.copyWith(
      gameState: filteredGameState,
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

  PowerLudoActionResult queueBonusRoll(PowerLudoState state) {
    _requirePowerMode(state);
    _requirePhase(state.gameState, GamePhase.waitingForRoll);

    final String playerId = state.gameState.currentPlayer.id;
    if (state.bonusRollQueued) {
      throw StateError('Bonus Roll is already queued.');
    }

    final PowerLudoState consumed = _consume(
      state,
      playerId,
      PowerType.bonusRoll,
    );

    return PowerLudoActionResult(
      state: consumed.copyWith(
        bonusRollPlayerId: playerId,
      ),
      powerEvents: <PowerGameEvent>[
        PowerGameEvent(
          type: PowerGameEventType.powerActivated,
          playerId: playerId,
          powerType: PowerType.bonusRoll,
        ),
        PowerGameEvent(
          type: PowerGameEventType.bonusRollQueued,
          playerId: playerId,
          powerType: PowerType.bonusRoll,
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

    final String playerId = state.gameState.currentPlayer.id;
    final int diceValue = state.gameState.diceValue ??
        (throw StateError('A token cannot move without a dice value.'));

    final bool doubleArmed = state.doubleDistanceArmed;
    final int? movementDistance = doubleArmed
        ? diceValue * PowerRules.doubleDistanceMultiplier
        : null;

    final LudoGameActionResult result = _classic.moveToken(
      state.gameState,
      tokenId,
      movementDistance: movementDistance,
      protectedTokenIds: state.shields.keys.toSet(),
    );

    final List<PowerGameEvent> powerEvents = <PowerGameEvent>[];
    PowerLudoState working = state;

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
      working = working.copyWith(
        clearDoubleDistancePlayerId: true,
      );
    }

    return _resolveClassicAction(
      before: working,
      baseResult: result,
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

  bool canUseBonusRoll(PowerLudoState state) {
    return state.gameState.phase == GamePhase.waitingForRoll &&
        !state.bonusRollQueued &&
        _hasCharge(
          state,
          state.gameState.currentPlayer.id,
          PowerType.bonusRoll,
        );
  }

  PowerLudoActionResult _resolveClassicAction({
    required PowerLudoState before,
    required LudoGameActionResult baseResult,
    List<PowerGameEvent> powerEvents = const <PowerGameEvent>[],
  }) {
    final String actingPlayerId = before.gameState.currentPlayer.id;
    final int actingPlayerIndex = before.gameState.currentPlayerIndex;
    final bool changedPlayer =
        baseResult.state.currentPlayerIndex != actingPlayerIndex;
    final bool forfeitedByThreeSixes = baseResult.events.any(
      (LudoGameEvent event) =>
          event.type == LudoGameEventType.threeSixesForfeit,
    );

    if (changedPlayer &&
        before.bonusRollPlayerId == actingPlayerId &&
        !forfeitedByThreeSixes) {
      final LudoGameState preserved =
          baseResult.state.copyWith(
        currentPlayerIndex: actingPlayerIndex,
        phase: GamePhase.waitingForRoll,
        clearDiceValue: true,
        movableTokenIds: const <int>[],
        consecutiveSixes: 0,
      );

      final List<LudoGameEvent> gameEvents = baseResult.events
          .where(
            (LudoGameEvent event) =>
                event.type != LudoGameEventType.turnChanged,
          )
          .toList(growable: true)
        ..add(
          LudoGameEvent(
            type: LudoGameEventType.extraTurn,
            playerId: actingPlayerId,
          ),
        );

      return PowerLudoActionResult(
        state: before.copyWith(
          gameState: preserved,
          clearBonusRollPlayerId: true,
        ),
        gameEvents: gameEvents,
        powerEvents: <PowerGameEvent>[
          ...powerEvents,
          PowerGameEvent(
            type: PowerGameEventType.bonusRollGranted,
            playerId: actingPlayerId,
            powerType: PowerType.bonusRoll,
          ),
        ],
      );
    }

    PowerLudoState next = before.copyWith(
      gameState: baseResult.state,
      clearDoubleDistancePlayerId: true,
      clearBonusRollPlayerId:
          changedPlayer &&
          before.bonusRollPlayerId == actingPlayerId &&
          forfeitedByThreeSixes,
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
    final PowerInventory inventory = state.inventoryFor(playerId);
    if (!inventory.has(type)) {
      throw StateError('No $type charges remain.');
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
