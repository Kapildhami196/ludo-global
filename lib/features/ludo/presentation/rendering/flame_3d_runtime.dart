import 'package:flame_3d/graphics.dart';
import 'package:flutter/foundation.dart';

import 'ludo_renderer_capabilities.dart';

abstract final class Flame3DRuntime {
  static bool _initialized = false;
  static bool _available = false;
  static Object? _initializationError;

  static bool get isAvailable =>
      LudoRendererCapabilities.supportsFlame3D && _available;

  static Object? get initializationError => _initializationError;

  static String get statusMessage {
    if (!LudoRendererCapabilities.supportsFlame3D) {
      return '2D fallback: ${LudoRendererCapabilities.unsupportedReason}';
    }

    if (!_initialized) {
      return '3D renderer not initialized';
    }

    if (_available) {
      return 'Flame 3D renderer active';
    }

    return '2D fallback: Flame GPU initialization failed'
        '${_initializationError == null ? '' : ' ($_initializationError)'}';
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!LudoRendererCapabilities.supportsFlame3D) {
      debugPrint('[LudoRenderer] $statusMessage');
      return;
    }

    try {
      await GpuBackend.initialize();
      _available = true;
      debugPrint('[LudoRenderer] $statusMessage');
    } on Object catch (error, stackTrace) {
      _initializationError = error;
      _available = false;
      debugPrint('[LudoRenderer] $statusMessage');
      debugPrintStack(
        label: '[LudoRenderer] Flame 3D initialization stack',
        stackTrace: stackTrace,
      );
    }
  }
}
