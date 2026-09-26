import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/power_type.dart';

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(LudoGlobalRadius.medium),
        border: Border.all(
          color: LudoGlobalColors.purple.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: LudoGlobalColors.purple.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 17,
                color: LudoGlobalColors.gold,
              ),
              SizedBox(width: 6),
              Text(
                'POWER LUDO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Spacer(),
              Text(
                'ONE CHARGE EACH',
                style: TextStyle(
                  color: LudoGlobalColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final PowerType type in PowerType.values) ...[
                if (type != PowerType.values.first)
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: active
                ? visual.color.withValues(alpha: 0.28)
                : visual.color.withValues(
                    alpha: interactive ? 0.16 : 0.06,
                  ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active
                  ? visual.color
                  : visual.color.withValues(
                      alpha: interactive ? 0.65 : 0.18,
                    ),
              width: active ? 1.6 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: visual.color.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: interactive || active ? 1 : 0.42,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      visual.icon,
                      color: visual.color,
                      size: 25,
                    ),
                    Positioned(
                      right: -8,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xE6031024),
                          shape: BoxShape.circle,
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
                const SizedBox(height: 5),
                Text(
                  active ? 'ACTIVE' : visual.shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? visual.color
                        : LudoGlobalColors.textPrimary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
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
          shortLabel: 'DOUBLE',
          icon: Icons.double_arrow_rounded,
          color: LudoGlobalColors.red,
        ),
      PowerType.shield => const _PowerVisual(
          label: 'Shield',
          shortLabel: 'SHIELD',
          icon: Icons.shield_rounded,
          color: LudoGlobalColors.electricBlue,
        ),
      PowerType.diceControl => const _PowerVisual(
          label: 'Dice Control',
          shortLabel: 'CONTROL',
          icon: Icons.gps_fixed_rounded,
          color: LudoGlobalColors.purple,
        ),
      PowerType.bonusRoll => const _PowerVisual(
          label: 'Bonus Roll',
          shortLabel: 'BONUS',
          icon: Icons.casino_rounded,
          color: LudoGlobalColors.gold,
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
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
}
