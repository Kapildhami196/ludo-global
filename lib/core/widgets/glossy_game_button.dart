import 'package:flutter/material.dart';

import '../theme/ludo_global_tokens.dart';

class GlossyGameButton extends StatelessWidget {
  const GlossyGameButton({
    required this.label,
    required this.onPressed,
    this.gradient = LudoGlobalGradients.normal,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: onPressed == null ? 0.5 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(LudoGlobalRadius.medium),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Color(0x99000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
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
