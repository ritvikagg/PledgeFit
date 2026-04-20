import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_app_background.dart';
import '../../core/theme/pledge_colors.dart';
import '../../data/models/auth_session.dart';
import '../../data/persistence/local_storage_repository.dart';
import '../../services/auth/auth_controller.dart';
import '../../services/health/health_sync_copy.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  Future<void> _routeUnauthenticated() async {
    if (_navigated) return;
    final prefs = await SharedPreferences.getInstance();
    final done = await LocalStorageRepository(prefs).isOnboardingCompleted();
    if (!mounted || _navigated) return;
    _navigated = true;
    if (!done) {
      context.go('/onboarding');
    } else {
      context.go('/welcome');
    }
  }

  void _goAppTarget(AppModel model) {
    if (_navigated) return;
    _navigated = true;
    final target = model.shouldShowLatestResult ? '/result' : '/home';
    Future.microtask(() {
      if (mounted) context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (prev, next) {
      next.when(
        loading: () {},
        error: (_, _) => _routeUnauthenticated(),
        data: (session) {
          if (session == null) {
            _routeUnauthenticated();
          }
        },
      );
    });

    ref.listen<AsyncValue<AppModel>>(appControllerProvider, (prev, next) {
      if (_navigated) return;
      final session = ref.read(authControllerProvider).asData?.value;
      if (session == null) return;
      next.whenData(_goAppTarget);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;
      final auth = ref.read(authControllerProvider);
      auth.when(
        loading: () {},
        error: (_, _) => _routeUnauthenticated(),
        data: (session) {
          if (session == null) {
            _routeUnauthenticated();
            return;
          }
          final app = ref.read(appControllerProvider);
          app.whenData(_goAppTarget);
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PledgeAppBackground(variant: PledgeBackgroundVariant.splash),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: PledgeColors.primaryGreen,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: PledgeColors.primaryGreen
                                  .withValues(alpha: 0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: PledgeColors.energyEmber
                                  .withValues(alpha: 0.18),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        HealthSyncCopy.appName,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Walk the talk. Stake the walk.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.66),
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: PledgeColors.primaryGreen.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
