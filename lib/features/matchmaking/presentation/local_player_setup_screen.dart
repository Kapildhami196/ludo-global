import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../../core/widgets/glossy_game_button.dart';
import '../../ludo/domain/entities/game_config.dart';
import '../../ludo/presentation/screens/local_game_screen.dart';
import '../../ludo/presentation/screens/power_local_game_screen.dart';

class LocalPlayerSetupScreen extends StatefulWidget {
  const LocalPlayerSetupScreen({
    required this.mode,
    super.key,
  });

  final LudoGameMode mode;

  @override
  State<LocalPlayerSetupScreen> createState() =>
      _LocalPlayerSetupScreenState();
}

class _LocalPlayerSetupScreenState extends State<LocalPlayerSetupScreen> {
  int _playerCount = 4;

  late final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(text: 'Player ${index + 1}'),
  );

  static const List<_PlayerVisual> _visuals = [
    _PlayerVisual(
      label: 'RED',
      color: LudoGlobalColors.red,
      icon: Icons.person_rounded,
    ),
    _PlayerVisual(
      label: 'GREEN',
      color: LudoGlobalColors.green,
      icon: Icons.person_rounded,
    ),
    _PlayerVisual(
      label: 'YELLOW',
      color: LudoGlobalColors.gold,
      icon: Icons.person_rounded,
    ),
    _PlayerVisual(
      label: 'BLUE',
      color: LudoGlobalColors.electricBlue,
      icon: Icons.person_rounded,
    ),
  ];

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    FocusManager.instance.primaryFocus?.unfocus();

    final List<String> names = [
      for (int index = 0; index < _playerCount; index++)
        _controllers[index].text.trim().isEmpty
            ? 'Player ${index + 1}'
            : _controllers[index].text.trim(),
    ];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          if (widget.mode == LudoGameMode.power) {
            return PowerLocalGameScreen(
              playerNames: names,
            );
          }

          return LocalGameScreen(
            mode: widget.mode,
            playerNames: names,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String modeName = widget.mode == LudoGameMode.normal
        ? 'Normal Ludo'
        : 'Power Ludo';

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
                            'LOCAL PLAYERS',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$modeName • Same device',
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
                const SizedBox(height: 20),
                const Text(
                  'How many people are playing?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final int count in const [2, 3, 4]) ...[
                      if (count != 2) const SizedBox(width: 9),
                      Expanded(
                        child: _PlayerCountButton(
                          count: count,
                          selected: _playerCount == count,
                          onTap: () {
                            setState(() {
                              _playerCount = count;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                for (int index = 0; index < _playerCount; index++) ...[
                  _PlayerNameField(
                    number: index + 1,
                    controller: _controllers[index],
                    visual: _visuals[index],
                  ),
                  if (index != _playerCount - 1)
                    const SizedBox(height: 12),
                ],
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LudoGlobalColors.surface.withValues(alpha: 0.82),
                    borderRadius:
                        BorderRadius.circular(LudoGlobalRadius.medium),
                    border: Border.all(color: LudoGlobalColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        color: LudoGlobalColors.cyan,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pass the phone to the next player after each turn. '
                          'This mode is designed to work without internet.',
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
                const SizedBox(height: 20),
                GlossyGameButton(
                  label: 'Start Game',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _startGame,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2DDF69),
                      Color(0xFF0AA43E),
                    ],
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

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LudoGlobalRadius.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: selected ? LudoGlobalGradients.normal : null,
            color: selected ? null : LudoGlobalColors.surface,
            borderRadius:
                BorderRadius.circular(LudoGlobalRadius.medium),
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
                '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Players',
                style: TextStyle(
                  fontSize: 10,
                  color: LudoGlobalColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({
    required this.number,
    required this.controller,
    required this.visual,
  });

  final int number;
  final TextEditingController controller;
  final _PlayerVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(LudoGlobalRadius.medium),
        border: Border.all(
          color: visual.color.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visual.color,
              boxShadow: [
                BoxShadow(
                  color: visual.color.withValues(alpha: 0.38),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              visual.icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 16,
              textInputAction: number == 4
                  ? TextInputAction.done
                  : TextInputAction.next,
              decoration: InputDecoration(
                counterText: '',
                labelText: 'Player $number',
                hintText: 'Enter player name',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 48,
            child: Text(
              visual.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: visual.color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerVisual {
  const _PlayerVisual({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}
