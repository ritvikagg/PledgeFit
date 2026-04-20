import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'root_navigator.dart';
import 'router_refresh.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/splash/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/update_goal/update_goal_page.dart';
import '../features/daily_entry/step_sync_page.dart';
import '../features/progress/challenge_progress_page.dart';
import '../features/wallet/wallet_page.dart';
import '../features/challenge_result/challenge_result_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/account_details_page.dart';
import '../features/settings/connected_devices_page.dart';
import '../features/settings/help_support_page.dart';
import '../features/settings/appeals_page.dart';
import '../services/auth/auth_controller.dart';
import '../core/ui/kit/pledge_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      if (loc == '/') {
        return null;
      }
      if (auth.isLoading) {
        return null;
      }
      final session = auth.asData?.value;
      const publicUnauthenticatedRoutes = {
        '/welcome',
        '/login',
        '/signup',
        '/onboarding',
      };
      final onPublicUnauthRoute = publicUnauthenticatedRoutes.contains(loc);
      if (session == null && !onPublicUnauthRoute) {
        return '/welcome';
      }
      if (session != null && onPublicUnauthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignUpPage(),
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
        builder: (context, state) => const StepSyncPage(),
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
