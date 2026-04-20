import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/presentation.dart';
import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/circular_goal_ring.dart';
import '../../core/ui/kit/metric_tile.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/health_sync_widgets.dart';
import '../../data/models/challenge.dart';
import '../../data/models/daily_entry.dart';
import '../../data/models/wallet.dart';
import '../../services/health/health_sync_copy.dart';
import '../../services/health/health_sync_providers.dart';
import '../../services/health/health_sync_ui.dart';
import '../../services/health/step_platform.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final displayChallenge = ref.watch(displayChallengeProvider);
    final displayWallet = ref.watch(displayWalletProvider);
    final isDemo = ref.watch(isUiDemoChallengeProvider);
    final needsHealth = ref.watch(needsHealthStepSourceProvider);

    return appState.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        final nowDate = MvpDateUtils.dateOnly(DateTime.now());

        if (displayChallenge == null) {
          final strip = HealthSyncBannerViewModel.stripForNoActiveChallenge(
            isDemo: isDemo,
            devices: model.connectedDevices,
          );
          return _EmptyHome(
            onCreate: () => context.go('/goal'),
            onConnectHealth: () => context.push('/daily'),
            healthStrip: strip,
          );
        }

        final healthBanner = HealthSyncBannerViewModel.primaryForActiveChallenge(
          isDemo: isDemo,
          devices: model.connectedDevices,
          challenge: displayChallenge,
          nowDate: nowDate,
        );

        return RefreshIndicator(
          color: PledgeColors.primaryGreen,
          onRefresh: () async {
            if (isDemo) return;
            await ref.read(appControllerProvider.notifier).syncStepsFromHealth();
          },
          child: _HomeBody(
            challenge: displayChallenge,
            wallet: displayWallet,
            nowDate: nowDate,
            isDemo: isDemo,
            needsHealthConnection: needsHealth,
            lastSyncedAt: model.connectedDevices.lastSyncedAt,
            stepSyncConnected: model.connectedDevices.stepSyncConnected,
            healthBanner: healthBanner,
            onHealthRetry: () async {
              await ref.read(appControllerProvider.notifier).syncStepsFromHealth();
            },
            onInstallHealthConnect: () async {
              await ref
                  .read(healthStepDataServiceProvider)
                  .promptInstallHealthConnect();
            },
          ),
        );
      },
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({
    required this.onCreate,
    required this.onConnectHealth,
    this.healthStrip,
  });

  final VoidCallback onCreate;
  final VoidCallback onConnectHealth;
  final HealthSyncBannerViewModel? healthStrip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                HealthSyncCopy.emptyHomeTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PledgeColors.ink,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                HealthSyncCopy.emptyHomeBody,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: PledgeColors.inkMuted,
                      height: 1.45,
                    ),
              ),
              if (healthStrip != null) ...[
                const SizedBox(height: 18),
                HealthSyncBannerCard(
                  model: healthStrip!,
                  compact: true,
                  onRetrySync: healthStrip!.showRetrySync ? onConnectHealth : null,
                  onInstallHealthConnect: healthStrip!.showInstallHealthConnect
                      ? onConnectHealth
                      : null,
                ),
              ],
              const Spacer(),
              if (healthStrip?.kind == HealthSyncBannerKind.connectRequired) ...[
                PledgeSecondaryButton(
                  label: connectHealthCtaLabel(),
                  onPressed: onConnectHealth,
                ),
                const SizedBox(height: 12),
              ],
              PledgePrimaryButton(
                label: 'Set your first goal',
                icon: Icons.flag_rounded,
                onPressed: onCreate,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.challenge,
    required this.wallet,
    required this.nowDate,
    required this.isDemo,
    required this.needsHealthConnection,
    required this.lastSyncedAt,
    required this.stepSyncConnected,
    this.healthBanner,
    this.onHealthRetry,
    this.onInstallHealthConnect,
  });

  final Challenge challenge;
  final Wallet wallet;
  final DateTime nowDate;
  final bool isDemo;
  final bool needsHealthConnection;
  final DateTime? lastSyncedAt;
  final bool stepSyncConnected;
  final HealthSyncBannerViewModel? healthBanner;
  final Future<void> Function()? onHealthRetry;
  final Future<void> Function()? onInstallHealthConnect;

  @override
  Widget build(BuildContext context) {
    final currentDay = MvpDateUtils.dayNumber(challenge.startDate, nowDate)
        .clamp(1, challenge.durationDays);

    final todaysEntry = challenge.dailyEntries.firstWhere(
      (e) => MvpDateUtils.isSameDate(e.date, nowDate),
      orElse: () => challenge.dailyEntries.first,
    );

    final totalPct = (challenge.totalStepsAccumulated / challenge.totalStepGoal)
        .clamp(0.0, 1.0)
        .toDouble();
    final dailyPct =
        (todaysEntry.steps / todaysEntry.stepGoalForDay)
            .clamp(0.0, 1.0)
            .toDouble();

    final remaining =
        (challenge.totalStepGoal - challenge.totalStepsAccumulated).clamp(0, challenge.totalStepGoal);

    final missDays = challenge.dailyEntries
        .where((e) =>
            e.evaluationState == DailyEntryEvaluationState.evaluated &&
            e.dailyPenaltyAmountCents > 0)
        .length;

    final penaltyPerMiss =
        challenge.depositPerDay.cents ~/ 5; // 20% of daily deposit (cents)

    final showHeaderLastSync = healthBanner == null &&
        !isDemo &&
        stepSyncConnected &&
        lastSyncedAt != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            if (!isDemo && healthBanner != null)
              HealthSyncBannerCard(
                model: healthBanner!,
                onRetrySync: healthBanner!.showRetrySync
                    ? () async => onHealthRetry?.call()
                    : null,
                onInstallHealthConnect: healthBanner!.showInstallHealthConnect
                    ? () async => onInstallHealthConnect?.call()
                    : null,
              ),
            if (!isDemo &&
                needsHealthConnection &&
                healthBanner?.kind == HealthSyncBannerKind.connectRequired)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: HealthSyncConnectCta(
                  onPressed: () => context.push('/daily'),
                ),
              ),
            if (isDemo)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: PledgeColors.successGreenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PledgeColors.successGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 18, color: PledgeColors.successGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Investor demo — mock data. Create a challenge to use your own numbers.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: PledgeColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day $currentDay of ${challenge.durationDays}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: PledgeColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active Challenge',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: PledgeColors.ink,
                                ),
                      ),
                      if (showHeaderLastSync) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Last synced ${_formatShortTime(lastSyncedAt!)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: PledgeColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: PledgeColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: PledgeColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: PledgeColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        challenge.refundableRemainingAmount.format(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: PledgeColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: CircularGoalRing(
                progress: totalPct,
                centerTitle: '${(totalPct * 100).round()}%',
                centerSubtitle:
                    '${formatWithCommas(challenge.totalStepsAccumulated)} / ${formatWithCommas(challenge.totalStepGoal)}',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 18, color: PledgeColors.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  '${formatWithCommas(remaining)} steps remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PledgeColors.inkMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PledgeColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PledgeColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today\'s Steps',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatWithCommas(todaysEntry.steps)} / ${formatWithCommas(todaysEntry.stepGoalForDay)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: PledgeColors.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  if (!isDemo && needsHealthConnection) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Steps appear after you connect ${healthProviderDisplayName()}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.penaltyAmber,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: dailyPct,
                      minHeight: 10,
                      backgroundColor: PledgeColors.progressTrack,
                      color: PledgeColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${(dailyPct * 100).round()}% complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: PledgeColors.inkMuted,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'Miss = -${Money(penaltyPerMiss).format()} penalty',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: PledgeColors.penaltyAmber,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                PledgeMetricTile(
                  label: 'Total deposit',
                  value: challenge.totalDeposit.format(),
                ),
                PledgeMetricTile(
                  label: 'Refundable',
                  value: challenge.refundableRemainingAmount.format(),
                  valueColor: PledgeColors.successGreen,
                ),
                PledgeMetricTile(
                  label: 'Penalties',
                  value: challenge.totalPenaltyAmount.format(),
                  valueColor: PledgeColors.penaltyAmber,
                  subtitle: missDays > 0 ? '$missDays days with forfeiture' : null,
                ),
                PledgeMetricTile(
                  label: 'Wallet',
                  value: wallet.availableBalance.format(),
                  valueColor: PledgeColors.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 22),
            PledgePrimaryButton(
              label: !isDemo && needsHealthConnection
                  ? connectHealthCtaLabel()
                  : (todaysEntry.editable ? 'Sync steps' : 'View progress'),
              icon: Icons.directions_walk_rounded,
              onPressed: () {
                if (!isDemo && needsHealthConnection) {
                  context.push('/daily');
                  return;
                }
                if (todaysEntry.editable) {
                  context.push('/daily');
                } else {
                  context.go('/progress');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatShortTime(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final sfx = d.hour >= 12 ? 'PM' : 'AM';
    return '${formatMonthDay(d)} $h:$m $sfx';
  }
}
