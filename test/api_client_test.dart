import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_mobile/core/config/app_config.dart';
import 'package:dart_mobile/core/network/api_client.dart';
import 'package:dart_mobile/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [HttpClientAdapter] that returns a canned response or throws a canned
/// [DioException], so we can drive [ApiClient] without real network I/O.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({this.responseBody, this.throwError});

  final Object? responseBody;
  static const int _statusCode = 200;
  final DioException? throwError;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final error = throwError;
    if (error != null) {
      // Re-associate the error with the actual request options.
      throw error.copyWith(requestOptions: options);
    }
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      _statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// Builds an [ApiClient] whose Dio uses [adapter], sharing the loaded config.
ApiClient _clientWith(_StubAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(dio: dio, config: AppConfig.instance);
}

void main() {
  setUpAll(() async {
    // Provide config in-memory (no .env asset needed under flutter test).
    dotenv.testLoad(
      fileInput: 'API_BASE_URL=http://localhost:10001\n'
          'API_APP_KEY=test-key\n',
    );
    await AppConfig.load();
  });

  group('ApiClient success', () {
    test('decodes a success envelope and exposes data', () async {
      final client = _clientWith(
        _StubAdapter(
          responseBody: {
            'code': '0200',
            'description': 'OK',
            'data': {'id': '1'},
          },
        ),
      );

      final response = await client.get('/ping');

      expect(response.isSuccess, isTrue);
      expect(response.code, '0200');
      expect(response.dataAsMap, {'id': '1'});
    });

    test('throws ApiException when the envelope reports a non-2xx code',
        () async {
      final client = _clientWith(
        _StubAdapter(
          responseBody: {
            'code': '0422',
            'description': 'Validation failed',
            'data': null,
          },
        ),
      );

      await expectLater(
        client.get('/users'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Validation failed')
              .having((e) => e.code, 'code', '0422'),
        ),
      );
    });

    test('throws ParsingException when the body is not a JSON object',
        () async {
      final client = _clientWith(_StubAdapter(responseBody: 'not-an-object'));

      await expectLater(
        client.get('/users'),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('ApiClient maps DioException', () {
    ApiClient clientThatThrows(DioExceptionType type, {Response? response}) {
      return _clientWith(
        _StubAdapter(
          throwError: DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: type,
            response: response,
          ),
        ),
      );
    }

    test('connectionTimeout -> network ApiException (no status)', () async {
      final client = clientThatThrows(DioExceptionType.connectionTimeout);

      await expectLater(
        client.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue),
        ),
      );
    });

    test('connectionError -> network ApiException', () async {
      final client = clientThatThrows(DioExceptionType.connectionError);

      await expectLater(
        client.get('/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });

    test('badResponse -> ApiException carrying status code and code', () async {
      final client = clientThatThrows(
        DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
          data: {'code': '0500', 'description': 'Server exploded'},
        ),
      );

      await expectLater(
        client.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', '0500')
              .having((e) => e.message, 'message', 'Server exploded'),
        ),
      );
    });
  });
}
