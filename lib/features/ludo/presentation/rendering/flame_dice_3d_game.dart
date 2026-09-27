import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';

class FlameDice3DGame
    extends FlameGame3D<World3D, CameraComponent3D> {
  FlameDice3DGame({
    required int initialValue,
    required Offset launchDirection,
  })  : _desiredValue = initialValue.clamp(1, 6).toInt(),
        _launchDirection = launchDirection,
        super(
          world: World3D(),
          camera: CameraComponent3D(
            fovY: 38,
            position: Vector3(0, 2.35, 4.7),
            target: Vector3(0, 0.22, 0),
          ),
        );

  int _desiredValue;
  bool _desiredRolling = false;
  Offset _launchDirection;
  LudoDice3DComponent? _dice;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  FutureOr<void> onLoad() {
    final LudoDice3DComponent dice = LudoDice3DComponent(
      initialValue: _desiredValue,
      launchDirection: _launchDirection,
    );
    _dice = dice;

    world.addAll(<Component3D>[
      LightComponent.ambient(
        color: const Color(0xFFFFFFFF),
        intensity: 0.72,
      ),
      LightComponent.point(
        position: Vector3(-2.2, 3.5, 3.2),
        color: const Color(0xFFFFFFFF),
        intensity: 9.0,
      ),
      LightComponent.point(
        position: Vector3(2.4, 1.4, 2.4),
        color: const Color(0xFF9BC6FF),
        intensity: 3.5,
      ),
      dice,
    ]);

    dice.setRollState(
      rolling: _desiredRolling,
      value: _desiredValue,
    );
  }

  void updateRollState({
    required bool rolling,
    required int value,
    required Offset launchDirection,
  }) {
    _desiredRolling = rolling;
    _desiredValue = value.clamp(1, 6).toInt();
    _launchDirection = launchDirection;

    final LudoDice3DComponent? dice = _dice;
    if (dice == null) {
      return;
    }

    dice
      ..launchDirection = launchDirection
      ..setRollState(
        rolling: rolling,
        value: _desiredValue,
      );
  }
}

class LudoDice3DComponent extends MeshComponent {
  LudoDice3DComponent({
    required int initialValue,
    required Offset launchDirection,
  })  : _value = initialValue.clamp(1, 6).toInt(),
        _launchDirection = launchDirection,
        super(
          position: Vector3(0, 0.10, 0),
          mesh: CuboidMesh(
            size: Vector3.all(1.28),
            material: SpatialMaterial(
              albedoColor: const Color(0xFFF9FAFC),
              metallic: 0.08,
              roughness: 0.23,
            ),
            useFaceNormals: true,
          ),
          children: _buildPips(),
        ) {
    rotation.setFrom(_orientationForValue(_value));
  }

  static const double _half = 0.64;
  static const double _pipRadius = 0.073;
  static const double _pipOffset = 0.29;

  int _value;
  bool _rolling = false;
  bool _settling = false;
  double _rollElapsed = 0;
  double _settleElapsed = 0;
  Offset _launchDirection;

  Quaternion _settleFrom = Quaternion.identity();
  Quaternion _settleTo = Quaternion.identity();

  set launchDirection(Offset value) {
    _launchDirection = value;
  }

  void setRollState({
    required bool rolling,
    required int value,
  }) {
    final int clampedValue = value.clamp(1, 6).toInt();

    if (rolling) {
      if (!_rolling) {
        _rolling = true;
        _settling = false;
        _rollElapsed = 0;
      }
      return;
    }

    if (_rolling || clampedValue != _value) {
      _rolling = false;
      _settling = true;
      _settleElapsed = 0;
      _value = clampedValue;
      _settleFrom = Quaternion.copy(rotation);
      _settleTo = _orientationForValue(_value);
      return;
    }

    _value = clampedValue;
    rotation.setFrom(_orientationForValue(_value));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_rolling) {
      _rollElapsed += dt;

      final double bounce =
          math.sin((_rollElapsed * math.pi) / 0.32).abs();
      final double forward =
          math.sin((_rollElapsed * math.pi) / 0.64)
              .clamp(0.0, 1.0);

      position.setValues(
        _launchDirection.dx * 0.52 * forward,
        0.10 + (bounce * 0.78),
        _launchDirection.dy * 0.34 * forward,
      );

      rotation.setEuler(
        _rollElapsed * 8.6,
        _rollElapsed * 10.8,
        _rollElapsed * 7.2,
      );
      return;
    }

    if (_settling) {
      _settleElapsed += dt;
      final double t =
          (_settleElapsed / 0.34).clamp(0.0, 1.0);
      final double eased =
          1 - math.pow(1 - t, 3).toDouble();
      final Quaternion next =
          Quaternion.copy(_settleFrom)
            ..slerp(_settleTo, eased);

      rotation.setFrom(next);

      final double landingBounce =
          math.sin(t * math.pi) * (1 - t);
      position.setValues(
        0,
        0.10 + landingBounce * 0.16,
        0,
      );

      if (t >= 1) {
        _settling = false;
        rotation.setFrom(_settleTo);
        position.setValues(0, 0.10, 0);
      }
    }
  }

  static Quaternion _orientationForValue(int value) {
    final Vector3 faceNormal = switch (value) {
      1 => Vector3(0, 0, 1),
      2 => Vector3(1, 0, 0),
      3 => Vector3(0, 1, 0),
      4 => Vector3(0, -1, 0),
      5 => Vector3(-1, 0, 0),
      6 => Vector3(0, 0, -1),
      _ => Vector3(0, 0, 1),
    };

    final Vector3 cameraDirection = Vector3(0, 0.26, 1)
      ..normalize();

    return Quaternion.fromTwoVectors(
      faceNormal,
      cameraDirection,
    );
  }

  static List<Component3D> _buildPips() {
    final List<Component3D> pips = <Component3D>[];

    void pip(double x, double y, double z) {
      pips.add(
        MeshComponent(
          position: Vector3(x, y, z),
          mesh: SphereMesh(
            radius: _pipRadius,
            segments: 18,
            material: SpatialMaterial(
              albedoColor: const Color(0xFF121319),
              metallic: 0.12,
              roughness: 0.34,
            ),
          ),
        ),
      );
    }

    void faceZ(int value, double z) {
      for (final (double x, double y) in _pattern(value)) {
        pip(x, y, z);
      }
    }

    void faceX(int value, double x) {
      for (final (double a, double b) in _pattern(value)) {
        pip(x, a, b);
      }
    }

    void faceY(int value, double y) {
      for (final (double a, double b) in _pattern(value)) {
        pip(a, y, b);
      }
    }

    faceZ(1, _half + 0.015);
    faceX(2, _half + 0.015);
    faceY(3, _half + 0.015);
    faceY(4, -_half - 0.015);
    faceX(5, -_half - 0.015);
    faceZ(6, -_half - 0.015);

    return pips;
  }

  static List<(double, double)> _pattern(int value) {
    const double o = _pipOffset;

    return switch (value) {
      1 => const <(double, double)>[(0, 0)],
      2 => const <(double, double)>[
          (-o, o),
          (o, -o),
        ],
      3 => const <(double, double)>[
          (-o, o),
          (0, 0),
          (o, -o),
        ],
      4 => const <(double, double)>[
          (-o, o),
          (o, o),
          (-o, -o),
          (o, -o),
        ],
      5 => const <(double, double)>[
          (-o, o),
          (o, o),
          (0, 0),
          (-o, -o),
          (o, -o),
        ],
      6 => const <(double, double)>[
          (-o, o),
          (-o, 0),
          (-o, -o),
          (o, o),
          (o, 0),
          (o, -o),
        ],
      _ => const <(double, double)>[(0, 0)],
    };
  }
}
