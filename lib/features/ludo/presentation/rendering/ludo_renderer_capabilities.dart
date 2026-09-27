import 'package:flutter/foundation.dart';

abstract final class LudoRendererCapabilities {
  static const bool force2D = bool.fromEnvironment(
    'LUDO_FORCE_2D',
    defaultValue: false,
  );

  static const bool enableExperimentalWeb3D = bool.fromEnvironment(
    'LUDO_ENABLE_WEB_3D',
    defaultValue: false,
  );

  static bool get supportsFlame3D {
    if (force2D) {
      return false;
    }

    if (kIsWeb) {
      // Flame 3D web rendering uses WebGPU and is still experimental.
      // Enable it automatically only for local/debug development so the
      // 3D renderer is visible while iterating. Release web stays opt-in.
      return kDebugMode || enableExperimentalWeb3D;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows =>
        false,
    };
  }

  static String get unsupportedReason {
    if (force2D) {
      return 'LUDO_FORCE_2D is enabled';
    }

    if (kIsWeb && !supportsFlame3D) {
      return 'Web 3D is disabled for this build';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows =>
        'Flame 3D does not support Windows native',
      TargetPlatform.linux =>
        'Flame 3D does not support Linux native',
      TargetPlatform.fuchsia =>
        'Flame 3D does not support Fuchsia',
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        'supported',
    };
  }
}
