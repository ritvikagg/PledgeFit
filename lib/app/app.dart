import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class StartupApp extends ConsumerWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Deposit Steps MVP',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        // While loading state, show the splash route content.
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

