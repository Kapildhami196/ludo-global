import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../../core/widgets/glossy_game_button.dart';
import '../../ludo/domain/ai/ai_difficulty.dart';
import '../../ludo/domain/entities/game_config.dart';
import '../../ludo/presentation/screens/computer_game_screen.dart';
import '../../ludo/presentation/screens/power_computer_game_screen.dart';

class ComputerSetupScreen extends StatefulWidget {
  const ComputerSetupScreen({
    required this.mode,
    super.key,
  });

  final LudoGameMode mode;

  @override
  State<ComputerSetupScreen> createState() =>
      _ComputerSetupScreenState();
}

class _ComputerSetupScreenState extends State<ComputerSetupScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'You');

  int _totalPlayers = 2;
  AiDifficulty _difficulty = AiDifficulty.medium;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    FocusManager.instance.primaryFocus?.unfocus();

    final String humanName = _nameController.text.trim().isEmpty
        ? 'You'
        : _nameController.text.trim();

    final List<String> names = <String>[
      humanName,
      for (int index = 1; index < _totalPlayers; index++)
        'Computer $index',
    ];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          if (widget.mode == LudoGameMode.power) {
            return PowerComputerGameScreen(
              playerNames: names,
              difficulty: _difficulty,
            );
          }

          return ComputerGameScreen(
            playerNames: names,
            difficulty: _difficulty,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool power = widget.mode == LudoGameMode.power;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LudoGlobalSpacing.md),
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
                            'PLAY WITH COMPUTER',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            power ? 'Power Ludo • Offline AI' : 'Normal Ludo • Offline AI',
                            style: const TextStyle(
                              color: LudoGlobalColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _nameController,
                  maxLength: 16,
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Your name',
                    prefixIcon: const Icon(Icons.person_rounded),
                    filled: true,
                    fillColor:
                        LudoGlobalColors.surface.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'TOTAL PLAYERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (final int count in const <int>[2, 3, 4]) ...[
                      if (count != 2) const SizedBox(width: 9),
                      Expanded(
                        child: _ChoiceTile(
                          title: '$count',
                          subtitle: count == 2
                              ? '1 AI'
                              : '${count - 1} AIs',
                          selected: _totalPlayers == count,
                          onTap: () => setState(
                            () => _totalPlayers = count,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'AI DIFFICULTY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 9),
                for (final AiDifficulty difficulty
                    in AiDifficulty.values) ...[
                  _DifficultyTile(
                    difficulty: difficulty,
                    selected: _difficulty == difficulty,
                    onTap: () => setState(
                      () => _difficulty = difficulty,
                    ),
                  ),
                  if (difficulty != AiDifficulty.values.last)
                    const SizedBox(height: 9),
                ],
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: LudoGlobalColors.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LudoGlobalColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        color: power
                            ? LudoGlobalColors.purple
                            : LudoGlobalColors.cyan,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          power
                              ? 'Computer players understand Normal Ludo rules and can also use Power Ludo abilities.'
                              : 'Computer players roll and move automatically. No internet is required.',
                          style: const TextStyle(
                            color: LudoGlobalColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlossyGameButton(
                  label: 'Start vs Computer',
                  icon: Icons.smart_toy_rounded,
                  onPressed: _start,
                  gradient: power
                      ? LudoGlobalGradients.power
                      : LudoGlobalGradients.normal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? LudoGlobalColors.electricBlue.withValues(alpha: 0.22)
              : LudoGlobalColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? LudoGlobalColors.cyan
                : LudoGlobalColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: LudoGlobalColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final AiDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (difficulty) {
      AiDifficulty.easy => Icons.sentiment_satisfied_rounded,
      AiDifficulty.medium => Icons.psychology_rounded,
      AiDifficulty.hard => Icons.local_fire_department_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? LudoGlobalColors.purple.withValues(alpha: 0.18)
              : LudoGlobalColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? LudoGlobalColors.purple
                : LudoGlobalColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? LudoGlobalColors.gold
                  : LudoGlobalColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    difficulty.description,
                    style: const TextStyle(
                      color: LudoGlobalColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: LudoGlobalColors.green,
              ),
          ],
        ),
      ),
    );
  }
}
