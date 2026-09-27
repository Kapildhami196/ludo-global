# Flame 3D Production Rendering Strategy

The app uses Flame as the game-rendering boundary while keeping all Ludo rules
and dice outcomes in the existing domain engine.

## Production rule

`flame_3d` is experimental, so it must never be the only renderer.

The production path initializes the GPU backend once before `runApp`. If that initialization fails, the app stays usable and selects the 2D renderer.

```text
Local Classic
  -> ProductionDice
      -> supported Android/iOS/macOS: FlameDice3D
      -> unsupported/init-error path: AnimatedDice
  -> LudoBoard
      -> supported Android/iOS/macOS: one shared FlamePawnBoard3D world
      -> unsupported/render-error path: existing PremiumLudoToken SVG layer
```

The game still works if 3D rendering is unavailable.

## Pinned versions

```yaml
flame: 1.38.2
flame_3d:
  git:
    url: https://github.com/flame-engine/flame.git
    ref: 0453bad6e726ff90610baec86e5c24dc4c89a5a4
    path: packages/flame_3d
```

The published 0.3.0 release predates Flutter 3.47 GPU API changes and fails to
compile under the current stable toolchain when the GPU backend is reached.
The pinned upstream commit is Flame's verified Flutter 3.47 compatibility fix.
Do not move this ref as part of unrelated dependency upgrades. Review upstream
changes and rerun CI plus the physical-device release gate before updating it.

## Domain ownership

The 3D renderer never generates a dice value.

```text
CompetitiveDiceEngine / FairDicePolicy
        -> result 1..6
        -> LudoGameEngine
        -> FlameDice3D animation
```

The renderer only animates the result it receives.

## Current 3D dice

The first production canary is the dice because it is isolated and easy to
fall back independently.

It uses:

- a real CuboidMesh body;
- six physical pip layouts made from SphereMesh components;
- SpatialMaterial lighting;
- ambient and point lights;
- a perspective CameraComponent3D;
- real XYZ tumbling while rolling;
- quaternion settling toward the final result face;
- a short vertical/forward launch arc;
- the existing SVG dice if Flame 3D cannot be used.

## Current 3D pawns

Local Classic now renders all active pawns in one shared `World3D`.

The scene uses:

- a single orthographic camera aligned to the existing 15x15 Flutter board;
- one shared GPU scene for all pawns, rather than one GameWidget per pawn;
- procedural pawn geometry made from CylinderMesh, ConeMesh, and SphereMesh;
- glossy SpatialMaterial surfaces and shared scene lighting;
- real Z-depth lift during movement;
- a curved hop between board cells;
- longer spinning return motion after capture;
- a pulse/lift treatment for selectable pawns;
- transparent Flutter hit targets above the 3D layer so existing tap behavior remains reliable;
- the complete existing SVG pawn layer as the render-error fallback.

The board painter, labels, rules, token placement calculations, and domain state remain Flutter/domain-owned.

## Supported runtime policy

3D is enabled for Android, iOS, and macOS.

Debug web builds also enable Flame 3D automatically through its experimental
WebGPU backend so developers can actually preview the 3D dice and pawns in
Chrome. Release web remains opt-in with:

```bash
flutter run -d chrome --dart-define=LUDO_ENABLE_WEB_3D=true
```

Windows native, Linux native, and Fuchsia still use the 2D fallback because
Flame 3D does not support those native targets.

A release can force the fallback everywhere with:

```bash
flutter run --dart-define=LUDO_FORCE_2D=true
```

Use the same define in a release build if a Flame 3D regression is found.

## Flutter GPU platform configuration

The repository currently does not contain generated Android/iOS platform
folders. When those platform folders are present, enable Flutter GPU/Impeller
according to the pinned Flame 3D release documentation.

Do not make GPU enablement a silent one-off local setting. Commit the platform
configuration so CI/release builds use the same configuration.

## Release gate before enabling 3D broadly

Validate at minimum:

1. Android physical devices across low/mid/high tiers.
2. iPhone physical device.
3. Dice roll repeated at least 500 times without GPU/resource failure.
4. Move all 16 pawns repeatedly through long matches/rematches and verify memory stays stable.
5. Verify capture return, highlighted pawn pulse, stacked positions, and every board-edge cell visually.
6. App background/resume during and after a roll.
7. Rotation/resize if supported by the app.
8. Memory behavior across repeated rematches.
9. 60 fps target during dice and pawn animation on supported devices.
10. Forced 2D fallback build.
11. Existing Ludo domain tests.
12. Visual verification that values 1 through 6 settle on the correct face.

## Rollout scope

The 3D pawn layer is currently enabled only for Normal Local Human matches.
Computer and Power modes intentionally retain the existing 2D pawn renderer
until Local Classic passes physical-device profiling.

Do not expand the 3D renderer to additional modes solely because CI is green.
The package itself remains experimental, so each rollout step must preserve
the automatic 2D fallback and the `LUDO_FORCE_2D` kill switch.


## Development renderer diagnostics

Startup now prints one explicit renderer line:

```text
[LudoRenderer] Flame 3D renderer active
```

or a concrete fallback reason, for example:

```text
[LudoRenderer] 2D fallback: Flame 3D does not support Windows native
[LudoRenderer] 2D fallback: Flame GPU initialization failed (...)
```

If Chrome still shows the 2D renderer, confirm WebGPU is available in the
browser/device and inspect this line before changing game widgets.
