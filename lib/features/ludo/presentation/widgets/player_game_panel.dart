import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/player_color.dart';

class PlayerGamePanel extends StatelessWidget {
  const PlayerGamePanel({
    required this.player,
    required this.active,
    this.isComputer = false,
    this.consecutiveSixes = 0,
    this.alignRight = false,
    super.key,
  });

  final LudoPlayer player;
  final bool active;
  final bool isComputer;
  final int consecutiveSixes;
  final bool alignRight;

  Color get _color => switch (player.color) {
        PlayerColor.red => LudoGlobalColors.red,
        PlayerColor.green => LudoGlobalColors.green,
        PlayerColor.yellow => LudoGlobalColors.gold,
        PlayerColor.blue => LudoGlobalColors.electricBlue,
      };

  int get _finishedCount =>
      player.tokens.where((token) => token.isFinished).length;

  @override
  Widget build(BuildContext context) {
    final Widget identity = Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            _color.withValues(alpha: 0.34),
            const Color(0xFF08162D),
          ],
        ),
        border: Border.all(
          color: _color.withValues(alpha: active ? 0.95 : 0.42),
          width: active ? 1.5 : 1,
        ),
        boxShadow: <BoxShadow>[
          if (active)
            BoxShadow(
              color: _color.withValues(alpha: 0.40),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: SvgPicture.asset(
        GameAssetPaths.pawnFor(player.color),
        fit: BoxFit.contain,
      ),
    );

    final Widget copy = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isComputer && !alignRight) ...[
                const Icon(
                  Icons.smart_toy_rounded,
                  size: 11,
                  color: LudoGlobalColors.textSecondary,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFFD4DDEC),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              if (isComputer && alignRight) ...[
                const SizedBox(width: 3),
                const Icon(
                  Icons.smart_toy_rounded,
                  size: 11,
                  color: LudoGlobalColors.textSecondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                '${_finishedCount}/${player.tokens.length} HOME',
                style: TextStyle(
                  color: active
                      ? _color
                      : LudoGlobalColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.25,
                ),
              ),
              if (active && consecutiveSixes > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '6×$consecutiveSixes',
                  style: const TextStyle(
                    color: LudoGlobalColors.gold,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          end: alignRight ? Alignment.centerLeft : Alignment.centerRight,
          colors: <Color>[
            _color.withValues(alpha: active ? 0.22 : 0.08),
            const Color(0xE607142A),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _color.withValues(alpha: active ? 0.82 : 0.28),
          width: active ? 1.4 : 0.8,
        ),
        boxShadow: <BoxShadow>[
          if (active)
            BoxShadow(
              color: _color.withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: alignRight
            ? <Widget>[
                copy,
                const SizedBox(width: 6),
                identity,
              ]
            : <Widget>[
                identity,
                const SizedBox(width: 6),
                copy,
              ],
      ),
    );
  }
}
