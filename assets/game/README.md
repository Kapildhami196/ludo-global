# Ludo Global Game Assets

These assets are original Ludo Global vector graphics created for the game.
They are not cropped or traced from third-party screenshots.

## Asset groups

- `pawns/` — red, green, yellow, and blue glossy pawn pieces
- `dice/` — six white 3D-style dice faces
- `powers/` — Double Distance, Shield, Dice Control, and Bonus Roll
- `board/` — safe star, direction arrow, and center goal

## Rendering

Use `flutter_svg` and the centralized paths in:

`lib/core/assets/game_asset_paths.dart`

The next graphics phase will replace the painter-only gameplay pawns and dice
with these assets while keeping movement, capture, shield, and roll animations
driven by Flutter.
