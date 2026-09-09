import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/user.dart';
import '../providers/user_providers.dart';
import '../widgets/error_view.dart';

/// Lists users with search, pull-to-refresh, infinite scroll, and per-row
/// edit/delete actions.
class UserListPage extends ConsumerWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // Pop back to the previous screen when possible, falling back to the
          // home route (e.g. on deep links that open the list directly).
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoutes.home),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.userCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New user'),
      ),
      body: Column(
        children: [
          const _SearchField(),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.read(userListControllerProvider.notifier).refresh(),
              ),
              data: (listState) => _UserList(listState: listState),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(userSearchProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Pushes the search term into the provider after a short idle period so we
  /// do not fire a request on every keystroke.
  void _onChanged(String value) {
    setState(() {}); // Reflect the clear-button visibility immediately.
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref.read(userSearchProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _debounce?.cancel();
                    _controller.clear();
                    ref.read(userSearchProvider.notifier).state = '';
                    setState(() {});
                  },
                ),
        ),
        onChanged: _onChanged,
        onSubmitted: (value) {
          _debounce?.cancel();
          ref.read(userSearchProvider.notifier).state = value.trim();
        },
      ),
    );
  }
}

class _UserList extends ConsumerStatefulWidget {
  const _UserList({required this.listState});

  final UserListState listState;

  @override
  ConsumerState<_UserList> createState() => _UserListState();
}

class _UserListState extends ConsumerState<_UserList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Triggers a load-more when the user scrolls near the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(userListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.listState.users;
    final isLoadingMore = widget.listState.isLoadingMore;
    // One extra slot for the footer spinner while loading the next page.
    final itemCount = users.length + (isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(userListControllerProvider.notifier).refresh(),
      child: users.isEmpty
          ? ListView(
              controller: _scrollController,
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No users yet. Tap "New user" to add one.')),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= users.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _UserTile(user: users[index]);
              },
            ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        ),
      ),
      title: Text(user.name),
      subtitle: Text(user.emailSummary),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              context.pushNamed(AppRoutes.userEdit, extra: user);
            case 'delete':
              _confirmDelete(context, ref);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => context.pushNamed(AppRoutes.userEdit, extra: user),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete "${user.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(userListControllerProvider.notifier).delete(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${user.name}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $error')),
        );
      }
    }
  }
}
