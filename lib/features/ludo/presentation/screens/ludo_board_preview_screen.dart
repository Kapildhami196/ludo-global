import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../domain/entities/game_config.dart';
import '../widgets/ludo_board.dart';

class LudoBoardPreviewScreen extends StatelessWidget {
  const LudoBoardPreviewScreen({
    required this.mode,
    required this.playerNames,
    super.key,
  });

  final LudoGameMode mode;
  final List<String> playerNames;

  static const List<Color> _playerColors = [
    LudoGlobalColors.red,
    LudoGlobalColors.green,
    LudoGlobalColors.gold,
    LudoGlobalColors.electricBlue,
  ];

  static const List<String> _playerLabels = [
    'RED',
    'GREEN',
    'YELLOW',
    'BLUE',
  ];

  @override
  Widget build(BuildContext context) {
    final String modeName =
        mode == LudoGameMode.normal ? 'Normal Ludo' : 'Power Ludo';

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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GAME BOARD',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '$modeName • Local Pass-and-Play',
                                  style: const TextStyle(
                                    color:
                                        LudoGlobalColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: mode == LudoGameMode.power
                                  ? LudoGlobalColors.red
                                      .withValues(alpha: 0.2)
                                  : LudoGlobalColors.electricBlue
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                LudoGlobalRadius.pill,
                              ),
                            ),
                            child: Text(
                              mode == LudoGameMode.power
                                  ? '⚡ POWER'
                                  : '🎲 NORMAL',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PlayerStrip(
                        playerNames: playerNames,
                        colors: _playerColors,
                        labels: _playerLabels,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061127),
                          borderRadius: BorderRadius.circular(
                            LudoGlobalRadius.large,
                          ),
                          border: Border.all(
                            color: LudoGlobalColors.border,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: LudoBoard(
                          activePlayerCount: playerNames.length,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _GameControlCard(
                              icon: Icons.chat_bubble_rounded,
                              label: 'Chat',
                              onTap: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Quick chat will be added with gameplay.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const _DicePreview(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GameControlCard(
                              icon: Icons.emoji_emotions_rounded,
                              label: 'Emotes',
                              onTap: () {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Player reactions will be added later.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (mode == LudoGameMode.power) ...[
                        const SizedBox(height: 14),
                        const _PowerPreviewBar(),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: LudoGlobalColors.surface
                              .withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(
                            LudoGlobalRadius.medium,
                          ),
                          border: Border.all(
                            color: LudoGlobalColors.border,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.construction_rounded,
                              color: LudoGlobalColors.gold,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Board foundation is ready. Dice and token '
                                'movement rules are the next gameplay phase.',
                                style: TextStyle(
                                  color: LudoGlobalColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({
    required this.playerNames,
    required this.colors,
    required this.labels,
  });

  final List<String> playerNames;
  final List<Color> colors;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < playerNames.length; index++) ...[
          if (index != 0) const SizedBox(width: 7),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: LudoGlobalColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors[index].withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[index],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playerNames[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: colors[index],
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DicePreview extends StatelessWidget {
  const _DicePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: LudoGlobalGradients.normal,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: LudoGlobalColors.electricBlue
                .withValues(alpha: 0.32),
            blurRadius: 15,
          ),
        ],
      ),
      child: const Icon(
        Icons.casino_rounded,
        size: 46,
        color: Colors.white,
      ),
    );
  }
}

class _GameControlCard extends StatelessWidget {
  const _GameControlCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          LudoGlobalRadius.medium,
        ),
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            color: LudoGlobalColors.surface,
            borderRadius: BorderRadius.circular(
              LudoGlobalRadius.medium,
            ),
            border: Border.all(
              color: LudoGlobalColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: LudoGlobalColors.cyan,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerPreviewBar extends StatelessWidget {
  const _PowerPreviewBar();

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String, Color)> powers = [
      (
        Icons.close_rounded,
        'Double',
        LudoGlobalColors.red,
      ),
      (
        Icons.shield_rounded,
        'Shield',
        LudoGlobalColors.electricBlue,
      ),
      (
        Icons.gps_fixed_rounded,
        'Control',
        LudoGlobalColors.purple,
      ),
      (
        Icons.star_rounded,
        'Bonus',
        LudoGlobalColors.gold,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(
          LudoGlobalRadius.medium,
        ),
        border: Border.all(color: LudoGlobalColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR POWERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final (IconData icon, String label, Color color)
                  in powers) ...[
                if (label != 'Double') const SizedBox(width: 7),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 23),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
