import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/presentation.dart';
import '../../app_controller/app_controller.dart';
import '../../core/date_utils.dart';
import '../../core/formatters.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/health_sync_widgets.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../services/health/health_sync_copy.dart';
import '../../services/health/health_sync_models.dart';
import '../../services/health/health_sync_providers.dart';
import '../../services/health/health_sync_ui.dart';
import '../../services/health/step_platform.dart';

/// Canonical health connection + sync hub for challenge step totals.
class StepSyncPage extends ConsumerStatefulWidget {
  const StepSyncPage({super.key});

  @override
  ConsumerState<StepSyncPage> createState() => _StepSyncPageState();
}

class _StepSyncPageState extends ConsumerState<StepSyncPage>
    with WidgetsBindingObserver {
  bool _busy = false;
  StepSyncOutcome? _lastInteraction;

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
      ref.read(healthStepDataServiceProvider).getAndroidSdkStatus();
      ref.read(appControllerProvider.notifier).syncStepsFromHealthIfEligible();
    }
  }

  Future<void> _runSync() async {
    setState(() {
      _busy = true;
      _lastInteraction = null;
    });
    final outcome =
        await ref.read(appControllerProvider.notifier).syncStepsFromHealth();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastInteraction = outcome;
    });
    if (outcome == StepSyncOutcome.success) {
      final showResult =
          ref.read(appControllerProvider).value?.shouldShowLatestResult ?? false;
      final noActive = ref.read(appControllerProvider).value?.activeChallenge == null;
      if (showResult && noActive && mounted) {
        context.go('/result');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${HealthSyncCopy.appName}: steps updated.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final challenge = ref.watch(displayChallengeProvider);
    final isDemo = ref.watch(isUiDemoChallengeProvider);
    final devices = ref.watch(appControllerProvider).value?.connectedDevices;
    final nowDate = MvpDateUtils.dateOnly(DateTime.now());

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
        if (challenge == null) {
          return PledgePageScaffold(
            title: 'Step sync',
            showBack: true,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No challenge yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set a goal first — ${HealthSyncCopy.appName} applies synced '
                    'steps to your active challenge only.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PledgeColors.inkMuted,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                  PledgePrimaryButton(
                    label: 'Set your first goal',
                    onPressed: () => context.go('/goal'),
                  ),
                ],
              ),
            ),
          );
        }

        if (isDemo) {
          return PledgePageScaffold(
            title: 'Step sync',
            showBack: true,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Investor preview uses demo data. Create a challenge on the Goal '
                  'tab to sync real steps from ${healthProviderDisplayName()}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: PledgeColors.inkMuted,
                        height: 1.45,
                      ),
                ),
              ),
            ),
          );
        }

        final todayEntry = challenge.dailyEntries.firstWhere(
          (e) => MvpDateUtils.isSameDate(e.date, nowDate),
          orElse: () => challenge.dailyEntries.first,
        );

        final connected = model.connectedDevices.stepSyncConnected;
        final lastSync = model.connectedDevices.lastSyncedAt;

        final banner = HealthSyncBannerViewModel.forStepSyncPage(
          isDemo: false,
          devices: model.connectedDevices,
          challenge: model.activeChallenge,
          nowDate: nowDate,
          lastInteraction: _lastInteraction,
        );

        return PledgePageScaffold(
          title: 'Step sync',
          showBack: true,
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (banner != null)
                HealthSyncBannerCard(
                  model: banner,
                  onRetrySync: banner.showRetrySync ? _runSync : null,
                  onInstallHealthConnect: banner.showInstallHealthConnect
                      ? () async {
                          await ref
                              .read(healthStepDataServiceProvider)
                              .promptInstallHealthConnect();
                          await ref
                              .read(healthStepDataServiceProvider)
                              .getAndroidSdkStatus();
                        }
                      : null,
                ),
              if (banner != null) const SizedBox(height: 14),
              if (!connected) ...[
                _OnboardingCard(
                  onInstallHc: isAndroidMobile
                      ? () async {
                          await ref
                              .read(healthStepDataServiceProvider)
                              .promptInstallHealthConnect();
                          await ref
                              .read(healthStepDataServiceProvider)
                              .getAndroidSdkStatus();
                        }
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PledgeColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PledgeColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: PledgeColors.inkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatWithCommas(todayEntry.steps)} / ${formatWithCommas(todayEntry.stepGoalForDay)} steps',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      HealthSyncCopy.readDataExplainer(healthProviderDisplayName()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatusRow(
                connected: connected,
                lastSync: lastSync,
                permissionGranted: devices?.permissionsGranted,
                lastSyncErrorCode: devices?.lastSyncErrorCode,
              ),
              const SizedBox(height: 20),
              PledgePrimaryButton(
                label: _busy
                    ? 'Syncingâ€¦'
                    : (connected ? 'Sync steps' : connectHealthCtaLabel()),
                isLoading: _busy,
                icon: Icons.sync_rounded,
                onPressed: (_busy || kIsWeb) ? null : _runSync,
              ),
              if (isAndroidMobile) ...[
                const SizedBox(height: 12),
                PledgeSecondaryButton(
                  label: 'Get Health Connect',
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
              const SizedBox(height: 12),
              PledgeSecondaryButton(
                label: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({this.onInstallHc});

  final VoidCallback? onInstallHc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PledgeColors.successGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PledgeColors.successGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: PledgeColors.successGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Automatic step tracking',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${HealthSyncCopy.appName} reads daily step totals from '
            '${healthProviderDisplayName()} for challenge scoring only. '
            '${HealthSyncCopy.connectToSyncSteps}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: PledgeColors.ink,
                ),
          ),
          if (onInstallHc != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onInstallHc,
              child: const Text('Open Health Connect installer'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.connected,
    required this.lastSync,
    required this.permissionGranted,
    this.lastSyncErrorCode,
  });

  final bool connected;
  final DateTime? lastSync;
  final bool? permissionGranted;
  final String? lastSyncErrorCode;

  @override
  Widget build(BuildContext context) {
    final permLabel = permissionGranted == null
        ? 'Permission: not reported (iOS may hide read access)'
        : (permissionGranted!
            ? 'Permission: granted'
            : 'Permission: denied');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PledgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            healthProviderDisplayName(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            connected ? 'Status: connected' : 'Status: not connected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: connected
                      ? PledgeColors.successGreen
                      : PledgeColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            permLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkMuted,
                ),
          ),
          if (lastSync != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last successful sync: ${formatMonthDay(lastSync!)} · ${_formatClock(lastSync!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PledgeColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (lastSyncErrorCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last sync issue: ${parseStepSyncOutcome(lastSyncErrorCode)?.name ?? lastSyncErrorCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PledgeColors.penaltyAmber,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatClock(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final sfx = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $sfx';
  }
}
