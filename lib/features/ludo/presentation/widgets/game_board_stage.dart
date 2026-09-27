import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/player_color.dart';
import 'player_dice_slot.dart';

class GameBoardStage extends StatelessWidget {
  const GameBoardStage({
    required this.gameState,
    required this.board,
    required this.diceValue,
    required this.diceRolling,
    required this.diceEnabled,
    required this.onRoll,
    super.key,
  });

  final LudoGameState gameState;
  final Widget board;
  final int diceValue;
  final bool diceRolling;
  final bool diceEnabled;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = constraints.maxWidth;
          final double diceSize = (size / 15) * 1.70;

          final Color activeColor =
              _colorFor(gameState.currentPlayer.color);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, size * 0.018),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.035),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0xB0000612),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.035),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: diceRolling ? 0.34 : 0.17,
                        ),
                        blurRadius: diceRolling ? 30 : 18,
                        spreadRadius: diceRolling ? 3 : 1,
                      ),
                    ],
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: diceRolling ? 0.996 : 1,
                    child: board,
                  ),
                ),
              ),
              for (final player in gameState.players)
                _dicePosition(
                  color: player.color,
                  size: size,
                  child: PlayerDiceSlot(
                    color: player.color,
                    active: player.id == gameState.currentPlayer.id,
                    value: diceValue,
                    rolling: player.id == gameState.currentPlayer.id &&
                        diceRolling,
                    enabled: player.id == gameState.currentPlayer.id &&
                        diceEnabled,
                    onRoll: onRoll,
                    size: diceSize,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _colorFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => LudoGlobalColors.red,
      PlayerColor.green => LudoGlobalColors.green,
      PlayerColor.yellow => LudoGlobalColors.gold,
      PlayerColor.blue => LudoGlobalColors.electricBlue,
    };
  }

  Widget _dicePosition({
    required PlayerColor color,
    required double size,
    required Widget child,
  }) {
    final double inset = size * 0.018;

    return switch (color) {
      PlayerColor.red => Positioned(
          left: inset,
          top: inset,
          child: child,
        ),
      PlayerColor.green => Positioned(
          right: inset,
          top: inset,
          child: child,
        ),
      PlayerColor.yellow => Positioned(
          right: inset,
          bottom: inset,
          child: child,
        ),
      PlayerColor.blue => Positioned(
          left: inset,
          bottom: inset,
          child: child,
        ),
    };
  }
}
