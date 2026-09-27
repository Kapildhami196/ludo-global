import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';

class GameplayHeader extends StatelessWidget {
  const GameplayHeader({
    required this.title,
    required this.onBack,
    this.onMenu,
    this.leadingIcon,
    this.badge,
    this.accentColor = LudoGlobalColors.electricBlue,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMenu;
  final IconData? leadingIcon;
  final String? badge;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          _RoundHudButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 7),
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              color: accentColor,
              size: 18,
            ),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.35,
                ),
              ),
            ),
          if (onMenu != null) ...[
            const SizedBox(width: 6),
            _RoundHudButton(
              key: const Key('game_menu_button'),
              icon: Icons.more_vert_rounded,
              onTap: onMenu!,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundHudButton extends StatelessWidget {
  const _RoundHudButton({
    required this.icon,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xD90A1931),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 19,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
