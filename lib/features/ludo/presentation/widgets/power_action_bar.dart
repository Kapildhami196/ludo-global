import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/power_type.dart';
import '../../domain/power/power_rules.dart';

class PowerActionBar extends StatelessWidget {
  const PowerActionBar({
    required this.counts,
    required this.enabledPowers,
    required this.activePowers,
    required this.onPowerTap,
    super.key,
  });

  final Map<PowerType, int> counts;
  final Set<PowerType> enabledPowers;
  final Set<PowerType> activePowers;
  final ValueChanged<PowerType> onPowerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xF20C2448),
            Color(0xF205142B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LudoGlobalColors.electricBlue.withValues(alpha: 0.38),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: LudoGlobalColors.gold,
              ),
              SizedBox(width: 5),
              Text(
                'POWER INVENTORY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              Spacer(),
              Text(
                'COLLECT ON BOARD',
                style: TextStyle(
                  color: LudoGlobalColors.textSecondary,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final PowerType type in PowerRules.heldPowerTypes) ...[
                if (type != PowerRules.heldPowerTypes.first)
                  const SizedBox(width: 7),
                Expanded(
                  child: _PowerButton(
                    type: type,
                    count: counts[type] ?? 0,
                    enabled: enabledPowers.contains(type),
                    active: activePowers.contains(type),
                    onTap: () => onPowerTap(type),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.type,
    required this.count,
    required this.enabled,
    required this.active,
    required this.onTap,
  });

  final PowerType type;
  final int count;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _PowerVisual visual = _visualFor(type);
    final bool interactive = enabled && count > 0;

    return Semantics(
      button: true,
      enabled: interactive,
      label: '${visual.label} power, $count remaining',
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: interactive || active ? 1 : 0.42,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 58,
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  visual.color.withValues(
                    alpha: active ? 0.38 : 0.22,
                  ),
                  const Color(0xFF08182F),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: visual.color.withValues(
                  alpha: active ? 1 : 0.62,
                ),
                width: active ? 1.6 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: visual.color.withValues(
                    alpha: active ? 0.40 : 0.15,
                  ),
                  blurRadius: active ? 12 : 7,
                ),
                const BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            visual.lightColor,
                            visual.color,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.52),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: visual.color.withValues(alpha: 0.42),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: Icon(
                        visual.icon,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: count > 0
                              ? LudoGlobalColors.red
                              : const Color(0xFF33435A),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active ? 'ACTIVE' : visual.shortLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? visual.lightColor
                          : Colors.white,
                      fontSize: 8,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PowerVisual _visualFor(PowerType type) {
    return switch (type) {
      PowerType.doubleDistance => const _PowerVisual(
          label: 'Double Distance',
          shortLabel: 'DOUBLE\nDISTANCE',
          icon: Icons.double_arrow_rounded,
          color: LudoGlobalColors.red,
          lightColor: Color(0xFFFF7B87),
        ),
      PowerType.shield => const _PowerVisual(
          label: 'Shield',
          shortLabel: 'SHIELD',
          icon: Icons.shield_rounded,
          color: LudoGlobalColors.electricBlue,
          lightColor: Color(0xFF70E8FF),
        ),
      PowerType.diceControl => const _PowerVisual(
          label: 'Dice Control',
          shortLabel: 'DICE\nCONTROL',
          icon: Icons.casino_rounded,
          color: LudoGlobalColors.purple,
          lightColor: Color(0xFFD6A5FF),
        ),
      PowerType.bonusRoll => const _PowerVisual(
          label: 'Bonus Roll',
          shortLabel: 'BONUS',
          icon: Icons.add_rounded,
          color: LudoGlobalColors.gold,
          lightColor: Color(0xFFFFF29D),
        ),
    };
  }
}

class _PowerVisual {
  const _PowerVisual({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.lightColor,
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final Color lightColor;
}
