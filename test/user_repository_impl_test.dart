import 'package:dart_mobile/core/error/failure.dart';
import 'package:dart_mobile/core/network/api_exception.dart';
import 'package:dart_mobile/features/user/data/user_remote_data_source.dart';
import 'package:dart_mobile/features/user/data/user_repository_impl.dart';
import 'package:dart_mobile/features/user/data/models/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [UserRemoteDataSource] whose `read` throws whatever error is configured,
/// letting us assert the repository's exception-to-[Failure] mapping without a
/// real HTTP client.
class _ThrowingDataSource implements UserRemoteDataSource {
  _ThrowingDataSource(this.error);

  final Object error;

  @override
  Future<({List<UserDto> users, int total, bool nextPage})> read({
    required int page,
    required int limit,
    String? search,
  }) async {
    throw error;
  }

  @override
  Future<UserDto> create({
    required String name,
    required List<String> emails,
  }) =>
      throw error;

  @override
  Future<void> update({
    required String id,
    String? name,
    List<String>? emails,
  }) =>
      throw error;

  @override
  Future<void> delete(String id) => throw error;
}

void main() {
  group('UserRepositoryImpl exception mapping', () {
    test('network ApiException -> NetworkFailure', () {
      final repo = UserRepositoryImpl(
        _ThrowingDataSource(const ApiException('offline')),
      );

      expect(
        () => repo.fetchUsers(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('ApiException with status -> ServerFailure (keeps code)', () async {
      final repo = UserRepositoryImpl(
        _ThrowingDataSource(
          const ApiException('boom', statusCode: 500, code: '0500'),
        ),
      );

      await expectLater(
        repo.fetchUsers(),
        throwsA(
          isA<ServerFailure>().having((f) => f.code, 'code', '0500'),
        ),
      );
    });

    test('ParsingException -> ParsingFailure', () {
      final repo = UserRepositoryImpl(
        _ThrowingDataSource(const ParsingException('bad json')),
      );

      expect(
        () => repo.fetchUsers(),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('unexpected error -> UnknownFailure', () {
      final repo = UserRepositoryImpl(
        _ThrowingDataSource(StateError('unexpected')),
      );

      expect(
        () => repo.fetchUsers(),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
