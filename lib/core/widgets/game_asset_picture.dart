import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders game art from either the SVG or raster asset collections.
class GameAssetPicture extends StatelessWidget {
  const GameAssetPicture.asset(
    this.assetName, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (assetName.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetName,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.asset(
      assetName,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}
