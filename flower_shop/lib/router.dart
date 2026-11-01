import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'models/app_user.dart';
import 'models/list_query.dart';
import 'screens/auth_screens.dart';
import 'screens/bouquet_screens.dart';
import 'screens/cart_screen.dart';
import 'screens/category_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/flower_screens.dart';
import 'screens/forbidden_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/order_screens.dart';
import 'screens/stats_screen.dart';
import 'screens/supplier_screens.dart';
import 'screens/supply_screens.dart';
import 'screens/user_screens.dart';
import 'state/auth_notifier.dart';
import 'widgets/app_shell.dart';

String? _need(bool allowed) => allowed ? null : '/forbidden';

String _id(GoRouterState state) => state.pathParameters['id']!;

ListQuery _query(GoRouterState state, String sort, {bool ascending = true}) =>
    ListQuery.fromParams(
      state.uri.path,
      sort,
      state.uri.queryParameters,
      defaultAscending: ascending,
    );

GoRoute _crud(
  String path, {
  required String sort,
  required bool Function() canView,
  required bool Function() canEdit,
  required Widget Function(ListQuery query) list,
  required Widget Function(String id) detail,
  required Widget Function(String? id) form,
}) {
  return GoRoute(
    path: path,
    redirect: (context, state) => _need(canView()),
    builder: (context, state) => list(_query(state, sort)),
    routes: [
      GoRoute(
        path: 'new',
        redirect: (context, state) => _need(canEdit()),
        builder: (context, state) => form(null),
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) => detail(_id(state)),
        routes: [
          GoRoute(
            path: 'edit',
            redirect: (context, state) => _need(canEdit()),
            builder: (context, state) => form(_id(state)),
          ),
        ],
      ),
    ],
  );
}

GoRouter buildRouter(AuthNotifier auth) {
  bool all() => true;
  bool staff() => auth.isStaff;
  bool admin() => auth.isRole(Role.admin);

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return state.uri.queryParameters['from'] ?? '/';
      return null;
    },
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => const ForbiddenScreen(),
          ),
          _crud(
            '/bouquets',
            sort: 'name',
            canView: all,
            canEdit: staff,
            list: (q) => BouquetListScreen(query: q),
            detail: (id) => BouquetDetailScreen(id: id),
            form: (id) => BouquetFormScreen(id: id),
          ),
          _crud(
            '/categories',
            sort: 'name',
            canView: staff,
            canEdit: staff,
            list: (q) => CategoryListScreen(query: q),
            detail: (id) => CategoryDetailScreen(id: id),
            form: (id) => CategoryFormScreen(id: id),
          ),
          _crud(
            '/flowers',
            sort: 'name',
            canView: staff,
            canEdit: staff,
            list: (q) => FlowerListScreen(query: q),
            detail: (id) => FlowerDetailScreen(id: id),
            form: (id) => FlowerFormScreen(id: id),
          ),
          _crud(
            '/admin/suppliers',
            sort: 'name',
            canView: admin,
            canEdit: admin,
            list: (q) => SupplierListScreen(query: q),
            detail: (id) => SupplierDetailScreen(id: id),
            form: (id) => SupplierFormScreen(id: id),
          ),
          _crud(
            '/admin/supplies',
            sort: 'supplied_at',
            canView: admin,
            canEdit: admin,
            list: (q) => SupplyListScreen(query: q),
            detail: (id) => SupplyDetailScreen(id: id),
            form: (id) => SupplyFormScreen(id: id),
          ),
          GoRoute(
            path: '/cart',
            redirect: (context, state) => _need(auth.isRole(Role.customer)),
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/my-orders',
            redirect: (context, state) => _need(auth.isRole(Role.customer)),
            builder: (context, state) => OrderListScreen(
              query: _query(state, 'created', ascending: false),
              mine: true,
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    OrderDetailScreen(id: _id(state), mine: true),
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            redirect: (context, state) => _need(auth.isRole(Role.florist)),
            builder: (context, state) => OrderListScreen(
              query: _query(state, 'created', ascending: false),
              mine: false,
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    OrderDetailScreen(id: _id(state), mine: false),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (context, state) => _need(admin()),
            builder: (context, state) =>
                UserListScreen(query: _query(state, 'name')),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => UserDetailScreen(id: _id(state)),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (context, state) => _need(admin()),
            builder: (context, state) => const StatsScreen(),
          ),
        ],
      ),
    ],
  );
}
