import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme/onboarding_example_challenge.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/theme/pledge_surfaces.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../data/persistence/local_storage_repository.dart';
import '../../services/health/health_sync_copy.dart';
import '../../services/health/step_platform.dart';

/// First-launch intro — aligned with [OnboardingExampleChallenge] economics.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  static const _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await LocalStorageRepository(prefs).setOnboardingCompleted(completed: true);
    if (!mounted) return;
    context.go('/welcome');
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OnboardingHeader(
                pageIndex: _page,
                pageCount: _totalPages,
                onSkip: _finish,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _IntroGoalsPage(),
                    _ChallengeExamplePage(
                      stepsPerDay: OnboardingExampleChallenge.stepsPerDay,
                      stakePerDay:
                          OnboardingExampleChallenge.depositPerDayDollars,
                      durationDays: OnboardingExampleChallenge.durationDays,
                      totalDeposit:
                          OnboardingExampleChallenge.totalDeposit.format(),
                    ),
                    _HealthSyncPage(),
                    _EarnOrLosePage(
                      earnBackTotal:
                          OnboardingExampleChallenge.totalDeposit.format(),
                      penaltyExample: OnboardingExampleChallenge
                          .examplePenaltyPerMissedDay
                          .format(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_page > 0)
                    _BackPill(
                      onPressed: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    )
                  else
                    const SizedBox(width: 52, height: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PledgeGradientCtaButton(
                      label: _page == _totalPages - 1 ? 'Get started' : 'Continue',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.pageIndex,
    required this.pageCount,
    required this.onSkip,
  });

  final int pageIndex;
  final int pageCount;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              HealthSyncCopy.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: PledgeColors.primaryGreen,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: PledgeColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (i) {
            final active = i == pageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 26 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? PledgeColors.primaryGreen
                    : PledgeColors.progressTrack,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _IntroGoalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PledgeColors.secondaryButtonBg.withValues(alpha: 0.65),
                  ),
                ),
                _iconNode(
                  alignment: const Alignment(-0.15, -0.85),
                  icon: Icons.track_changes_rounded,
                  bg: PledgeColors.successGreenBg,
                  fg: PledgeColors.primaryGreen,
                ),
                _iconNode(
                  alignment: const Alignment(-0.95, 0.55),
                  icon: Icons.show_chart_rounded,
                  bg: PledgeColors.successGreenBg,
                  fg: PledgeColors.successGreen,
                ),
                _iconNode(
                  alignment: const Alignment(0.85, 0.55),
                  icon: Icons.account_balance_wallet_rounded,
                  bg: PledgeColors.penaltyAmberBg,
                  fg: PledgeColors.penaltyAmber,
                ),
              ],
            ),
          ),
          Text(
            'Commit to your goals',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: PledgeColors.ink,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set a goal. Put money on the line. Stay accountable.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _iconNode({
    required Alignment alignment,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: PledgeColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PledgeColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: fg, size: 32),
      ),
    );
  }
}

class _ChallengeExamplePage extends StatelessWidget {
  const _ChallengeExamplePage({
    required this.stepsPerDay,
    required this.stakePerDay,
    required this.durationDays,
    required this.totalDeposit,
  });

  final int stepsPerDay;
  final int stakePerDay;
  final int durationDays;
  final String totalDeposit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set your challenge',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: PledgeColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your daily steps, commitment amount, and duration.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: PledgeSurfaces.cardElevated(radius: 20),
            child: Column(
              children: [
                _ExampleMetricRow(
                  icon: Icons.directions_walk_rounded,
                  iconBg: PledgeColors.successGreenBg,
                  iconFg: PledgeColors.primaryGreen,
                  label: 'Steps per day',
                  value: formatWithCommas(stepsPerDay),
                ),
                const SizedBox(height: 14),
                _ExampleMetricRow(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: PledgeColors.penaltyAmberBg,
                  iconFg: PledgeColors.penaltyAmber,
                  label: 'Stake per day',
                  value: Money(stakePerDay * 100).format(),
                ),
                const SizedBox(height: 14),
                _ExampleMetricRow(
                  icon: Icons.calendar_month_rounded,
                  iconBg: PledgeColors.successGreenBg,
                  iconFg: PledgeColors.successGreen,
                  label: 'Challenge duration',
                  value: '$durationDays days',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Text(
                      'Total commitment',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: PledgeColors.inkMuted,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      totalDeposit,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: PledgeColors.ink,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Example only — you choose your real numbers when you start.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkSoft,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExampleMetricRow extends StatelessWidget {
  const _ExampleMetricRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconFg, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PledgeColors.inkMuted,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: PledgeColors.ink,
              ),
        ),
      ],
    );
  }
}

class _HealthSyncPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Steps tracked automatically',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: PledgeColors.ink,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect to ${healthProviderDisplayName()} for seamless tracking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 28),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PledgeColors.primaryGreen,
                      PledgeColors.primaryGreenDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PledgeColors.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: PledgeColors.ink.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 44,
                            color: PledgeColors.primaryGreen,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            HealthSyncCopy.appName,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: PledgeColors.ink,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PledgeColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PledgeColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: PledgeColors.dangerRose,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: PledgeColors.successGreenBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PledgeColors.successGreen.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              'Your step data syncs automatically throughout the day.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PledgeColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnOrLosePage extends StatelessWidget {
  const _EarnOrLosePage({
    required this.earnBackTotal,
    required this.penaltyExample,
  });

  final String earnBackTotal;
  final String penaltyExample;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Earn it back or lose it',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: PledgeColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your challenge to get your money back. Miss targets and face penalties.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          _OutcomeCard(
            title: 'Complete your goal',
            body:
                'Complete your step commitment (daily goal × every day) and get your remaining deposit returned.',
            icon: Icons.check_rounded,
            iconBg: PledgeColors.successGreen,
            surfaceColor: PledgeColors.successGreenBg,
            borderColor: PledgeColors.successGreen.withValues(alpha: 0.35),
            footerLabel: 'You can earn back ',
            footerHighlight: earnBackTotal,
            footerSuffix: ' if you finish strong',
            highlightColor: PledgeColors.successGreen,
          ),
          const SizedBox(height: 14),
          _OutcomeCard(
            title: 'Miss daily targets',
            body:
                'Each day you miss your step goal, part of that day’s stake is forfeited.',
            icon: Icons.priority_high_rounded,
            iconBg: PledgeColors.penaltyAmber,
            surfaceColor: PledgeColors.penaltyAmberBg,
            borderColor: PledgeColors.penaltyAmber.withValues(alpha: 0.4),
            footerLabel: 'Example at \$${OnboardingExampleChallenge.depositPerDayDollars}/day: ',
            footerHighlight: '$penaltyExample per miss',
            footerSuffix: ' (20% of that day’s stake)',
            highlightColor: PledgeColors.penaltyAmber,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: PledgeSurfaces.calloutMuted(radius: 14),
            child: Text(
              'Your commitment keeps you accountable every single day.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PledgeColors.inkMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconBg,
    required this.surfaceColor,
    required this.borderColor,
    required this.footerLabel,
    required this.footerHighlight,
    required this.footerSuffix,
    required this.highlightColor,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color iconBg;
  final Color surfaceColor;
  final Color borderColor;
  final String footerLabel;
  final String footerHighlight;
  final String footerSuffix;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: PledgeColors.ink,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: PledgeColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PledgeColors.cardBorder),
            ),
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PledgeColors.inkMuted,
                      height: 1.4,
                    ),
                children: [
                  TextSpan(text: footerLabel),
                  TextSpan(
                    text: footerHighlight,
                    style: TextStyle(
                      color: highlightColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: footerSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  const _BackPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PledgeColors.card,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PledgeColors.cardBorder),
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            color: PledgeColors.inkMuted,
            size: 26,
          ),
        ),
      ),
    );
  }
}
