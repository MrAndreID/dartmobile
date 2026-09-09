import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/user_dto.dart';

/// Talks to the goapi `/api/v1/user` endpoints.
///
/// This is the only class in the feature that knows the concrete URLs, query
/// parameters and JSON shapes. It returns DTOs (or a small raw record) and
/// throws [ApiException] on failure; mapping to domain/failures happens in the
/// repository.
class UserRemoteDataSource {
  const UserRemoteDataSource(this._client);

  final ApiClient _client;

  static const String _basePath = '/api/v1/user';

  /// GET /api/v1/user — returns the paginator payload as a raw map plus the
  /// parsed list of users.
  Future<({List<UserDto> users, int total, bool nextPage})> read({
    required int page,
    required int limit,
    String? search,
  }) async {
    final response = await _client.get(
      _basePath,
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.dataAsMap;
    if (data == null) {
      throw const ParsingException('Malformed user list payload.');
    }

    final rawRecords = data['records'];
    final users = rawRecords is List
        ? rawRecords
            .whereType<Map<String, dynamic>>()
            .map(UserDto.fromJson)
            .toList()
        : <UserDto>[];

    final total = (data['total'] as num?)?.toInt() ?? users.length;
    final nextPage = data['nextPage'] == true;

    return (users: users, total: total, nextPage: nextPage);
  }

  /// POST /api/v1/user
  Future<UserDto> create({
    required String name,
    required List<String> emails,
  }) async {
    final response = await _client.post(
      _basePath,
      data: {'name': name, 'emails': emails},
    );

    final data = response.dataAsMap;
    if (data == null) {
      throw const ParsingException('Malformed create-user response.');
    }
    return UserDto.fromJson(data);
  }

  /// PATCH /api/v1/user/:id
  Future<void> update({
    required String id,
    String? name,
    List<String>? emails,
  }) async {
    await _client.patch(
      '$_basePath/$id',
      data: {
        if (name != null) 'name': name,
        if (emails != null) 'emails': emails,
      },
    );
  }

  /// DELETE /api/v1/user/:id
  Future<void> delete(String id) async {
    await _client.delete('$_basePath/$id');
  }
}
