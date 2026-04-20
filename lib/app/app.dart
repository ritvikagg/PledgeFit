import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_controller/app_controller.dart';
import '../services/auth/auth_controller.dart';
import 'router.dart';
import '../core/theme/pledge_app_background.dart';
import 'theme.dart';

class StartupApp extends ConsumerStatefulWidget {
  const StartupApp({super.key});

  @override
  ConsumerState<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends ConsumerState<StartupApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb) {
      final session = ref.read(authControllerProvider).asData?.value;
      if (session == null) return;
      ref.read(appControllerProvider.notifier).syncStepsFromHealthIfEligible();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'StepStake',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: PledgeAppBackground()),
            child,
          ],
        );
      },
    );
  }
}

