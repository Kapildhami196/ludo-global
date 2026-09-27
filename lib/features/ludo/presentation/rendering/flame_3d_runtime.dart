import 'package:flame_3d/graphics.dart';

import 'ludo_renderer_capabilities.dart';

abstract final class Flame3DRuntime {
  static bool _initialized = false;
  static bool _available = false;
  static Object? _initializationError;

  static bool get isAvailable =>
      LudoRendererCapabilities.supportsFlame3D && _available;

  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!LudoRendererCapabilities.supportsFlame3D) {
      return;
    }

    try {
      await GpuBackend.initialize();
      _available = true;
    } on Object catch (error) {
      _initializationError = error;
      _available = false;
    }
  }
}
