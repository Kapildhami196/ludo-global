import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/ai/ai_difficulty.dart';
import '../../domain/ai/power_ai_decision.dart';
import '../../domain/ai/power_ludo_ai_strategy.dart';
import '../../domain/entities/game_config.dart';
import '../../domain/entities/game_phase.dart';
import '../../domain/entities/ludo_game_event.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/ludo_token.dart';
import '../../domain/entities/player_color.dart';
import '../../domain/entities/power_type.dart';
import '../../domain/entities/token_status.dart';
import '../../domain/power/power_game_event.dart';
import '../../domain/power/power_inventory.dart';
import '../../domain/power/power_ludo_action_result.dart';
import '../../domain/power/power_ludo_engine.dart';
import '../../domain/power/power_ludo_state.dart';
import '../../domain/rules/classic_rules.dart';
import '../services/game_feedback_service.dart';
import '../widgets/game_board_stage.dart';
import '../widgets/game_fx_overlay.dart';
import '../widgets/gameplay_callout.dart';
import '../widgets/gameplay_header.dart';
import '../widgets/ludo_board.dart';
import '../widgets/match_result_dialog.dart';
import '../widgets/power_action_bar.dart';

class PowerComputerGameScreen extends StatefulWidget {
  const PowerComputerGameScreen({
    required this.playerNames,
    required this.difficulty,
    super.key,
  });

  final List<String> playerNames;
  final AiDifficulty difficulty;

  @override
  State<PowerComputerGameScreen> createState() =>
      _PowerComputerGameScreenState();
}

class _PowerComputerGameScreenState
    extends State<PowerComputerGameScreen> {
  final PowerLudoEngine _engine = PowerLudoEngine();
  final PowerLudoAiStrategy _ai = PowerLudoAiStrategy();
  final Map<int, int> _visualPathOverrides = <int, int>{};

  late PowerLudoState _powerState;

  int _lastDiceValue = 1;
  int _fxSequence = 0;
  int _autoMoveSequence = 0;
  int? _movingTokenId;
  Set<int> _capturedTokenIds = const <int>{};
  Set<int> _returningTokenIds = const <int>{};
  GameFxType? _fxType;
  String? _fxLabel;

  bool _isRolling = false;
  bool _isMoving = false;
  bool _computerLoopRunning = false;
  final bool _soundEnabled = true;
  final bool _hapticsEnabled = true;

  String _message = '';

  LudoGameState get _state => _powerState.gameState;
  bool get _isHumanTurn => _state.currentPlayerIndex == 0;
  bool get _isBusy => _isRolling || _isMoving;

  GameFeedbackService get _feedback => GameFeedbackService(
        soundEnabled: _soundEnabled,
        hapticsEnabled: _hapticsEnabled,
      );

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _powerState = _engine.createGame(
      config: LudoGameConfig(
        mode: LudoGameMode.power,
        matchType: LudoMatchType.computer,
        playerCount: widget.playerNames.length,
      ),
      playerNames: widget.playerNames,
    );
    _lastDiceValue = 1;
    _fxSequence = 0;
    _movingTokenId = null;
    _capturedTokenIds = const <int>{};
    _returningTokenIds = const <int>{};
    _fxType = null;
    _fxLabel = null;
    _isRolling = false;
    _isMoving = false;
    _computerLoopRunning = false;
    _visualPathOverrides.clear();
    _message = _isHumanTurn
        ? 'Your Power turn. Choose a power or roll.'
        : '${_state.currentPlayer.name} starts.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startComputerIfNeeded();
    });
  }

  bool get _canHumanRoll =>
      _isHumanTurn &&
      !_isBusy &&
      _state.phase == GamePhase.waitingForRoll &&
      !_state.isGameOver;

  Set<PowerType> get _enabledHumanPowers {
    if (!_isHumanTurn || _isBusy) {
      return const <PowerType>{};
    }

    final Set<PowerType> enabled = <PowerType>{};
    if (_engine.canUseDoubleDistance(_powerState)) {
      enabled.add(PowerType.doubleDistance);
    }
    if (_engine.canUseShield(_powerState)) {
      enabled.add(PowerType.shield);
    }
    if (_engine.canUseDiceControl(_powerState)) {
      enabled.add(PowerType.diceControl);
    }
    return enabled;
  }

  Set<PowerType> get _activeHumanPowers {
    final Set<PowerType> active = <PowerType>{};
    if (_powerState.doubleDistanceArmed && _isHumanTurn) {
      active.add(PowerType.doubleDistance);
    }
    if (_isHumanTurn &&
        _state.currentPlayer.tokens.any(
          (token) => _powerState.isShielded(token.id),
        )) {
      active.add(PowerType.shield);
    }
    return active;
  }

  Map<PowerType, int> get _humanPowerCounts {
    final PowerInventory inventory =
        _powerState.inventoryFor('player_0');
    return <PowerType, int>{
      for (final PowerType type in PowerType.values)
        type: inventory.count(type),
    };
  }

  Future<void> _humanRoll() async {
    if (!_canHumanRoll) {
      return;
    }
    await _rollNormally(isComputer: false);
    _startComputerIfNeeded();
  }

  Future<void> _rollNormally({
    required bool isComputer,
  }) async {
    setState(() {
      _isRolling = true;
      _message = isComputer
          ? '${_state.currentPlayer.name} is rolling...'
          : 'Rolling...';
    });

    unawaited(_feedback.diceRoll());
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }

    final PowerLudoActionResult result =
        _engine.rollDice(_powerState);

    _applyRollResult(result, isComputer: isComputer);
    if (!isComputer) {
      _scheduleHumanSingleAutoMove();
    }
  }

  void _applyRollResult(
    PowerLudoActionResult result, {
    required bool isComputer,
    String? prefix,
  }) {
    final LudoGameEvent? diceEvent = _eventOfType(
      result.gameEvents,
      LudoGameEventType.diceRolled,
    );

    setState(() {
      _powerState = result.state;
      _isRolling = false;
      if (diceEvent?.value != null) {
        _lastDiceValue = diceEvent!.value!;
      }

      if (_state.phase == GamePhase.selectingToken) {
        _message = prefix ??
            (isComputer
                ? '${_state.currentPlayer.name} rolled $_lastDiceValue.'
                : 'You rolled $_lastDiceValue. Tap a glowing token.');
      } else if (result.powerEvents.any(
        (event) =>
            event.type == PowerGameEventType.bonusRollTriggered,
      )) {
        _message = 'Bonus Roll activated!';
      } else if (result.gameEvents.any(
        (event) => event.type == LudoGameEventType.noLegalMove,
      )) {
        _message = isComputer
            ? 'Computer has no legal move.'
            : 'No legal move.';
      } else {
        _message = prefix ?? 'Turn resolved.';
      }
    });
  }

  void _onHumanTokenTap(int tokenId) {
    if (!_isHumanTurn ||
        _isBusy ||
        _state.phase != GamePhase.selectingToken) {
      return;
    }
    _autoMoveSequence++;
    unawaited(_humanMove(tokenId));
  }

  void _scheduleHumanSingleAutoMove() {
    if (!ClassicRules.autoMoveSingleLegalToken ||
        !_isHumanTurn ||
        _state.phase != GamePhase.selectingToken ||
        _state.movableTokenIds.length != 1 ||
        _isBusy) {
      return;
    }

    final int tokenId = _state.movableTokenIds.single;
    final int sequence = ++_autoMoveSequence;

    Future<void>.delayed(
      ClassicRules.singleLegalTokenAutoMoveDelay,
      () {
        if (!mounted ||
            sequence != _autoMoveSequence ||
            !_isHumanTurn ||
            _isBusy ||
            _state.phase != GamePhase.selectingToken ||
            _state.movableTokenIds.length != 1 ||
            _state.movableTokenIds.single != tokenId) {
          return;
        }
        unawaited(_humanMove(tokenId));
      },
    );
  }

  Future<void> _humanMove(int tokenId) async {
    try {
      final PowerLudoActionResult result =
          _engine.moveToken(_powerState, tokenId);
      await _animateMove(
        result: result,
        tokenId: tokenId,
        computerReason: null,
      );
      _startComputerIfNeeded();
    } on StateError catch (error) {
      _showRuleMessage(error.message);
    }
  }

  Future<void> _humanUsePower(PowerType type) async {
    if (!_isHumanTurn || _isBusy) {
      return;
    }

    switch (type) {
      case PowerType.doubleDistance:
        try {
          final result =
              _engine.armDoubleDistance(_powerState);
          setState(() {
            _powerState = result.state;
            _message =
                'Double Distance armed. Tap a glowing token.';
          });
          unawaited(_feedback.tap());
        } on StateError catch (error) {
          _showRuleMessage(error.message);
        }
        break;

      case PowerType.shield:
        await _humanUseShield();
        break;

      case PowerType.diceControl:
        await _humanUseDiceControl();
        break;

      case PowerType.bonusRoll:
        _showRuleMessage(
          'Bonus Roll activates automatically when you land on it.',
        );
        break;
    }
  }

  Future<void> _humanUseShield() async {
    final List<LudoToken> eligible = _state.currentPlayer.tokens
        .where(
          (token) =>
              token.status == TokenStatus.active &&
              !_powerState.isShielded(token.id),
        )
        .toList(growable: false);

    if (eligible.isEmpty) {
      _showRuleMessage(
        'Move a token onto the shared track before using Shield.',
      );
      return;
    }

    final int? tokenId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: LudoGlobalColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SHIELD A TOKEN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (int index = 0;
                  index < eligible.length;
                  index++)
                ListTile(
                  leading: const Icon(
                    Icons.shield_rounded,
                    color: LudoGlobalColors.electricBlue,
                  ),
                  title: Text('Token ${index + 1}'),
                  subtitle: Text(
                    'Position ${eligible[index].pathPosition + 1}',
                  ),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(eligible[index].id),
                ),
            ],
          ),
        ),
      ),
    );

    if (tokenId == null || !mounted) {
      return;
    }

    try {
      final result = _engine.applyShield(
        _powerState,
        tokenId,
      );
      setState(() {
        _powerState = result.state;
        _message = 'Shield active on your token.';
      });
      unawaited(_feedback.home());
    } on StateError catch (error) {
      _showRuleMessage(error.message);
    }
  }

  Future<void> _humanUseDiceControl() async {
    final int? value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: LudoGlobalColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DICE CONTROL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (int face = 1; face <= 6; face++)
                    SizedBox(
                      width: 78,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(face),
                        child: Text('$face'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      _isRolling = true;
      _message = 'Controlling dice to $value...';
    });
    unawaited(_feedback.diceRoll());
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) {
      return;
    }

    try {
      final result =
          _engine.useDiceControl(_powerState, value);
      _applyRollResult(
        result,
        isComputer: false,
        prefix: 'Dice Control selected $value.',
      );
      _scheduleHumanSingleAutoMove();
      _startComputerIfNeeded();
    } on StateError catch (error) {
      setState(() => _isRolling = false);
      _showRuleMessage(error.message);
    }
  }

  void _startComputerIfNeeded() {
    if (!mounted ||
        _state.isGameOver ||
        _isHumanTurn ||
        _computerLoopRunning) {
      return;
    }
    unawaited(_runComputerLoop());
  }

  Future<void> _runComputerLoop() async {
    if (_computerLoopRunning) {
      return;
    }

    _computerLoopRunning = true;

    while (mounted && !_state.isGameOver && !_isHumanTurn) {
      final String computerName = _state.currentPlayer.name;

      if (_state.phase == GamePhase.waitingForRoll) {
        setState(() {
          _message = '$computerName is planning a Power move...';
        });

        await Future<void>.delayed(
          Duration(
            milliseconds: widget.difficulty == AiDifficulty.hard
                ? 600
                : 430,
          ),
        );

        if (!mounted || _isHumanTurn || _state.isGameOver) {
          break;
        }

        final PowerAiPreRollDecision decision =
            _ai.choosePreRollAction(
          state: _powerState,
          engine: _engine,
          difficulty: widget.difficulty,
        );

        switch (decision.type) {
          case PowerAiPreRollActionType.shield:
            final int tokenId = decision.tokenId ??
                _ai.chooseShieldToken(_powerState);
            final result =
                _engine.applyShield(_powerState, tokenId);
            setState(() {
              _powerState = result.state;
              _message = '$computerName used Shield.';
            });
            unawaited(_feedback.home());
            await Future<void>.delayed(
              const Duration(milliseconds: 330),
            );
            if (!mounted || _isHumanTurn) {
              continue;
            }
            await _rollNormally(isComputer: true);
            break;

          case PowerAiPreRollActionType.diceControl:
            final int value = decision.diceValue ?? 6;
            setState(() {
              _isRolling = true;
              _message =
                  '$computerName used Dice Control: $value.';
            });
            unawaited(_feedback.diceRoll());
            await Future<void>.delayed(
              const Duration(milliseconds: 650),
            );
            if (!mounted) {
              break;
            }
            final result =
                _engine.useDiceControl(_powerState, value);
            _applyRollResult(
              result,
              isComputer: true,
              prefix:
                  '$computerName controlled the dice to $value.',
            );
            break;

          case PowerAiPreRollActionType.normalRoll:
            await _rollNormally(isComputer: true);
            break;
        }

        if (!mounted || _state.isGameOver || _isHumanTurn) {
          continue;
        }
      }

      if (_state.phase == GamePhase.selectingToken &&
          !_isHumanTurn) {
        final PowerAiDoubleDecision doubleDecision =
            _ai.shouldUseDoubleDistance(
          state: _powerState,
          engine: _engine,
          difficulty: widget.difficulty,
        );

        if (doubleDecision.shouldUse) {
          final result =
              _engine.armDoubleDistance(_powerState);
          setState(() {
            _powerState = result.state;
            _message =
                '${_state.currentPlayer.name} used Double Distance.';
          });
          unawaited(_feedback.tap());
          await Future<void>.delayed(
            const Duration(milliseconds: 350),
          );
        }

        if (!mounted || _isHumanTurn || _state.isGameOver) {
          break;
        }

        final int tokenId = _ai.chooseMove(
          state: _powerState,
          difficulty: widget.difficulty,
        );

        final String reason = doubleDecision.shouldUse
            ? 'Double Distance'
            : 'strategic move';

        final PowerLudoActionResult result =
            _engine.moveToken(_powerState, tokenId);

        await _animateMove(
          result: result,
          tokenId: tokenId,
          computerReason: reason,
        );
      }

      if (mounted &&
          !_state.isGameOver &&
          !_isHumanTurn) {
        await Future<void>.delayed(
          const Duration(milliseconds: 330),
        );
      }
    }

    _computerLoopRunning = false;

    if (mounted && _isHumanTurn && !_state.isGameOver) {
      setState(() {
        _message = _state.phase == GamePhase.waitingForRoll
            ? 'Your Power turn. Choose a power or roll.'
            : 'Your turn. Tap a glowing token.';
      });
    }
  }

  Future<void> _animateMove({
    required PowerLudoActionResult result,
    required int tokenId,
    required String? computerReason,
  }) async {
    final LudoGameEvent moveEvent = result.gameEvents.firstWhere(
      (event) =>
          event.type == LudoGameEventType.tokenMoved ||
          event.type == LudoGameEventType.tokenReleased,
    );

    final int from = moveEvent.fromPosition ?? -1;
    final int to = moveEvent.toPosition ?? from;
    final LudoGameEvent? capture = _eventOfType(
      result.gameEvents,
      LudoGameEventType.tokenCaptured,
    );
    final bool reachedHome = result.gameEvents.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    );
    final bool won = result.gameEvents.any(
      (event) => event.type == LudoGameEventType.playerWon,
    );

    setState(() {
      _isMoving = true;
      _movingTokenId = tokenId;
    });

    for (int progress = from + 1; progress <= to; progress++) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visualPathOverrides[tokenId] = progress;
      });
      unawaited(_feedback.tokenStep());
      await Future<void>.delayed(const Duration(milliseconds: 125));
    }

    if (!mounted) {
      return;
    }

    if (capture != null) {
      setState(() {
        _capturedTokenIds = capture.otherTokenIds.toSet();
      });
      unawaited(_feedback.capture());
      await _triggerFx(GameFxType.capture, durationMs: 480);
    }

    if (capture != null) {
      if (!mounted) {
        return;
      }

      final Set<int> returning = capture.otherTokenIds.toSet();

      setState(() {
        _visualPathOverrides.remove(tokenId);
        _movingTokenId = null;
        _capturedTokenIds = const <int>{};
        _returningTokenIds = returning;
        _powerState = result.state;
      if (result.powerEvents.any(
        (event) =>
            event.type == PowerGameEventType.bonusRollTriggered,
      )) {
        _message = 'Bonus Roll activated!';
      } else if (computerReason != null) {
        _message = 'Computer used $computerReason.';
      } else if (result.gameEvents.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        _message = 'You earned another roll.';
      } else {
        _message = 'Move complete.';
      }
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 540),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _returningTokenIds = const <int>{};
        _isMoving = false;
      });
    } else {
      if (reachedHome) {
        unawaited(_feedback.home());
        await _triggerFx(GameFxType.home, durationMs: 480);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _visualPathOverrides.remove(tokenId);
        _movingTokenId = null;
        _capturedTokenIds = const <int>{};
        _powerState = result.state;
        _isMoving = false;
      if (result.powerEvents.any(
        (event) =>
            event.type == PowerGameEventType.bonusRollTriggered,
      )) {
        _message = 'Bonus Roll activated!';
      } else if (computerReason != null) {
        _message = 'Computer used $computerReason.';
      } else if (result.gameEvents.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        _message = 'You earned another roll.';
      } else {
        _message = 'Move complete.';
      }
      });
    }

    if (won) {
      unawaited(_feedback.win());
      await _triggerFx(
        GameFxType.winner,
        label: '${_winnerName(_state)} wins!',
        durationMs: 900,
      );
      if (mounted) {
        await _showWinner();
      }
    }
  }

  LudoGameEvent? _eventOfType(
    List<LudoGameEvent> events,
    LudoGameEventType type,
  ) {
    for (final LudoGameEvent event in events) {
      if (event.type == type) {
        return event;
      }
    }
    return null;
  }

  String _winnerName(LudoGameState state) {
    final String? winnerId = state.winnerPlayerId;
    if (winnerId == null) {
      return 'Player';
    }

    return state.players
        .firstWhere((player) => player.id == winnerId)
        .name;
  }

  Future<void> _triggerFx(
    GameFxType type, {
    String? label,
    int durationMs = 650,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _fxType = type;
      _fxLabel = label;
      _fxSequence++;
    });

    await Future<void>.delayed(Duration(milliseconds: durationMs));

    if (mounted) {
      setState(() {
        _fxType = null;
        _fxLabel = null;
      });
    }
  }

  void _showRuleMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showWinner() async {
    final bool humanWon = _state.winnerPlayerId == 'player_0';
    final String winner = _winnerName(_state);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MatchResultDialog(
        title: humanWon
            ? 'You win Power Ludo!'
            : '$winner wins Power Ludo',
        subtitle: humanWon
            ? 'You finished all four tokens first.'
            : 'The computer finished all four tokens first.',
        accentColor: humanWon
            ? LudoGlobalColors.gold
            : LudoGlobalColors.purple,
        icon: humanWon
            ? Icons.emoji_events_rounded
            : Icons.smart_toy_rounded,
        onPlayAgain: () {
          Navigator.of(dialogContext).pop();
          setState(_resetGame);
        },
        onBack: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmQuit() async {
    if (_isBusy) {
      return;
    }

    final bool quit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Quit match?'),
            content: const Text(
              'Your current Power match against the computer will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true),
                child: const Text('Quit'),
              ),
            ],
          ),
        ) ??
        false;

    if (quit && mounted) {
      Navigator.of(context).pop();
    }
  }

  Color _playerColor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => LudoGlobalColors.red,
      PlayerColor.green => LudoGlobalColors.green,
      PlayerColor.yellow => LudoGlobalColors.gold,
      PlayerColor.blue => LudoGlobalColors.electricBlue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final LudoPlayer current = _state.currentPlayer;
    final Color currentColor = _playerColor(current.color);

    return Scaffold(
      body: Stack(
        children: [
          GameBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    GameplayHeader(
                      title: 'POWER VS AI',
                      badge: widget.difficulty.label.toUpperCase(),
                      leadingIcon: Icons.bolt_rounded,
                      accentColor: LudoGlobalColors.gold,
                      onBack: _confirmQuit,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF061127),
                        borderRadius:
                            BorderRadius.circular(LudoGlobalRadius.large),
                        border: Border.all(
                          color: currentColor.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      child: GameBoardStage(
                        gameState: _state,
                        diceValue: _lastDiceValue,
                        diceRolling: _isRolling,
                        diceEnabled: _canHumanRoll,
                        onRoll: () => unawaited(_humanRoll()),
                        computerPlayerIds: <String>{
                          for (final player in _state.players.skip(1))
                            player.id,
                        },
                        board: LudoBoard(
                          gameState: _state,
                          activePlayerCount: _state.players.length,
                          movableTokenIds: _isHumanTurn
                              ? _state.movableTokenIds.toSet()
                              : const <int>{},
                          visualPathOverrides: _visualPathOverrides,
                          movingTokenId: _movingTokenId,
                          capturedTokenIds: _capturedTokenIds,
                          returningTokenIds: _returningTokenIds,
                          shieldedTokenIds:
                              _powerState.shields.keys.toSet(),
                          powerPickupPositions: <PowerType, int>{
                            for (final entry
                                in _powerState.pickups.entries)
                              entry.key: entry.value.globalIndex,
                          },
                          onTokenTap: _onHumanTokenTap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GameplayCallout(
                      message: _message,
                      color: currentColor,
                    ),

                    const SizedBox(height: 8),
                    PowerActionBar(
                      counts: _humanPowerCounts,
                      enabledPowers: _enabledHumanPowers,
                      activePowers: _activeHumanPowers,
                      onPowerTap: (type) =>
                          unawaited(_humanUsePower(type)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GameFxOverlay(
            type: _fxType,
            sequence: _fxSequence,
            label: _fxLabel,
          ),
        ],
      ),
    );
  }
}
