# Ludo Global Game Assets

These are the gameplay graphics used by Ludo Global.

## Asset groups

- `pawns/` — red, green, yellow, and blue glossy pawn pieces
- `dice/` — six white 3D-style dice faces
- `powers/` — Double Distance, Shield, Dice Control, and Bonus Roll raster artwork
- `board/` — the complete Ludo board plus supporting board graphics

## Rendering

Use the centralized asset paths in:

`lib/core/assets/game_asset_paths.dart`

Gameplay pawns, dice, and power markers use these assets while movement,
capture, shield, and roll animations remain driven by Flutter.

The board PNG is rendered at the SVG's native 1500 x 1500 resolution so its
drop shadows remain identical on Flutter renderers that do not support SVG
filters. The original SVG is retained beside it as the source artwork.
