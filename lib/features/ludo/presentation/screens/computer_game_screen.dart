import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/ai/ai_difficulty.dart';
import '../../domain/ai/ai_move_decision.dart';
import '../../domain/ai/ludo_ai_strategy.dart';
import '../../domain/engine/ludo_game_engine.dart';
import '../../domain/entities/game_config.dart';
import '../../domain/entities/game_phase.dart';
import '../../domain/entities/ludo_game_action_result.dart';
import '../../domain/entities/ludo_game_event.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/player_color.dart';
import '../services/game_feedback_service.dart';
import '../widgets/animated_dice.dart';
import '../widgets/game_fx_overlay.dart';
import '../widgets/ludo_board.dart';

class ComputerGameScreen extends StatefulWidget {
  const ComputerGameScreen({
    required this.playerNames,
    required this.difficulty,
    super.key,
  });

  final List<String> playerNames;
  final AiDifficulty difficulty;

  @override
  State<ComputerGameScreen> createState() => _ComputerGameScreenState();
}

class _ComputerGameScreenState extends State<ComputerGameScreen> {
  final LudoGameEngine _engine = LudoGameEngine();
  final LudoAiStrategy _ai = LudoAiStrategy();
  final Map<int, int> _visualPathOverrides = <int, int>{};

  late LudoGameState _state;

  int _lastDiceValue = 1;
  int _fxSequence = 0;
  int? _movingTokenId;
  Set<int> _capturedTokenIds = const <int>{};
  GameFxType? _fxType;
  String? _fxLabel;

  bool _isRolling = false;
  bool _isMoving = false;
  bool _computerLoopRunning = false;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  String _message = '';

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
    _state = _engine.createGame(
      config: LudoGameConfig(
        mode: LudoGameMode.normal,
        matchType: LudoMatchType.computer,
        playerCount: widget.playerNames.length,
      ),
      playerNames: widget.playerNames,
    );
    _lastDiceValue = 1;
    _fxSequence = 0;
    _movingTokenId = null;
    _capturedTokenIds = const <int>{};
    _fxType = null;
    _fxLabel = null;
    _isRolling = false;
    _isMoving = false;
    _computerLoopRunning = false;
    _visualPathOverrides.clear();
    _message = 'Your turn. Roll the dice.';
  }

  Future<void> _humanRoll() async {
    if (!_isHumanTurn ||
        _isBusy ||
        _state.phase != GamePhase.waitingForRoll ||
        _state.isGameOver) {
      return;
    }

    await _performRoll(isComputer: false);
    _startComputerIfNeeded();
  }

  void _onHumanTokenTap(int tokenId) {
    if (!_isHumanTurn ||
        _isBusy ||
        _state.phase != GamePhase.selectingToken) {
      return;
    }

    unawaited(_humanMove(tokenId));
  }

  Future<void> _humanMove(int tokenId) async {
    final LudoGameActionResult result =
        _engine.moveToken(_state, tokenId);
    await _animateMove(
      result: result,
      tokenId: tokenId,
      computerReason: null,
    );
    _startComputerIfNeeded();
  }

  Future<void> _performRoll({
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

    final LudoGameActionResult result = _engine.rollDice(_state);
    final LudoGameEvent diceEvent = result.events.firstWhere(
      (event) => event.type == LudoGameEventType.diceRolled,
    );

    setState(() {
      _lastDiceValue = diceEvent.value ?? 1;
      _state = result.state;
      _isRolling = false;
      _message = _messageForRoll(result, isComputer: isComputer);
    });
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
          _message = '$computerName is thinking...';
        });

        await Future<void>.delayed(
          Duration(
            milliseconds: widget.difficulty == AiDifficulty.hard
                ? 520
                : 400,
          ),
        );

        if (!mounted || _isHumanTurn || _state.isGameOver) {
          break;
        }

        await _performRoll(isComputer: true);

        if (!mounted || _state.isGameOver || _isHumanTurn) {
          continue;
        }
      }

      if (_state.phase == GamePhase.selectingToken &&
          !_isHumanTurn) {
        final AiMoveDecision decision = _ai.chooseMove(
          state: _state,
          engine: _engine,
          difficulty: widget.difficulty,
        );

        setState(() {
          _message = '$computerName chose: ${decision.reason}.';
        });

        await Future<void>.delayed(
          Duration(
            milliseconds: widget.difficulty == AiDifficulty.easy
                ? 360
                : 520,
          ),
        );

        if (!mounted || _isHumanTurn || _state.isGameOver) {
          break;
        }

        final LudoGameActionResult result =
            _engine.moveToken(_state, decision.tokenId);

        await _animateMove(
          result: result,
          tokenId: decision.tokenId,
          computerReason: decision.reason,
        );
      }

      if (mounted &&
          !_state.isGameOver &&
          !_isHumanTurn) {
        await Future<void>.delayed(
          const Duration(milliseconds: 320),
        );
      }
    }

    _computerLoopRunning = false;

    if (mounted && _isHumanTurn && !_state.isGameOver) {
      setState(() {
        if (_state.phase == GamePhase.waitingForRoll) {
          _message = 'Your turn. Roll the dice.';
        } else {
          _message = 'Your turn. Tap a glowing token.';
        }
      });
    }
  }

  Future<void> _animateMove({
    required LudoGameActionResult result,
    required int tokenId,
    required String? computerReason,
  }) async {
    final LudoGameEvent moveEvent = result.events.firstWhere(
      (event) =>
          event.type == LudoGameEventType.tokenMoved ||
          event.type == LudoGameEventType.tokenReleased,
    );

    final int from = moveEvent.fromPosition ?? -1;
    final int to = moveEvent.toPosition ?? from;
    final LudoGameEvent? capture = _eventOfType(
      result.events,
      LudoGameEventType.tokenCaptured,
    );
    final bool reachedHome = result.events.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    );
    final bool won = result.events.any(
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
      await Future<void>.delayed(const Duration(milliseconds: 145));
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
      _state = result.state;
      _isMoving = false;
      _message = _messageForMove(
        result,
        computerReason: computerReason,
      );
    });

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

  String _messageForRoll(
    LudoGameActionResult result, {
    required bool isComputer,
  }) {
    final String actor = isComputer
        ? result.events.first.playerId == 'player_0'
            ? widget.playerNames.first
            : _nameForPlayerId(result.events.first.playerId)
        : 'You';

    if (result.events.any(
      (event) =>
          event.type == LudoGameEventType.threeSixesForfeit,
    )) {
      return '$actor rolled three sixes and lost the turn.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.noLegalMove,
    )) {
      return '$actor rolled $_lastDiceValue but has no legal move.';
    }

    return isComputer
        ? '$actor rolled $_lastDiceValue.'
        : 'You rolled $_lastDiceValue. Tap a glowing token.';
  }

  String _messageForMove(
    LudoGameActionResult result, {
    String? computerReason,
  }) {
    if (result.events.any(
      (event) => event.type == LudoGameEventType.playerWon,
    )) {
      return '${_winnerName(result.state)} wins!';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenCaptured,
    )) {
      return 'Capture! Another roll is awarded.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    )) {
      return 'A token reached home.';
    }

    if (computerReason != null) {
      return 'Computer move: $computerReason.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.extraTurn,
    )) {
      return 'You earned another roll.';
    }

    return _isHumanTurn
        ? 'Your turn.'
        : '${result.state.currentPlayer.name} is next.';
  }

  String _nameForPlayerId(String? playerId) {
    if (playerId == null) {
      return 'Computer';
    }
    for (final LudoPlayer player in _state.players) {
      if (player.id == playerId) {
        return player.name;
      }
    }
    return 'Computer';
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

  Future<void> _showWinner() async {
    final String winner = _winnerName(_state);
    final bool humanWon = _state.winnerPlayerId == 'player_0';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: LudoGlobalColors.surface,
          icon: Icon(
            humanWon
                ? Icons.emoji_events_rounded
                : Icons.smart_toy_rounded,
            size: 62,
            color: humanWon
                ? LudoGlobalColors.gold
                : LudoGlobalColors.purple,
          ),
          title: Text(
            humanWon ? 'You win!' : '$winner wins',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            humanWon
                ? 'Great match against the computer.'
                : 'Try again or change the AI difficulty.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(_resetGame);
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
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
              'Your current match against the computer will be lost.',
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
    final bool canHumanRoll = _isHumanTurn &&
        !_isBusy &&
        _state.phase == GamePhase.waitingForRoll &&
        !_state.isGameOver;

    return Scaffold(
      body: Stack(
        children: [
          GameBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LudoGlobalSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _confirmQuit,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'VS COMPUTER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: LudoGlobalColors.purple
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.difficulty.label.toUpperCase(),
                            style: const TextStyle(
                              color: LudoGlobalColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LudoGlobalColors.surface
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentColor.withValues(alpha: 0.72),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: currentColor,
                            child: Icon(
                              _isHumanTurn
                                  ? Icons.person_rounded
                                  : Icons.smart_toy_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  _isHumanTurn
                                      ? 'YOUR TURN'
                                      : 'COMPUTER TURN',
                                  style: const TextStyle(
                                    color:
                                        LudoGlobalColors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isHumanTurn &&
                              (_computerLoopRunning || _isBusy))
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF061127),
                        borderRadius:
                            BorderRadius.circular(LudoGlobalRadius.large),
                        border: Border.all(
                          color: currentColor.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      child: LudoBoard(
                        gameState: _state,
                        activePlayerCount: _state.players.length,
                        movableTokenIds: _isHumanTurn
                            ? _state.movableTokenIds.toSet()
                            : const <int>{},
                        visualPathOverrides: _visualPathOverrides,
                        movingTokenId: _movingTokenId,
                        capturedTokenIds: _capturedTokenIds,
                        onTokenTap: _onHumanTokenTap,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: currentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedDice(
                      value: _lastDiceValue,
                      enabled: canHumanRoll,
                      rolling: _isRolling,
                      onTap: () => unawaited(_humanRoll()),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isHumanTurn
                          ? 'Tap the dice when it is your turn.'
                          : 'Computer moves automatically.',
                      style: const TextStyle(
                        color: LudoGlobalColors.textSecondary,
                        fontSize: 10,
                      ),
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
