import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../../core/widgets/game_icon_tile.dart';
import '../../ludo/domain/entities/game_config.dart';
import 'computer_setup_screen.dart';
import 'local_player_setup_screen.dart';

class MatchTypeScreen extends StatelessWidget {
  const MatchTypeScreen({
    required this.mode,
    super.key,
  });

  final LudoGameMode mode;

  String get _modeName =>
      mode == LudoGameMode.normal ? 'Normal Ludo' : 'Power Ludo';

  void _openLocal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalPlayerSetupScreen(mode: mode),
      ),
    );
  }

  void _openComputer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComputerSetupScreen(mode: mode),
      ),
    );
  }

  void _showPlanned(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is planned after the offline game engine is complete.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LudoGlobalSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(modeName: _modeName),
                const SizedBox(height: 22),
                _MatchTypeCard(
                  icon: Icons.phone_android_rounded,
                  title: 'Local / Pass-and-Play',
                  subtitle: '2, 3, or 4 humans • Same device • Offline',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB62C),
                      Color(0xFFEA6B16),
                    ],
                  ),
                  badge: 'READY',
                  onTap: () => _openLocal(context),
                ),
                const SizedBox(height: 12),
                _MatchTypeCard(
                  icon: Icons.smart_toy_rounded,
                  title: 'Play with Computer',
                  subtitle: 'Practice against AI players',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9B55FF),
                      Color(0xFF5628CE),
                    ],
                  ),
                  badge: 'READY',
                  onTap: () => _openComputer(context),
                ),
                const SizedBox(height: 12),
                _MatchTypeCard(
                  icon: Icons.public_rounded,
                  title: 'Online Match',
                  subtitle: 'Match with players around the world',
                  gradient: LudoGlobalGradients.normal,
                  badge: 'LATER',
                  onTap: () => _showPlanned(
                    context,
                    'Online Match',
                  ),
                ),
                const SizedBox(height: 12),
                _MatchTypeCard(
                  icon: Icons.lock_rounded,
                  title: 'Private Room',
                  subtitle: 'Create or join with a room code',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC13CFF),
                      Color(0xFF7137E7),
                    ],
                  ),
                  badge: 'LATER',
                  onTap: () => _showPlanned(
                    context,
                    'Private Room',
                  ),
                ),
                const SizedBox(height: 12),
                _MatchTypeCard(
                  icon: Icons.groups_rounded,
                  title: 'Play with Friends',
                  subtitle: 'Invite friends and play together',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF19C6D7),
                      Color(0xFF087DCB),
                    ],
                  ),
                  badge: 'LATER',
                  onTap: () => _showPlanned(
                    context,
                    'Play with Friends',
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

class _Header extends StatelessWidget {
  const _Header({required this.modeName});

  final String modeName;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                'SELECT MATCH TYPE',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                modeName,
                style: const TextStyle(
                  color: LudoGlobalColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchTypeCard extends StatelessWidget {
  const _MatchTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LudoGlobalRadius.large),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: LudoGlobalColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(LudoGlobalRadius.large),
            border: Border.all(
              color: LudoGlobalColors.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              GameIconTile(
                icon: icon,
                gradient: gradient,
                size: 58,
                iconSize: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LudoGlobalColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badge == 'READY'
                      ? LudoGlobalColors.green.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(
                    LudoGlobalRadius.pill,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badge == 'READY'
                        ? LudoGlobalColors.green
                        : LudoGlobalColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
