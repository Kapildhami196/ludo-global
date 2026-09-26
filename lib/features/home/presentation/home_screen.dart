import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../ludo/domain/entities/game_config.dart';
import '../../matchmaking/presentation/match_type_screen.dart';
import 'widgets/ludo_mode_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMatchType(
    BuildContext context,
    LudoGameMode mode,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchTypeScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(LudoGlobalSpacing.md),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (LudoGlobalSpacing.md * 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const _HomeLogo(),
                      const SizedBox(height: 30),
                      LudoModeCard(
                        title: 'NORMAL\nLUDO',
                        subtitle: 'Classic Game',
                        icon: Icons.casino_rounded,
                        gradient: LudoGlobalGradients.normal,
                        onPressed: () => _openMatchType(
                          context,
                          LudoGameMode.normal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LudoModeCard(
                        title: 'POWER\nLUDO',
                        subtitle: 'Play With Powers',
                        icon: Icons.bolt_rounded,
                        gradient: LudoGlobalGradients.power,
                        onPressed: () => _openMatchType(
                          context,
                          LudoGameMode.power,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LudoGlobalGradients.normal,
              boxShadow: [
                BoxShadow(
                  color: LudoGlobalColors.electricBlue.withValues(
                    alpha: 0.45,
                  ),
                  blurRadius: 26,
                ),
              ],
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.casino_rounded,
                  size: 46,
                  color: Colors.white,
                ),
                Positioned(
                  top: -2,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 29,
                    color: LudoGlobalColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: LudoGlobalGradients.gold.createShader,
            child: const Text(
              'LUDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: 1,
              ),
            ),
          ),
          const Text(
            'GLOBAL',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}
