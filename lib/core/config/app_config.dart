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
    required this.apiTimeout,
  });

  /// Base URL of the goapi service, e.g. `http://10.0.2.2:10001`.
  final String apiBaseUrl;

  /// Application key sent as the `X-App-Key` header on every request.
  final String apiAppKey;

  /// Connect/receive timeout for HTTP requests. Configurable via
  /// `API_TIMEOUT_SECONDS`; defaults to 15 seconds.
  final Duration apiTimeout;

  static AppConfig? _instance;

  /// The loaded configuration. Call [load] once during app start-up first.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig.load() must be called before use.');
    }
    return config;
  }

  // Compile-time values injected via `--dart-define` / `--dart-define-from-file`.
  // These take precedence over `.env` so release builds can supply secrets at
  // build time without bundling the `.env` file into the app.
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envApiAppKey = String.fromEnvironment('API_APP_KEY');
  static const String _envApiTimeoutSeconds =
      String.fromEnvironment('API_TIMEOUT_SECONDS');

  static const int _defaultTimeoutSeconds = 15;

  /// Loads and validates configuration.
  ///
  /// Resolution order for each value:
  ///   1. compile-time `--dart-define` (preferred for release builds);
  ///   2. the `.env` file (convenient for local development).
  ///
  /// The `.env` file is optional: when it is absent (e.g. a release build that
  /// relies solely on `--dart-define`) loading is skipped silently.
  ///
  /// Fails fast with a [StateError] when a required value is missing, so a
  /// misconfiguration surfaces at startup rather than as opaque 401s later.
  static Future<AppConfig> load() async {
    await _loadDotEnvIfPresent();

    final apiBaseUrl = _read(
      'API_BASE_URL',
      compileTime: _envApiBaseUrl,
      fallback: 'http://10.0.2.2:10001',
    );
    final apiAppKey = _read('API_APP_KEY', compileTime: _envApiAppKey);

    if (apiAppKey.isEmpty) {
      throw StateError(
        'API_APP_KEY is missing. Provide it via --dart-define '
        '(e.g. --dart-define-from-file=env.json) or in the .env file.',
      );
    }

    final timeoutRaw = _read(
      'API_TIMEOUT_SECONDS',
      compileTime: _envApiTimeoutSeconds,
    );
    final timeoutSeconds = int.tryParse(timeoutRaw);
    final effectiveTimeout = (timeoutSeconds != null && timeoutSeconds > 0)
        ? timeoutSeconds
        : _defaultTimeoutSeconds;

    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      apiAppKey: apiAppKey,
      apiTimeout: Duration(seconds: effectiveTimeout),
    );

    return _instance!;
  }

  /// Reads [key] from the compile-time define first, then from `.env`.
  static String _read(
    String key, {
    required String compileTime,
    String fallback = '',
  }) {
    if (compileTime.trim().isNotEmpty) return compileTime.trim();
    return dotenv.maybeGet(key, fallback: fallback)?.trim() ?? fallback;
  }

  /// Loads `.env` when it exists; ignores its absence so release builds that
  /// use only `--dart-define` do not crash on a missing file.
  static Future<void> _loadDotEnvIfPresent() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }
}
