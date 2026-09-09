import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';

/// The root widget. Wires the router and theming into a [MaterialApp.router].
///
/// The router is created once in `main` and passed in so hot restart does not
/// rebuild navigation state unexpectedly.
class DartMobileApp extends StatelessWidget {
  const DartMobileApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DartMobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
