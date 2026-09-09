import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// A thin wrapper around [Dio] that centralises everything specific to the
/// goapi service:
///
///  * base URL and timeouts from [AppConfig];
///  * the `X-App-Key` authentication header on every request;
///  * decoding the `{code, description, data}` envelope;
///  * converting [DioException]s into a uniform [ApiException].
///
/// Feature data sources depend on this client rather than on Dio directly, so
/// transport concerns stay in one place.
class ApiClient {
  ApiClient({Dio? dio, AppConfig? config})
      : _config = config ?? AppConfig.instance,
        _dio = dio ?? Dio() {
    final cfg = _config;
    _dio.options = _dio.options.copyWith(
      baseUrl: cfg.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      headers: {
        'X-App-Key': cfg.apiAppKey,
        'Accept': Headers.jsonContentType,
      },
    );

    // Log requests/responses only in debug builds. `avoid_print` is satisfied
    // because Dio's LogInterceptor writes via the provided `logPrint` callback,
    // and we route it through `debugPrint`.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (Object? object) => debugPrint(object?.toString()),
        ),
      );
    }
  }

  final Dio _dio;
  final AppConfig _config;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () => _dio.get(path, queryParameters: queryParameters),
    );
  }

  Future<ApiResponse> post(String path, {Object? data}) {
    return _request(() => _dio.post(path, data: data));
  }

  Future<ApiResponse> patch(String path, {Object? data}) {
    return _request(() => _dio.patch(path, data: data));
  }

  Future<ApiResponse> delete(String path, {Object? data}) {
    return _request(() => _dio.delete(path, data: data));
  }

  /// Executes [send], normalises the outcome and always returns a decoded
  /// [ApiResponse] for success, or throws an [ApiException] otherwise.
  Future<ApiResponse> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      final body = response.data;

      if (body is! Map<String, dynamic>) {
        throw const ParsingException('Malformed response body.');
      }

      final envelope = ApiResponse.fromJson(body);
      if (!envelope.isSuccess) {
        throw ApiException(
          envelope.description.isNotEmpty
              ? envelope.description
              : 'Request failed.',
          statusCode: response.statusCode,
          code: envelope.code,
        );
      }

      return envelope;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  ApiException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('The connection timed out.');
      case DioExceptionType.connectionError:
        return const ApiException('Could not reach the server.');
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final description = data is Map<String, dynamic>
            ? (data['description']?.toString() ?? 'Request failed.')
            : 'Request failed.';
        final code =
            data is Map<String, dynamic> ? data['code']?.toString() : null;
        return ApiException(
          description,
          statusCode: error.response?.statusCode,
          code: code,
        );
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('Invalid server certificate.');
      // `unknown` and any other/legacy variant (e.g. the deprecated
      // `transformTimeout`) fall through here so the switch stays exhaustive
      // across Dio versions.
      default:
        return ApiException(error.message ?? 'An unexpected error occurred.');
    }
  }
}
