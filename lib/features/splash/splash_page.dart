import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppModel>>(appControllerProvider, (prev, next) {
      if (_navigated) return;
      if (!next.hasValue) return;

      _navigated = true;
      final model = next.value!;
      final target = model.shouldShowLatestResult ? '/result' : '/home';
      Future.microtask(() {
        if (context.mounted) context.go(target);
      });
    });

    return Scaffold(
      backgroundColor: PledgeColors.splashBg,
      body: SafeArea(
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
                          color: PledgeColors.primaryGreen.withValues(alpha: 0.35),
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
                  const SizedBox(height: 28),
                  Text(
                    'PledgeFit',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
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
                color: PledgeColors.primaryGreen.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
