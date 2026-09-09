import 'package:go_router/go_router.dart';

import '../../features/hello_world/presentation/hello_world_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/user/domain/user.dart';
import '../../features/user/presentation/pages/user_form_page.dart';
import '../../features/user/presentation/pages/user_list_page.dart';

/// Centralised route configuration.
///
/// Route names and paths are declared as constants so the rest of the app
/// navigates by name and never hard-codes path strings.
class AppRoutes {
  const AppRoutes._();

  static const String home = 'home';
  static const String helloWorld = 'hello_world';
  static const String userList = 'user_list';
  static const String userCreate = 'user_create';
  static const String userEdit = 'user_edit';
}

/// Builds the [GoRouter] for the app. Declared as a top-level factory so it can
/// be created once in `main` and injected into `MaterialApp.router`.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoutes.home,
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'hello-world',
            name: AppRoutes.helloWorld,
            builder: (context, state) => const HelloWorldPage(),
          ),
          GoRoute(
            path: 'users',
            name: AppRoutes.userList,
            builder: (context, state) => const UserListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: AppRoutes.userCreate,
                builder: (context, state) => const UserFormPage(),
              ),
              GoRoute(
                path: 'edit',
                name: AppRoutes.userEdit,
                builder: (context, state) {
                  // The user to edit is passed via `extra` to avoid an extra
                  // fetch when navigating from the list.
                  final user = state.extra as User?;
                  return UserFormPage(user: user);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
