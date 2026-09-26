import 'package:flutter/material.dart';

import '../../../core/theme/ludo_global_tokens.dart';
import '../../../core/widgets/game_background.dart';
import '../../../core/widgets/game_icon_tile.dart';
import '../../ludo/domain/entities/game_config.dart';
import 'mode_selection_screen.dart';
import 'widgets/ludo_mode_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMode(
    BuildContext context,
    LudoGameMode mode,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModeSelectionScreen(initialMode: mode),
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
                      const _PlayerHeader(),
                      const SizedBox(height: 18),
                      const _HomeLogo(),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LudoModeCard(
                              title: 'NORMAL\nLUDO',
                              subtitle: 'Classic fun for everyone',
                              icon: Icons.casino_rounded,
                              gradient: LudoGlobalGradients.normal,
                              onPressed: () => _openMode(
                                context,
                                LudoGameMode.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LudoModeCard(
                              title: 'POWER\nLUDO',
                              subtitle: 'Special powers. Bigger strategy.',
                              icon: Icons.bolt_rounded,
                              gradient: LudoGlobalGradients.power,
                              onPressed: () => _openMode(
                                context,
                                LudoGameMode.power,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _QuickActions(),
                      const SizedBox(height: 22),
                      const _BottomMenu(),
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

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LudoGlobalGradients.gold,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF14305D),
            size: 30,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lv. 1',
                style: TextStyle(
                  color: LudoGlobalColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const _CurrencyPill(
          icon: Icons.monetization_on_rounded,
          value: '12,500',
          color: LudoGlobalColors.gold,
        ),
        const SizedBox(width: 8),
        const _CurrencyPill(
          icon: Icons.diamond_rounded,
          value: '320',
          color: LudoGlobalColors.purple,
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface,
        borderRadius: BorderRadius.circular(LudoGlobalRadius.pill),
        border: Border.all(color: LudoGlobalColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
                  color:
                      LudoGlobalColors.electricBlue.withValues(alpha: 0.45),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.people_alt_rounded,
            label: 'Friends',
            gradient: LinearGradient(
              colors: [
                Color(0xFF20B8FF),
                Color(0xFF0866DE),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.smart_toy_rounded,
            label: 'Computer',
            gradient: LinearGradient(
              colors: [
                Color(0xFF9D54FF),
                Color(0xFF5B2ED8),
              ],
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.phone_android_rounded,
            label: 'Local',
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFB526),
                Color(0xFFEF6B18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameIconTile(
          icon: icon,
          gradient: gradient,
          size: 54,
          iconSize: 27,
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BottomMenu extends StatelessWidget {
  const _BottomMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: LudoGlobalColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(LudoGlobalRadius.large),
        border: Border.all(color: LudoGlobalColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MenuItem(icon: Icons.store_rounded, label: 'Shop'),
          _MenuItem(icon: Icons.people_rounded, label: 'Friends'),
          _MenuItem(icon: Icons.task_alt_rounded, label: 'Missions'),
          _MenuItem(icon: Icons.event_rounded, label: 'Events'),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 23,
          color: LudoGlobalColors.gold,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
