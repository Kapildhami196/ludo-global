import 'package:flutter/material.dart';

import '../core/theme/ludo_global_theme.dart';
import '../features/splash/presentation/splash_screen.dart';

class LudoGlobalApp extends StatelessWidget {
  const LudoGlobalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Global',
      debugShowCheckedModeBanner: false,
      theme: LudoGlobalTheme.dark,
      home: const SplashScreen(),
    );
  }
}
