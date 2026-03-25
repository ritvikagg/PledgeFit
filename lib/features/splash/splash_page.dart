import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';

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
      // Delay slightly for a smoother transition.
      Future.microtask(() => context.go(target));
    });

    return const _SplashBody();
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, size: 54, color: Color(0xFF2DD4BF)),
            const SizedBox(height: 14),
            Text(
              'Deposit Steps',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accountability with step-based penalties.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

