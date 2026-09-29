import 'package:flutter/material.dart';

import 'app/ludo_global_app.dart';
import 'core/ads/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  runApp(const LudoGlobalApp());
}
