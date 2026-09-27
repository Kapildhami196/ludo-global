import 'package:flutter/material.dart';

import 'app/ludo_global_app.dart';
import 'features/ludo/presentation/rendering/flame_3d_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame3DRuntime.initialize();
  runApp(const LudoGlobalApp());
}
