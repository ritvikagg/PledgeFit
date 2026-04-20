import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../services/auth/auth_controller.dart';
import '../../services/health/health_sync_copy.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authBusy = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: PledgeColors.primaryGreen,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:
                            PledgeColors.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                HealthSyncCopy.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Walk the talk. Stake the walk.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: PledgeColors.inkMuted,
                      height: 1.35,
                    ),
              ),
              const Spacer(flex: 2),
              PledgePrimaryButton(
                label: 'Log in',
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 12),
              PledgeSecondaryButton(
                label: 'Sign up',
                onPressed: () => context.push('/signup'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: authBusy
                    ? null
                    : () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogleMock();
                        if (!context.mounted) return;
                        final auth = ref.read(authControllerProvider);
                        if (auth.hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error.toString())),
                          );
                          return;
                        }
                        ref.invalidate(appControllerProvider);
                        if (!context.mounted) return;
                        context.go('/home');
                      },
                icon: authBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded, size: 22),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PledgeColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: PledgeColors.border),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Google sign-in is simulated on this build — swap in real OAuth later.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PledgeColors.inkMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
