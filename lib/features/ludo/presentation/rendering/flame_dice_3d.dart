import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../widgets/animated_dice.dart';
import 'flame_dice_3d_game.dart';

class FlameDice3D extends StatefulWidget {
  const FlameDice3D({
    required this.value,
    required this.enabled,
    required this.rolling,
    required this.onTap,
    required this.size,
    required this.launchDirection,
    this.accentColor = Colors.blueAccent,
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;
  final double size;
  final Offset launchDirection;
  final Color accentColor;

  @override
  State<FlameDice3D> createState() => _FlameDice3DState();
}

class _FlameDice3DState extends State<FlameDice3D> {
  late final FlameDice3DGame _game = FlameDice3DGame(
    initialValue: widget.value,
    launchDirection: widget.launchDirection,
  );

  @override
  void didUpdateWidget(covariant FlameDice3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateRollState(
      rolling: widget.rolling,
      value: widget.value,
      launchDirection: widget.launchDirection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Roll dice',
      child: GestureDetector(
        key: const Key('roll_dice_button'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:
              widget.enabled || widget.rolling ? 1 : 0.72,
          child: SizedBox.square(
            dimension: widget.size,
            child: ClipRect(
              child: GameWidget<FlameDice3DGame>(
                game: _game,
                autofocus: false,
                errorBuilder: (context, error) {
                  return AnimatedDice(
                    value: widget.value,
                    enabled: widget.enabled,
                    rolling: widget.rolling,
                    onTap: widget.onTap,
                    accentColor: widget.accentColor,
                    size: widget.size,
                    compact: true,
                    launchDirection: widget.launchDirection,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
