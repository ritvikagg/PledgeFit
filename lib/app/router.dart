import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'root_navigator.dart';
import '../features/splash/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/update_goal/update_goal_page.dart';
import '../features/daily_entry/daily_entry_page.dart';
import '../features/progress/challenge_progress_page.dart';
import '../features/wallet/wallet_page.dart';
import '../features/challenge_result/challenge_result_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/account_details_page.dart';
import '../features/settings/connected_devices_page.dart';
import '../features/settings/help_support_page.dart';
import '../features/settings/appeals_page.dart';
import '../core/ui/kit/pledge_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PledgeMainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goal',
                name: 'updateGoal',
                builder: (context, state) => const UpdateGoalPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                builder: (context, state) => const ChallengeProgressPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                name: 'wallet',
                builder: (context, state) => const WalletPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'account',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AccountDetailsPage(),
                  ),
                  GoRoute(
                    path: 'devices',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const ConnectedDevicesPage(),
                  ),
                  GoRoute(
                    path: 'help',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const HelpSupportPage(),
                  ),
                  GoRoute(
                    path: 'appeals',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const AppealsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/daily',
        name: 'dailyEntry',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DailyEntryPage(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChallengeResultPage(),
      ),
    ],
  );
});
