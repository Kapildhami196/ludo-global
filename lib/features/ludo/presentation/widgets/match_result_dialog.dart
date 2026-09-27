import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';

class MatchResultDialog extends StatelessWidget {
  const MatchResultDialog({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.onPlayAgain,
    required this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF10264A),
              Color(0xFF07152D),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.78),
            width: 1.5,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accentColor.withValues(alpha: 0.28),
              blurRadius: 34,
              spreadRadius: 3,
            ),
            const BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    accentColor.withValues(alpha: 0.38),
                    accentColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 54,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LudoGlobalColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play Again'),
              ),
            ),
            TextButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
