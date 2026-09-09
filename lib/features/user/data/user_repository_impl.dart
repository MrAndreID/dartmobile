import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../domain/paginated_users.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';
import 'user_remote_data_source.dart';

/// Concrete [UserRepository] backed by the goapi remote data source.
///
/// Its job is to (a) call the data source, (b) map DTOs to domain entities, and
/// (c) translate transport [ApiException]s into domain [Failure]s so the
/// presentation layer deals only with a small, stable error vocabulary.
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remote);

  final UserRemoteDataSource _remote;

  @override
  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return _guard(() async {
      final result =
          await _remote.read(page: page, limit: limit, search: search);
      return PaginatedUsers(
        users: result.users.map((dto) => dto.toDomain()).toList(),
        total: result.total,
        hasNextPage: result.nextPage,
      );
    });
  }

  @override
  Future<User> createUser({
    required String name,
    required List<String> emails,
  }) {
    return _guard(() async {
      final dto = await _remote.create(name: name, emails: emails);
      return dto.toDomain();
    });
  }

  @override
  Future<void> updateUser({
    required String id,
    String? name,
    List<String>? emails,
  }) {
    return _guard(() => _remote.update(id: id, name: name, emails: emails));
  }

  @override
  Future<void> deleteUser(String id) {
    return _guard(() => _remote.delete(id));
  }

  /// Runs [action] and converts any thrown error into the matching [Failure].
  ///
  /// Transport errors arrive as [ApiException] (and its [ParsingException]
  /// subtype); anything else is treated as an [UnknownFailure] so no raw error
  /// ever escapes to the presentation layer.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ParsingException catch (error) {
      throw ParsingFailure(error.message);
    } on ApiException catch (error) {
      throw _mapException(error);
    } on Failure {
      rethrow;
    } catch (error) {
      throw UnknownFailure(error.toString());
    }
  }

  Failure _mapException(ApiException error) {
    if (error.isNetworkError) {
      return NetworkFailure(error.message);
    }
    return ServerFailure(error.message, code: error.code);
  }
}
