import 'paginated_users.dart';
import 'user.dart';

/// The contract the presentation layer depends on for user data.
///
/// Defining the interface in the domain layer keeps the presentation layer
/// decoupled from the concrete data source (Dio/goapi). It also makes the
/// repository trivially mockable in tests.
abstract interface class UserRepository {
  /// Fetches a page of users.
  ///
  /// [search] filters by name; [page] is 1-based; [limit] caps page size.
  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int limit = 20,
    String? search,
  });

  /// Creates a user with the given [name] and [emails]. Returns the created
  /// resource as echoed back by the server.
  Future<User> createUser({
    required String name,
    required List<String> emails,
  });

  /// Updates the user identified by [id]. Fields left null are unchanged.
  Future<void> updateUser({
    required String id,
    String? name,
    List<String>? emails,
  });

  /// Permanently deletes the user identified by [id].
  Future<void> deleteUser(String id);
}
