import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1700), _openHome);
  }

  void _openHome() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.78, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: const _GameLogo(),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Classic strategy. Powerful twists.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LudoGlobalColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 8,
                    backgroundColor: Color(0x3326D9FF),
                    valueColor: AlwaysStoppedAnimation(
                      LudoGlobalColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Loading the board...',
                  style: TextStyle(
                    color: LudoGlobalColors.textSecondary,
                    fontSize: 12,
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

class _GameLogo extends StatelessWidget {
  const _GameLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LudoGlobalGradients.normal,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: LudoGlobalColors.electricBlue.withValues(alpha: 0.55),
                blurRadius: 34,
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.casino_rounded,
                size: 68,
                color: Colors.white,
              ),
              Positioned(
                top: 4,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: LudoGlobalColors.gold,
                  size: 42,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ShaderMask(
          shaderCallback: (bounds) {
            return LudoGlobalGradients.gold.createShader(bounds);
          },
          child: const Text(
            'LUDO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 54,
              height: 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'GLOBAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}
