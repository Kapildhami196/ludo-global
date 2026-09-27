import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/power_type.dart';

class PowerPickupMarker extends StatefulWidget {
  const PowerPickupMarker({
    required this.type,
    required this.size,
    super.key,
  });

  final PowerType type;
  final double size;

  @override
  State<PowerPickupMarker> createState() => _PowerPickupMarkerState();
}

class _PowerPickupMarkerState extends State<PowerPickupMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  Color get _glowColor => switch (widget.type) {
        PowerType.doubleDistance => LudoGlobalColors.red,
        PowerType.shield => LudoGlobalColors.electricBlue,
        PowerType.diceControl => LudoGlobalColors.purple,
        PowerType.bonusRoll => LudoGlobalColors.gold,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.62, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, entranceScale, child) {
          return AnimatedBuilder(
            animation: _controller,
            child: child,
            builder: (context, child) {
              final double wave =
                  (math.sin(_controller.value * math.pi * 2) + 1) / 2;
              final double scale =
                  entranceScale * (0.96 + wave * 0.07);
              final double lift =
                  -widget.size * (0.025 + wave * 0.035);

              return Transform.translate(
                offset: Offset(0, lift),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: entranceScale.clamp(0.0, 1.0).toDouble(),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: widget.size * (0.82 + wave * 0.32),
                          height: widget.size * (0.82 + wave * 0.32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _glowColor.withValues(
                                  alpha: 0.22 + wave * 0.28,
                                ),
                                blurRadius:
                                    widget.size * (0.30 + wave * 0.38),
                                spreadRadius: wave * widget.size * 0.035,
                              ),
                            ],
                          ),
                        ),
                        child!,
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _glowColor.withValues(alpha: 0.58),
                blurRadius: widget.size * 0.44,
                spreadRadius: widget.size * 0.02,
              ),
              BoxShadow(
                color: const Color(0x99000000),
                blurRadius: widget.size * 0.20,
                offset: Offset(0, widget.size * 0.10),
              ),
            ],
          ),
          child: SvgPicture.asset(
            GameAssetPaths.powerFor(widget.type),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
