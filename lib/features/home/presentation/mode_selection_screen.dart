import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../ludo/domain/entities/game_config.dart';
import 'widgets/ludo_mode_card.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    this.initialMode,
    super.key,
  });

  final LudoGameMode? initialMode;

  void _showNextStep(
    BuildContext context,
    LudoGameMode mode,
  ) {
    final String modeName =
        mode == LudoGameMode.normal ? 'Normal Ludo' : 'Power Ludo';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LudoGlobalColors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  modeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Match type selection is the next screen in this UI phase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LudoGlobalColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _NextMatchTile(
                  icon: Icons.people_alt_rounded,
                  title: 'Local / Pass-and-Play',
                  subtitle: '2, 3, or 4 human players on one device',
                  enabled: true,
                ),
                const SizedBox(height: 10),
                const _NextMatchTile(
                  icon: Icons.smart_toy_rounded,
                  title: 'Play with Computer',
                  subtitle: 'Offline AI mode',
                  enabled: false,
                ),
                const SizedBox(height: 10),
                const _NextMatchTile(
                  icon: Icons.public_rounded,
                  title: 'Online Match',
                  subtitle: 'Planned after the offline game is complete',
                  enabled: false,
                ),
              ],
            ),
          ),
        );
      },
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
                        onPressed: () => _showNextStep(
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
                        onPressed: () => _showNextStep(
                          context,
                          LudoGameMode.power,
                        ),
                      ),
                      if (initialMode != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Selected from Home: ' +
                              (initialMode == LudoGameMode.normal
                                  ? 'Normal Ludo'
                                  : 'Power Ludo'),
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

class _NextMatchTile extends StatelessWidget {
  const _NextMatchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LudoGlobalColors.surfaceBright,
          borderRadius: BorderRadius.circular(LudoGlobalRadius.medium),
          border: Border.all(color: LudoGlobalColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled
                  ? LudoGlobalColors.cyan
                  : LudoGlobalColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: LudoGlobalColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!enabled)
              const Text(
                'LATER',
                style: TextStyle(
                  color: LudoGlobalColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
