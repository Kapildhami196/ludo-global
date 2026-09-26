import 'dart:async';

import 'package:flutter/material.dart';

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
import '../widgets/ludo_board.dart';

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
  bool _isAnimating = false;
  String _message = 'Roll the dice to begin.';

  @override
  void initState() {
    super.initState();
    _resetGame();
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
    _isAnimating = false;
    _visualPathOverrides.clear();
    _message = '${_state.currentPlayer.name}, roll the dice.';
  }

  void _rollDice() {
    if (_isAnimating ||
        _state.phase != GamePhase.waitingForRoll ||
        _state.isGameOver) {
      return;
    }

    final LudoGameActionResult result = _engine.rollDice(_state);
    final LudoGameEvent diceEvent = result.events.firstWhere(
      (event) => event.type == LudoGameEventType.diceRolled,
    );

    setState(() {
      _lastDiceValue = diceEvent.value ?? 1;
      _state = result.state;
      _message = _messageForRoll(result);
    });
  }

  void _onTokenTap(int tokenId) {
    if (_isAnimating || _state.phase != GamePhase.selectingToken) {
      return;
    }
    unawaited(_moveToken(tokenId));
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

    setState(() {
      _isAnimating = true;
      _message = 'Moving token...';
    });

    for (int progress = from + 1; progress <= to; progress++) {
      if (!mounted) {
        return;
      }

      setState(() {
        _visualPathOverrides[tokenId] = progress;
      });
      await Future<void>.delayed(
        const Duration(milliseconds: 145),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _visualPathOverrides.remove(tokenId);
      _state = result.state;
      _isAnimating = false;
      _message = _messageForMove(result);
    });

    if (_state.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWinner();
        }
      });
    }
  }

  String _messageForRoll(LudoGameActionResult result) {
    if (result.events.any(
      (event) =>
          event.type == LudoGameEventType.threeSixesForfeit,
    )) {
      return 'Three consecutive sixes — turn forfeited. '
          'Pass to ${result.state.currentPlayer.name}.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.noLegalMove,
    )) {
      if (result.events.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        return 'No legal move. Roll again.';
      }
      return 'No legal move. Pass to '
          '${result.state.currentPlayer.name}.';
    }

    return 'Rolled $_lastDiceValue. Tap a glowing token.';
  }

  String _messageForMove(LudoGameActionResult result) {
    if (result.events.any(
      (event) => event.type == LudoGameEventType.playerWon,
    )) {
      final String winner = _winnerName(result.state);
      return '$winner wins!';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenCaptured,
    )) {
      return 'Captured! ${result.state.currentPlayer.name} '
          'gets another roll.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.tokenFinished,
    )) {
      if (result.events.any(
        (event) => event.type == LudoGameEventType.extraTurn,
      )) {
        return 'Token reached home. Roll again.';
      }
      return 'Token reached home. Pass to '
          '${result.state.currentPlayer.name}.';
    }

    if (result.events.any(
      (event) => event.type == LudoGameEventType.extraTurn,
    )) {
      return '${result.state.currentPlayer.name}, roll again.';
    }

    return 'Pass to ${result.state.currentPlayer.name}.';
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
      builder: (context) {
        return AlertDialog(
          backgroundColor: LudoGlobalColors.surface,
          icon: const Icon(
            Icons.emoji_events_rounded,
            size: 58,
            color: LudoGlobalColors.gold,
          ),
          title: Text(
            '$winner wins!',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'All four tokens reached the center.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(_resetGame);
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
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
    final bool canRoll = !_isAnimating &&
        _state.phase == GamePhase.waitingForRoll &&
        !_state.isGameOver;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(LudoGlobalSpacing.sm),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (LudoGlobalSpacing.sm * 2),
                  ),
                  child: Column(
                    children: [
                      _GameHeader(
                        mode: widget.mode,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 8),
                      _TurnCard(
                        player: current,
                        color: currentColor,
                        consecutiveSixes: _state.consecutiveSixes,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061127),
                          borderRadius: BorderRadius.circular(
                            LudoGlobalRadius.large,
                          ),
                          border: Border.all(
                            color: currentColor.withValues(alpha: 0.75),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  currentColor.withValues(alpha: 0.18),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: LudoBoard(
                          gameState: _state,
                          activePlayerCount: _state.players.length,
                          movableTokenIds:
                              _state.movableTokenIds.toSet(),
                          visualPathOverrides:
                              _visualPathOverrides,
                          onTokenTap: _onTokenTap,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusBanner(
                        message: _message,
                        color: currentColor,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SmallControl(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Chat',
                            onTap: () {},
                          ),
                          const SizedBox(width: 18),
                          _DiceButton(
                            value: _lastDiceValue,
                            enabled: canRoll,
                            onTap: _rollDice,
                          ),
                          const SizedBox(width: 18),
                          _SmallControl(
                            icon: Icons.emoji_emotions_rounded,
                            label: 'Emotes',
                            onTap: () {},
                          ),
                        ],
                      ),
                      if (widget.mode == LudoGameMode.power) ...[
                        const SizedBox(height: 12),
                        const _PowerComingNext(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.mode,
    required this.onBack,
  });

  final LudoGameMode mode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            mode == LudoGameMode.normal
                ? 'NORMAL LUDO'
                : 'POWER LUDO',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Text(
          'LOCAL',
          style: TextStyle(
            color: LudoGlobalColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    required this.player,
    required this.color,
    required this.consecutiveSixes,
  });

  final LudoPlayer player;
  final Color color;
  final int consecutiveSixes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(
          LudoGlobalRadius.medium,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'YOUR TURN',
                  style: TextStyle(
                    color: LudoGlobalColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (consecutiveSixes > 0)
            Text(
              '6 × $consecutiveSixes',
              style: const TextStyle(
                color: LudoGlobalColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  const _DiceButton({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool enabled;
  final VoidCallback onTap;

  static const List<String> _faces = <String>[
    '⚀',
    '⚁',
    '⚂',
    '⚃',
    '⚄',
    '⚅',
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Roll dice',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: enabled ? 1 : 0.92,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: enabled ? 1 : 0.5,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LudoGlobalGradients.normal,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LudoGlobalColors.electricBlue
                        .withValues(alpha: enabled ? 0.42 : 0.1),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _faces[(value - 1).clamp(0, 5)],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 49,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallControl extends StatelessWidget {
  const _SmallControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 54,
        decoration: BoxDecoration(
          color: LudoGlobalColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: LudoGlobalColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: LudoGlobalColors.cyan,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerComingNext extends StatelessWidget {
  const _PowerComingNext();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LudoGlobalColors.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LudoGlobalColors.purple.withValues(alpha: 0.45),
        ),
      ),
      child: const Text(
        '⚡ Power controls use this same Normal Ludo engine and '
        'will be enabled in the Power phase.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: LudoGlobalColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
