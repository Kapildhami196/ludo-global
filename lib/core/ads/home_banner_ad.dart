import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/ludo_global_tokens.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({
    super.key,
  });

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _loadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadRequested || !AdService.instance.isInitialized) {
      return;
    }

    _loadRequested = true;
    unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    final int width = (
      MediaQuery.sizeOf(context).width -
      (LudoGlobalSpacing.md * 2)
    ).floor();

    final AdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (!mounted || size == null) {
      return;
    }

    final BannerAd ad = BannerAd(
      adUnitId: AdIds.banner,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (Ad loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }

          setState(() {
            _bannerAd = loadedAd as BannerAd;
          });
        },
        onAdFailedToLoad: (
          Ad failedAd,
          LoadAdError error,
        ) {
          failedAd.dispose();
        },
      ),
    );

    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.isInitialized) {
      return const SizedBox.shrink();
    }

    final BannerAd? ad = _bannerAd;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(
          LudoGlobalRadius.small,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      alignment: Alignment.center,
      child: ad == null
          ? const SizedBox(height: 50)
          : SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
