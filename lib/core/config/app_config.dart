import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised, typed access to environment configuration.
///
/// Values are loaded from the `.env` asset at startup (see [AppConfig.load]).
/// Keeping all env reads in one place avoids scattering `dotenv.env[...]`
/// look-ups across the codebase and gives us a single source of truth.
class AppConfig {
  const AppConfig._({
    required this.apiBaseUrl,
    required this.apiAppKey,
  });

  /// Base URL of the goapi service, e.g. `http://10.0.2.2:10001`.
  final String apiBaseUrl;

  /// Application key sent as the `X-App-Key` header on every request.
  final String apiAppKey;

  static AppConfig? _instance;

  /// The loaded configuration. Call [load] once during app start-up first.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig.load() must be called before use.');
    }
    return config;
  }

  /// Loads and validates configuration from the `.env` asset.
  ///
  /// Fails fast with a [StateError] when a required value is missing, so a
  /// misconfiguration surfaces at startup rather than as opaque 401s later.
  static Future<AppConfig> load() async {
    await dotenv.load(fileName: '.env');

    final apiBaseUrl =
        dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:10001').trim();
    final apiAppKey = dotenv.get('API_APP_KEY', fallback: '').trim();

    if (apiAppKey.isEmpty) {
      throw StateError(
        'API_APP_KEY is missing from .env. Set it to the goapi APP_KEY value.',
      );
    }

    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      apiAppKey: apiAppKey,
    );

    return _instance!;
  }
}
