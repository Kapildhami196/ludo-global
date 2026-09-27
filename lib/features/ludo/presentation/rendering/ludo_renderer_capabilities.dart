import 'package:flutter/foundation.dart';

abstract final class LudoRendererCapabilities {
  static const bool force2D = bool.fromEnvironment(
    'LUDO_FORCE_2D',
    defaultValue: false,
  );

  static bool get supportsFlame3D {
    if (force2D || kIsWeb) {
      return false;
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
}
