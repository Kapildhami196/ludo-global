# Flame 3D Production Rendering Strategy

The app uses Flame as the game-rendering boundary while keeping all Ludo rules
and dice outcomes in the existing domain engine.

## Production rule

`flame_3d` is experimental, so it must never be the only renderer.

The production path is:

```text
PlayerDiceSlot
  -> ProductionDice
      -> supported Android/iOS/macOS: FlameDice3D
      -> unsupported/error path: AnimatedDice (existing SVG)
```

The game still works if 3D rendering is unavailable.

## Pinned versions

```yaml
flame: 1.38.2
flame_3d: 0.3.0
```

Do not change these versions as part of unrelated dependency upgrades. Review
the Flame 3D changelog and rerun device validation before changing either one.

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

## Supported runtime policy

3D is enabled only for Android, iOS, and macOS.

Web, Windows, Linux, and Fuchsia use the 2D fallback.

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
4. App background/resume during and after a roll.
5. Rotation/resize if supported by the app.
6. Memory behavior across repeated rematches.
7. 60 fps target during dice roll on supported devices.
8. Forced 2D fallback build.
9. Existing Ludo domain tests.
10. Visual verification that values 1 through 6 settle on the correct face.

## Next migration

After the dice passes the release gate, build one shared Flame 3D board scene
for all pawns. Do not create one GameWidget per pawn. All pawn meshes should
live in a single World3D so camera, lights, resources, and effects are shared.
