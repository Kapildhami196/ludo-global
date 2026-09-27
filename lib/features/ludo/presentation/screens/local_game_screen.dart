import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/audio/game_audio_service.dart';
import '../../../../core/settings/game_preferences.dart';
import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/engine/ludo_game_engine.dart';
import '../../domain/entities/game_config.dart';
import '../../domain/entities/game_phase.dart';
import '../../domain/entities/ludo_game_action_result.dart';
import '../../domain/entities/ludo_game_event.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/player_color.dart';
import '../../domain/rules/classic_rules.dart';
import '../services/game_feedback_service.dart';
import '../widgets/game_board_stage.dart';
import '../widgets/game_fx_overlay.dart';
import '../widgets/gameplay_callout.dart';
import '../widgets/gameplay_header.dart';
import '../widgets/ludo_board.dart';
import '../widgets/match_result_dialog.dart';

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({
    required this.mode,
    required this.playerNames,
    super.key,
  });

  final LudoGameMode mode;
  final List<String> playerNames;

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final LudoGameEngine _engine = LudoGameEngine();
  final Map<int, int> _visualPathOverrides = <int, int>{};

  late LudoGameState _state;

  int _lastDiceValue = 1;
  int _fxSequence = 0;
  int _autoMoveSequence = 0;
  int? _movingTokenId;
  Set<int> _capturedTokenIds = const <int>{};
  Set<int> _returningTokenIds = const <int>{};
  GameFxType? _fxType;

  bool _isRolling = false;
  bool _isMoving = false;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  String _message = '';

  GameFeedbackService get _feedback => GameFeedbackService(
        soundEnabled: _soundEnabled,
        hapticsEnabled: _hapticsEnabled,
      );

  bool get _isBusy => _isRolling || _isMoving;

  @override
  void initState() {
    super.initState();
    _resetGame();
    unawaited(GameAudioService.instance.preload());
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final settings = await GamePreferences.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _soundEnabled = settings.soundEnabled;
      _hapticsEnabled = settings.hapticsEnabled;
    });
  }

  void _resetGame() {
    _state = _engine.createGame(
      config: LudoGameConfig(
        mode: widget.mode,
        matchType: LudoMatchType.localPassAndPlay,
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
    _isRolling = false;
    _isMoving = false;
    _visualPathOverrides.clear();
    _message = '${_state.currentPlayer.name}, roll the dice.';
  }

  Future<void> _rollDice() async {
    if (_isBusy ||
        _state.phase != GamePhase.waitingForRoll ||
        _state.isGameOver) {
      return;
    }

    _autoMoveSequence++;

    setState(() {
      _isRolling = true;
      _message = 'Rolling...';
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
      _message = _messageForRoll(result);
    });

    _scheduleSingleLegalAutoMove();
  }

  void _onTokenTap(int tokenId) {
    if (_isBusy ||
        _state.phase != GamePhase.selectingToken) {
      return;
    }

    _autoMoveSequence++;
    unawaited(_moveToken(tokenId));
  }

  void _scheduleSingleLegalAutoMove() {
    if (!ClassicRules.autoMoveSingleLegalToken ||
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
            _isBusy ||
            _state.phase != GamePhase.selectingToken ||
            _state.movableTokenIds.length != 1 ||
            _state.movableTokenIds.single != tokenId) {
          return;
        }

        unawaited(_moveToken(tokenId));
      },
    );
  }

  Future<void> _moveToken(int tokenId) async {
    final LudoGameActionResult result =
        _engine.moveToken(_state, tokenId);

    final LudoGameEvent moveEvent = result.events.firstWhere(
      (event) =>
          event.type == LudoGameEventType.tokenMoved ||
          event.type == LudoGameEventType.tokenReleased,
    );

    final int from = moveEvent.fromPosition ?? -1;
    final int to = moveEvent.toPosition ?? from;

    final LudoGameEvent? captureEvent = _eventOfType(
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
      _message = 'Moving token...';
    });

    for (int progress = from + 1; progress <= to; progress++) {
      if (!mounted) {
        return;
      }

      setState(() {
        _visualPathOverrides[tokenId] = progress;
      });

      if (moveEvent.type == LudoGameEventType.tokenReleased &&
          progress == to) {
        unawaited(_feedback.pawnRelease());
      } else {
        unawaited(_feedback.tokenStep());
      }
      await Future<void>.delayed(const Duration(milliseconds: 125));
    }

    if (!mounted) {
      return;
    }

    if (captureEvent != null) {
      setState(() {
        _capturedTokenIds = captureEvent.otherTokenIds.toSet();
      });

      unawaited(_feedback.capture());
      await _triggerFx(GameFxType.capture, durationMs: 520);
    }

    if (captureEvent != null) {
      if (!mounted) {
        return;
      }

      final Set<int> returning =
          captureEvent.otherTokenIds.toSet();

      unawaited(_feedback.returnHome());

      setState(() {
        _visualPathOverrides.remove(tokenId);
        _capturedTokenIds = const <int>{};
        _returningTokenIds = returning;
        _movingTokenId = null;
        _state = result.state;
        _message = _messageForMove(result);
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
        await _triggerFx(GameFxType.home, durationMs: 520);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _visualPathOverrides.remove(tokenId);
        _capturedTokenIds = const <int>{};
        _movingTokenId = null;
        _state = result.state;
        _isMoving = false;
        _message = _messageForMove(result);
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
      return;
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
      _fxSequence++;
      _fxLabel = label;
    });

    await Future<void>.delayed(Duration(milliseconds: durationMs));

    if (!mounted) {
      return;
    }

    setState(() {
      _fxType = null;
      _fxLabel = null;
    });
  }

  String? _fxLabel;

  String _messageForRoll(LudoGameActionResult result) {
    if (result.events.any(
      (event) =>
          event.type == LudoGameEventType.threeSixesForfeit,
    )) {
      return 'Three consecutive sixes — turn forfeited.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.noLegalMove,
    )) {
      if (result.events.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        return 'No legal move. Roll again.';
      }
      return '${_state.currentPlayer.name}, roll the dice.';
    }

    return 'Rolled $_lastDiceValue. Tap a glowing token.';
  }

  String _messageForMove(LudoGameActionResult result) {
    if (result.events.any(
      (event) => event.type == LudoGameEventType.playerWon,
    )) {
      return '${_winnerName(result.state)} wins!';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenCaptured,
    )) {
      return 'Capture! Extra roll awarded.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    )) {
      if (result.events.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        return 'Token reached home. Roll again.';
      }
      return 'Token reached home.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.extraTurn,
    )) {
      return '${result.state.currentPlayer.name}, roll again.';
    }

    return '${result.state.currentPlayer.name}, roll the dice.';
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

  Future<void> _showWinner() async {
    final String winner = _winnerName(_state);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MatchResultDialog(
        title: '$winner wins!',
        subtitle: 'All four tokens reached the center.',
        accentColor: LudoGlobalColors.gold,
        icon: Icons.emoji_events_rounded,
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

  Future<void> _openGameMenu() async {
    if (_isBusy) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LudoGlobalColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME MENU',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _soundEnabled,
                      secondary: const Icon(Icons.volume_up_rounded),
                      title: const Text('Sound'),
                      onChanged: (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                        unawaited(
                          GamePreferences.setSoundEnabled(value),
                        );
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _hapticsEnabled,
                      secondary: const Icon(Icons.vibration_rounded),
                      title: const Text('Haptics'),
                      onChanged: (value) {
                        setState(() {
                          _hapticsEnabled = value;
                        });
                        unawaited(
                          GamePreferences.setHapticsEnabled(value),
                        );
                        setSheetState(() {});
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('Restart Match'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _confirmRestart();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.exit_to_app_rounded,
                        color: LudoGlobalColors.red,
                      ),
                      title: const Text(
                        'Quit Match',
                        style: TextStyle(
                          color: LudoGlobalColors.red,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _confirmQuit();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRestart() async {
    final bool restart = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Restart match?'),
              content: const Text(
                'All current token positions will be reset.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  child: const Text('Restart'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (restart && mounted) {
      unawaited(_feedback.tap());
      setState(_resetGame);
    }
  }

  Future<void> _confirmQuit() async {
    if (_isBusy) {
      return;
    }

    final bool quit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Quit match?'),
              content: const Text(
                'Your current local match progress will be lost.',
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
            );
          },
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

    final bool canRoll = !_isBusy &&
        _state.phase == GamePhase.waitingForRoll &&
        !_state.isGameOver;

    return Scaffold(
      body: Stack(
        children: [
          GameBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            (LudoGlobalSpacing.sm * 2),
                      ),
                      child: Column(
                        children: [
                          GameplayHeader(
                            title: widget.mode == LudoGameMode.normal
                                ? 'NORMAL LUDO'
                                : 'POWER LUDO',
                            badge: 'LOCAL',
                            accentColor: currentColor,
                            onBack: _confirmQuit,
                            onMenu: _openGameMenu,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF061127),
                              borderRadius: BorderRadius.circular(
                                LudoGlobalRadius.large,
                              ),
                              border: Border.all(
                                color:
                                    currentColor.withValues(alpha: 0.75),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: currentColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: GameBoardStage(
                              gameState: _state,
                              diceValue: _lastDiceValue,
                              diceRolling: _isRolling,
                              diceEnabled: canRoll,
                              onRoll: () => unawaited(_rollDice()),
                              board: LudoBoard(
                                gameState: _state,
                                activePlayerCount: _state.players.length,
                                movableTokenIds:
                                    _state.movableTokenIds.toSet(),
                                visualPathOverrides:
                                    _visualPathOverrides,
                                movingTokenId: _movingTokenId,
                                capturedTokenIds: _capturedTokenIds,
                                returningTokenIds: _returningTokenIds,
                                onTokenTap: _onTokenTap,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GameplayCallout(
                            message: _message,
                            color: currentColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

