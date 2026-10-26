import 'dart:async';

import 'package:flutter/material.dart';

import 'app/ludo_global_app.dart';
import 'core/ads/ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LudoGlobalApp());

  // UMP needs an attached activity to display its consent form.
  // Do not hold up offline gameplay while consent or ads are loading.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AdService.instance.initialize());
  });
}
