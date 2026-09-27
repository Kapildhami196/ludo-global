import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';

class BoardDecorationLayer extends StatelessWidget {
  const BoardDecorationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final double cell = size / 15;

          Widget atCell({
            required int column,
            required int row,
            required String asset,
            double scale = 0.72,
            double rotation = 0,
          }) {
            final double assetSize = cell * scale;
            return Positioned(
              left: (column + 0.5) * cell - assetSize / 2,
              top: (row + 0.5) * cell - assetSize / 2,
              child: Transform.rotate(
                angle: rotation,
                child: SvgPicture.asset(
                  asset,
                  width: assetSize,
                  height: assetSize,
                ),
              ),
            );
          }

          return Stack(
            children: [
              atCell(
                column: 6,
                row: 2,
                asset: GameAssetPaths.safeStar,
              ),
              atCell(
                column: 12,
                row: 6,
                asset: GameAssetPaths.safeStar,
              ),
              atCell(
                column: 8,
                row: 12,
                asset: GameAssetPaths.safeStar,
              ),
              atCell(
                column: 2,
                row: 8,
                asset: GameAssetPaths.safeStar,
              ),
              atCell(
                column: 1,
                row: 6,
                asset: GameAssetPaths.directionArrow,
                scale: 0.54,
              ),
              atCell(
                column: 8,
                row: 1,
                asset: GameAssetPaths.directionArrow,
                scale: 0.54,
                rotation: math.pi / 2,
              ),
              atCell(
                column: 13,
                row: 8,
                asset: GameAssetPaths.directionArrow,
                scale: 0.54,
                rotation: math.pi,
              ),
              atCell(
                column: 6,
                row: 13,
                asset: GameAssetPaths.directionArrow,
                scale: 0.54,
                rotation: -math.pi / 2,
              ),
              Positioned(
                left: 6.77 * cell,
                top: 6.77 * cell,
                child: SvgPicture.asset(
                  GameAssetPaths.centerGoal,
                  width: cell * 1.46,
                  height: cell * 1.46,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
