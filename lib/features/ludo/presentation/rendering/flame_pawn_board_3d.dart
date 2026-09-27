import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/material.dart' show BuildContext, StatefulWidget, State, Widget, WidgetsBinding;

class FlamePawnVisualState {
  const FlamePawnVisualState({
    required this.tokenId,
    required this.boardX,
    required this.boardY,
    required this.color,
    required this.scale,
    required this.highlighted,
    required this.moving,
    required this.captured,
    required this.returning,
  });

  final int tokenId;
  final double boardX;
  final double boardY;
  final Color color;
  final double scale;
  final bool highlighted;
  final bool moving;
  final bool captured;
  final bool returning;
}

class FlamePawnBoard3D extends StatefulWidget {
  const FlamePawnBoard3D({
    required this.pawns,
    required this.cellSize,
    required this.fallback,
    super.key,
  });

  final List<FlamePawnVisualState> pawns;
  final double cellSize;
  final Widget fallback;

  @override
  State<FlamePawnBoard3D> createState() => _FlamePawnBoard3DState();
}

class _FlamePawnBoard3DState extends State<FlamePawnBoard3D> {
  late final FlamePawnBoard3DGame _game =
      FlamePawnBoard3DGame(initialPawns: widget.pawns);

  bool _failed = false;

  @override
  void didUpdateWidget(covariant FlamePawnBoard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updatePawns(widget.pawns);
  }

  void _handleRenderError() {
    if (_failed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallback;
    }

    final double overflow = widget.cellSize;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: -overflow,
          top: -overflow,
          right: -overflow,
          bottom: -overflow,
          child: IgnorePointer(
            child: GameWidget<FlamePawnBoard3DGame>(
              game: _game,
              autofocus: false,
              errorBuilder: (context, error) {
                _handleRenderError();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FlamePawnBoard3DGame
    extends FlameGame3D<World3D, CameraComponent3D> {
  FlamePawnBoard3DGame({
    required List<FlamePawnVisualState> initialPawns,
  })  : _pendingPawns = List<FlamePawnVisualState>.of(initialPawns),
        super(
          world: World3D(),
          camera: CameraComponent3D(
            projection: CameraProjection.orthographic,
            fovY: 17,
            position: Vector3(0, 0, 20),
            target: Vector3.zero(),
            up: Vector3(0, 1, 0),
          ),
        );

  final Map<int, LudoPawn3DComponent> _components =
      <int, LudoPawn3DComponent>{};

  List<FlamePawnVisualState> _pendingPawns;
  bool _sceneReady = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  FutureOr<void> onLoad() {
    world.addAll(<Component3D>[
      LightComponent.ambient(
        color: const Color(0xFFFFFFFF),
        intensity: 0.60,
      ),
      LightComponent.point(
        position: Vector3(-6.5, 8.5, 10),
        color: const Color(0xFFFFFFFF),
        intensity: 10,
      ),
      LightComponent.point(
        position: Vector3(7, -5.5, 8),
        color: const Color(0xFF9CCBFF),
        intensity: 4.2,
      ),
    ]);

    _sceneReady = true;
    _syncPawns(_pendingPawns, animate: false);
  }

  void updatePawns(List<FlamePawnVisualState> pawns) {
    _pendingPawns = List<FlamePawnVisualState>.of(pawns);

    if (_sceneReady) {
      _syncPawns(_pendingPawns, animate: true);
    }
  }

  void _syncPawns(
    List<FlamePawnVisualState> pawns, {
    required bool animate,
  }) {
    final Set<int> incoming =
        pawns.map((FlamePawnVisualState pawn) => pawn.tokenId).toSet();

    final List<int> removed = _components.keys
        .where((int tokenId) => !incoming.contains(tokenId))
        .toList(growable: false);

    for (final int tokenId in removed) {
      _components.remove(tokenId)?.removeFromParent();
    }

    for (final FlamePawnVisualState pawn in pawns) {
      final LudoPawn3DComponent? existing = _components[pawn.tokenId];

      if (existing == null) {
        final LudoPawn3DComponent component =
            LudoPawn3DComponent(visual: pawn);
        _components[pawn.tokenId] = component;
        world.add(component);
      } else {
        existing.applyVisual(
          pawn,
          animate: animate,
        );
      }
    }
  }
}

class LudoPawn3DComponent extends MeshComponent {
  LudoPawn3DComponent({
    required FlamePawnVisualState visual,
  }) : this._(
          visual: visual,
          material: SpatialMaterial(
            albedoColor: visual.color,
            metallic: 0.10,
            roughness: 0.24,
          ),
        );

  LudoPawn3DComponent._({
    required FlamePawnVisualState visual,
    required SpatialMaterial material,
  })  : _visual = visual,
        _targetPosition = _positionFor(visual),
        super(
          position: _positionFor(visual),
          scale: Vector3.all(_visualScale(visual)),
          mesh: CylinderMesh(
            radius: 0.48,
            height: 0.18,
            segments: 24,
            material: material,
          ),
          children: <Component3D>[
            MeshComponent(
              position: Vector3(0, 0.07, 0),
              mesh: ConeMesh(
                radius: 0.36,
                height: 0.58,
                segments: 24,
                material: material,
              ),
            ),
            MeshComponent(
              position: Vector3(0, 0.69, 0),
              mesh: CylinderMesh(
                radius: 0.20,
                height: 0.16,
                segments: 24,
                material: material,
              ),
            ),
            MeshComponent(
              position: Vector3(0, 0.94, 0.02),
              mesh: SphereMesh(
                radius: 0.28,
                segments: 24,
                material: material,
              ),
            ),
          ],
        );

  FlamePawnVisualState _visual;

  Vector3 _targetPosition;
  Vector3 _moveFrom = Vector3.zero();

  double _moveElapsed = 0;
  double _moveDuration = 0.155;
  double _clock = 0;
  bool _animatingPosition = false;

  static Vector3 _positionFor(FlamePawnVisualState visual) {
    return Vector3(
      visual.boardX - 7.5,
      7.5 - visual.boardY,
      0,
    );
  }

  static double _visualScale(FlamePawnVisualState visual) {
    return visual.scale * 1.18;
  }

  void applyVisual(
    FlamePawnVisualState visual, {
    required bool animate,
  }) {
    final Vector3 nextPosition = _positionFor(visual);
    final bool moved =
        (nextPosition - _targetPosition).length2 > 0.000001;

    _visual = visual;

    if (moved) {
      _moveFrom = position.clone();
      _targetPosition = nextPosition;
      _moveElapsed = 0;
      _moveDuration = visual.returning ? 0.52 : 0.155;
      _animatingPosition = animate;

      if (!animate) {
        position.setFrom(_targetPosition);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _clock += dt;

    double motionLift = 0;
    double motionSpin = 0;

    if (_animatingPosition) {
      _moveElapsed += dt;
      final double t =
          (_moveElapsed / _moveDuration).clamp(0.0, 1.0);
      final double eased =
          1 - math.pow(1 - t, 3).toDouble();
      final double arc = math.sin(t * math.pi);

      motionLift =
          arc * (_visual.returning ? 0.82 : 0.48);
      motionSpin =
          _visual.returning ? t * math.pi * 2.4 : 0;

      position.setValues(
        _lerp(_moveFrom.x, _targetPosition.x, eased),
        _lerp(_moveFrom.y, _targetPosition.y, eased) +
            (arc * 0.18),
        motionLift,
      );

      if (t >= 1) {
        _animatingPosition = false;
        position.setFrom(_targetPosition);
      }
    }

    final double captureShake = _visual.captured
        ? math.sin(_clock * math.pi * 13) * 0.16
        : 0;

    rotation.setEuler(
      0,
      motionSpin,
      captureShake,
    );

    final double highlightPulse = _visual.highlighted
        ? 1 + ((math.sin(_clock * math.pi * 4) + 1) * 0.035)
        : 1;

    final double captureScale = _visual.captured ? 0.88 : 1;
    final double baseScale =
        _visualScale(_visual) * highlightPulse * captureScale;

    scale.setValues(
      baseScale,
      baseScale,
      baseScale,
    );

    if (!_animatingPosition) {
      position.z = _visual.highlighted
          ? 0.04 +
              ((math.sin(_clock * math.pi * 4) + 1) * 0.025)
          : 0;
    } else {
      position.z = motionLift;
    }
  }

  static double _lerp(double a, double b, double t) {
    return a + ((b - a) * t);
  }
}
