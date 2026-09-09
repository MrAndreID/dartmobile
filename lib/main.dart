import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';

/// Application entry point.
///
/// Startup order matters:
///   1. ensure the Flutter binding is ready (required before async work);
///   2. load configuration from the `.env` asset;
///   3. build the router;
///   4. run the app inside a Riverpod [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  final router = createRouter();

  runApp(
    ProviderScope(
      child: DartMobileApp(router: router),
    ),
  );
}
