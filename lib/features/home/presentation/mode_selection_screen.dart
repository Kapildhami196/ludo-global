import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../ludo/domain/entities/game_config.dart';
import '../../matchmaking/presentation/match_type_screen.dart';
import 'widgets/ludo_mode_card.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    this.initialMode,
    super.key,
  });

  final LudoGameMode? initialMode;

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
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Expanded(
                            child: Text(
                              'CHOOSE YOUR MODE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pick classic strategy or add tactical powers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LudoGlobalColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LudoModeCard(
                        title: 'NORMAL\nLUDO',
                        subtitle:
                            'Classic rules • Pure strategy • Quick matches',
                        icon: Icons.casino_rounded,
                        gradient: LudoGlobalGradients.normal,
                        onPressed: () => _openMatchType(
                          context,
                          LudoGameMode.normal,
                        ),
                      ),
                      const SizedBox(height: 18),
                      LudoModeCard(
                        title: 'POWER\nLUDO',
                        subtitle:
                            'Double • Shield • Dice Control • Bonus Roll',
                        icon: Icons.bolt_rounded,
                        gradient: LudoGlobalGradients.power,
                        onPressed: () => _openMatchType(
                          context,
                          LudoGameMode.power,
                        ),
                      ),
                      if (initialMode != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          initialMode == LudoGameMode.normal
                              ? 'Selected from Home: Normal Ludo'
                              : 'Selected from Home: Power Ludo',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: LudoGlobalColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
