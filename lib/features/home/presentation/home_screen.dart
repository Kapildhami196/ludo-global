import 'package:flutter/material.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/ads/home_banner_ad.dart';
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

  Future<void> _watchRewardedAd(BuildContext context) async {
    final RewardedAdOutcome outcome =
        await AdService.instance.showRewardedForAdFreeMatch();

    if (!context.mounted) {
      return;
    }

    final String message = switch (outcome) {
      RewardedAdOutcome.earned =>
        'Reward earned: your next match is ad-free.',
      RewardedAdOutcome.dismissedWithoutReward =>
        'Finish the ad to earn an ad-free match.',
      RewardedAdOutcome.unavailable =>
        'The rewarded ad is still loading. Try again in a moment.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LudoGlobalSpacing.md,
            ),
            child: Column(
              children: [
                const HomeBannerAd(
                  key: Key('home_top_banner'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 520,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            const _HomeLogo(),
                            const SizedBox(height: 22),
                            Text(
                              'CHOOSE GAME MODE',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.72,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: LudoModeCard(
                                    title: 'NORMAL\nLUDO',
                                    subtitle: 'Classic Game',
                                    icon: Icons.casino_rounded,
                                    gradient:
                                        LudoGlobalGradients.normal,
                                    onPressed: () =>
                                        _openMatchType(
                                      context,
                                      LudoGameMode.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LudoModeCard(
                                    title: 'POWER\nLUDO',
                                    subtitle: 'Play With Powers',
                                    icon: Icons.bolt_rounded,
                                    gradient:
                                        LudoGlobalGradients.power,
                                    onPressed: () =>
                                        _openMatchType(
                                      context,
                                      LudoGameMode.power,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                key: const Key(
                                  'rewarded_ad_free_button',
                                ),
                                onPressed: () =>
                                    _watchRewardedAd(context),
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 19,
                                ),
                                label: const Text(
                                  'Watch Ad • Get 1 Ad-Free Match',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(
                                      alpha: 0.32,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const HomeBannerAd(
                  key: Key('home_bottom_banner'),
                ),
              ],
            ),
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
