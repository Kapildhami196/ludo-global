import 'package:flutter/material.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_asset_picture.dart';
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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xD907142A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LudoGlobalColors.electricBlue.withValues(alpha: 0.26),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Text(
              'POWERS',
              style: TextStyle(
                color: LudoGlobalColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final PowerType type in PowerRules.heldPowerTypes) ...[
            if (type != PowerRules.heldPowerTypes.first)
              const SizedBox(width: 6),
            Expanded(
              child: _CompactPowerButton(
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
    );
  }
}

class _CompactPowerButton extends StatelessWidget {
  const _CompactPowerButton({
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

  Color get _color => switch (type) {
        PowerType.doubleDistance => LudoGlobalColors.red,
        PowerType.shield => LudoGlobalColors.electricBlue,
        PowerType.diceControl => LudoGlobalColors.purple,
        PowerType.bonusRoll => LudoGlobalColors.gold,
      };

  String get _label => switch (type) {
        PowerType.doubleDistance => 'DOUBLE',
        PowerType.shield => 'SHIELD',
        PowerType.diceControl => 'CONTROL',
        PowerType.bonusRoll => 'BONUS',
      };

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && count > 0;

    return Semantics(
      button: true,
      enabled: interactive,
      label: '$_label power, $count remaining',
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: interactive || active ? 1 : 0.40,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  _color.withValues(alpha: active ? 0.34 : 0.16),
                  const Color(0xFF07162D),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _color.withValues(alpha: active ? 0.95 : 0.44),
                width: active ? 1.4 : 0.8,
              ),
              boxShadow: <BoxShadow>[
                if (active)
                  BoxShadow(
                    color: _color.withValues(alpha: 0.34),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: GameAssetPicture.asset(
                        GameAssetPaths.powerFor(type),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: count > 0
                              ? LudoGlobalColors.red
                              : const Color(0xFF33435A),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.65),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    active ? 'ACTIVE' : _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? _color : Colors.white,
                      fontSize: 7.5,
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
}
