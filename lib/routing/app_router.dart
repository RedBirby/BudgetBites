import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/auth/create_account_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/location/location_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/preferences/preferences_screen.dart';
import '../features/saved/saved_screen.dart';
import '../shared/widgets/app_shell.dart';
import '../state/app_controller.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(
    ref.read(appControllerProvider).session != null,
  );
  ref.listen(
    appControllerProvider,
    (_, next) => refresh.value = next.session != null,
  );
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/discover',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(appControllerProvider).session != null;
      final onAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/create-account';
      if (!signedIn) return onAuthPage ? null : '/login';
      if (onAuthPage) return '/discover';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/create-account',
        builder: (_, _) => const CreateAccountScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (_, _) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/preferences',
        builder: (_, _) => const PreferencesScreen(),
      ),
      GoRoute(path: '/location', builder: (_, _) => const LocationScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
    ],
  );
});
