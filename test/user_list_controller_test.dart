import 'package:dart_mobile/features/user/domain/paginated_users.dart';
import 'package:dart_mobile/features/user/domain/user.dart';
import 'package:dart_mobile/features/user/domain/user_repository.dart';
import 'package:dart_mobile/features/user/presentation/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repository returning two pages so we can exercise load-more.
class _FakeUserRepository implements UserRepository {
  int fetchCalls = 0;

  User _user(String id) => User(id: id, name: 'User $id', emails: const []);

  @override
  Future<PaginatedUsers> fetchUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    fetchCalls++;
    if (page == 1) {
      return PaginatedUsers(
        users: [_user('1'), _user('2')],
        total: 4,
        hasNextPage: true,
      );
    }
    return PaginatedUsers(
      users: [_user('3'), _user('4')],
      total: 4,
      hasNextPage: false,
    );
  }

  @override
  Future<User> createUser({
    required String name,
    required List<String> emails,
  }) async =>
      _user('new');

  @override
  Future<void> updateUser({
    required String id,
    String? name,
    List<String>? emails,
  }) async {}

  @override
  Future<void> deleteUser(String id) async {}
}

void main() {
  test('loadMore appends the next page and stops at the end', () async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      ],
    );
    addTearDown(container.dispose);

    // First page.
    final first = await container.read(userListControllerProvider.future);
    expect(first.users.map((u) => u.id), ['1', '2']);
    expect(first.hasNextPage, isTrue);
    expect(first.nextPage, 2);

    // Load the second (final) page.
    await container.read(userListControllerProvider.notifier).loadMore();
    final second = container.read(userListControllerProvider).requireValue;
    expect(second.users.map((u) => u.id), ['1', '2', '3', '4']);
    expect(second.hasNextPage, isFalse);

    // No further pages: loadMore is a no-op.
    await container.read(userListControllerProvider.notifier).loadMore();
    final third = container.read(userListControllerProvider).requireValue;
    expect(third.users.length, 4);
  });
}
