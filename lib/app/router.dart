import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/splash/splash_page.dart';
import '../features/home/home_page.dart';
import '../features/create_challenge/create_challenge_page.dart';
import '../features/daily_entry/daily_entry_page.dart';
import '../features/progress/challenge_progress_page.dart';
import '../features/wallet/wallet_page.dart';
import '../features/challenge_result/challenge_result_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/create',
        name: 'createChallenge',
        builder: (context, state) => const CreateChallengePage(),
      ),
      GoRoute(
        path: '/daily',
        name: 'dailyEntry',
        builder: (context, state) => const DailyEntryPage(),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ChallengeProgressPage(),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => const ChallengeResultPage(),
      ),
    ],
  );
});

