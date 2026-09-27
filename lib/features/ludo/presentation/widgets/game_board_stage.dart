import 'package:flutter/material.dart';

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

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: board),
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
