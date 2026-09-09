import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/user_remote_data_source.dart';
import '../../data/user_repository_impl.dart';
import '../../domain/user.dart';
import '../../domain/user_repository.dart';

/// Dependency wiring for the user feature.
///
/// Providers are declared top-to-bottom in dependency order: data source →
/// repository → list controller. The presentation widgets only ever watch the
/// [userRepositoryProvider] and [userListControllerProvider].

final _userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(apiClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(_userRemoteDataSourceProvider));
});

/// Holds the current search term used by the list. Kept separate so typing in
/// the search box does not rebuild unrelated widgets.
final userSearchProvider = StateProvider<String>((ref) => '');

/// Page size used when loading the user list.
const int kUserPageSize = 20;

/// Loads and exposes a paginated list of users, reacting to
/// [userSearchProvider]. Supports load-more (infinite scroll) via [loadMore].
final userListControllerProvider =
    AsyncNotifierProvider<UserListController, UserListState>(
  UserListController.new,
);

/// Presentation-facing state for the user list.
///
/// Wraps the loaded [users] together with the pagination cursor ([nextPage],
/// [hasNextPage]) and a transient [isLoadingMore] flag so the UI can show a
/// footer spinner without replacing the whole list with a loading indicator.
class UserListState extends Equatable {
  const UserListState({
    required this.users,
    required this.nextPage,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  final List<User> users;
  final int nextPage;
  final bool hasNextPage;
  final bool isLoadingMore;

  UserListState copyWith({
    List<User>? users,
    int? nextPage,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) {
    return UserListState(
      users: users ?? this.users,
      nextPage: nextPage ?? this.nextPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [users, nextPage, hasNextPage, isLoadingMore];
}

class UserListController extends AsyncNotifier<UserListState> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  Future<UserListState> build() async {
    // Rebuild the first page whenever the search term changes.
    final search = ref.watch(userSearchProvider);
    final result = await _repository.fetchUsers(
      page: 1,
      limit: kUserPageSize,
      search: search,
    );
    return UserListState(
      users: result.users,
      nextPage: 2,
      hasNextPage: result.hasNextPage,
    );
  }

  /// Re-fetches the first page, e.g. for pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final search = ref.read(userSearchProvider);
      final result = await _repository.fetchUsers(
        page: 1,
        limit: kUserPageSize,
        search: search,
      );
      return UserListState(
        users: result.users,
        nextPage: 2,
        hasNextPage: result.hasNextPage,
      );
    });
  }

  /// Appends the next page to the current list. No-op while a page is already
  /// loading, when there is no further page, or before the first load settles.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasNextPage) {
      return;
    }

    // Show the footer spinner without dropping the already-loaded users.
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final search = ref.read(userSearchProvider);
      final result = await _repository.fetchUsers(
        page: current.nextPage,
        limit: kUserPageSize,
        search: search,
      );
      state = AsyncValue.data(
        current.copyWith(
          users: [...current.users, ...result.users],
          nextPage: current.nextPage + 1,
          hasNextPage: result.hasNextPage,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      // Keep the existing list; surface the error via the async state.
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Deletes [id] then refreshes so the list reflects the change.
  Future<void> delete(String id) async {
    await _repository.deleteUser(id);
    await refresh();
  }
}
