import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_controller/app_controller.dart';
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

class ConnectedDevicesPage extends ConsumerStatefulWidget {
  const ConnectedDevicesPage({super.key});

  @override
  ConsumerState<ConnectedDevicesPage> createState() =>
      _ConnectedDevicesPageState();
}

class _ConnectedDevicesPageState extends ConsumerState<ConnectedDevicesPage> {
  bool _busy = false;

  Future<void> _sync() async {
    setState(() => _busy = true);
    final outcome =
        await ref.read(appControllerProvider.notifier).syncStepsFromHealth();
    if (!mounted) return;
    setState(() => _busy = false);
    final msg = _syncMessage(outcome);
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await ref.read(appControllerProvider.notifier).disconnectHealth();
    if (!mounted) return;
    setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Disconnected. ${HealthSyncCopy.disconnectProgressStalls}',
          ),
        ),
      );
    }
  }

  String? _syncMessage(StepSyncOutcome o) {
    switch (o) {
      case StepSyncOutcome.success:
        return 'Steps synced successfully.';
      case StepSyncOutcome.noActiveChallenge:
        return 'No active challenge to sync.';
      case StepSyncOutcome.unsupportedPlatform:
        return 'Health sync requires iOS or Android.';
      case StepSyncOutcome.healthConnectUnavailable:
        return 'Health Connect is not ready on this device.';
      case StepSyncOutcome.healthConnectNotInstalled:
        return 'Install Health Connect from the Play Store.';
      case StepSyncOutcome.activityPermissionDenied:
        return 'Activity recognition is required.';
      case StepSyncOutcome.healthPermissionDenied:
        return 'Health data access was denied.';
      case StepSyncOutcome.syncFailed:
        return 'Sync failed. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider).value;
    final devices = app?.connectedDevices;
    final connected = devices?.stepSyncConnected ?? false;
    final lastSync = devices?.lastSyncedAt;
    final perm = devices?.permissionsGranted;
    final err = devices?.lastSyncErrorCode;

    final banner = devices != null
        ? HealthSyncBannerViewModel.forProgress(
            isDemo: false,
            hasActiveChallenge: app?.activeChallenge != null,
            devices: devices,
          )
        : null;

    return PledgePageScaffold(
      title: 'Health connection',
      showBack: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            HealthSyncCopy.readDataExplainer(healthProviderDisplayName()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          if (isAndroidMobile)
            FutureBuilder(
              future: ref.read(healthStepDataServiceProvider).getAndroidSdkStatus(),
              builder: (context, snap) {
                final s = snap.data;
                final label = s == null
                    ? 'Checking Health Connect…'
                    : 'Health Connect on device: $s';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PledgeColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              },
            ),
          if (banner != null)
            HealthSyncBannerCard(
              model: banner,
              onRetrySync: banner.showRetrySync ? _sync : null,
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
          if (banner != null) const SizedBox(height: 16),
          _StatusCard(
            title: healthProviderDisplayName(),
            connected: connected,
            permissionGranted: perm,
            lastSync: lastSync,
            lastErrorCode: err,
          ),
          const SizedBox(height: 20),
          PledgePrimaryButton(
            label: _busy
                ? 'Working…'
                : (connected ? 'Resync steps' : connectHealthCtaLabel()),
            isLoading: _busy,
            icon: Icons.sync_rounded,
            onPressed: kIsWeb || _busy ? null : _sync,
          ),
          const SizedBox(height: 10),
          if (!connected)
            PledgeSecondaryButton(
              label: 'Open system settings',
              onPressed: () => openAppSettings(),
            ),
          const SizedBox(height: 12),
          PledgeSecondaryButton(
            label: 'Install Health Connect',
            onPressed: !isAndroidMobile
                ? null
                : () async {
                    final uri = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
          ),
          const SizedBox(height: 12),
          PledgeSecondaryButton(
            label: 'Disconnect',
            onPressed: (!connected || _busy) ? null : _disconnect,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.connected,
    required this.permissionGranted,
    required this.lastSync,
    required this.lastErrorCode,
  });

  final String title;
  final bool connected;
  final bool? permissionGranted;
  final DateTime? lastSync;
  final String? lastErrorCode;

  @override
  Widget build(BuildContext context) {
    final permText = permissionGranted == null
        ? 'Permission: not reported (iOS may hide read access)'
        : (permissionGranted!
            ? 'Permission: granted'
            : 'Permission: denied');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PledgeColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: PledgeColors.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: connected
                      ? PledgeColors.successGreenBg
                      : PledgeColors.secondaryButtonBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  connected ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: connected
                        ? PledgeColors.successGreen
                        : PledgeColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            permText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.4,
                ),
          ),
          if (lastSync != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last successful sync: ${formatMonthDay(lastSync!)} · ${_clock(lastSync!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PledgeColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (lastErrorCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last issue: ${parseStepSyncOutcome(lastErrorCode)?.name ?? lastErrorCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PledgeColors.penaltyAmber,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your previous successful sync time stays visible until a new sync succeeds.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PledgeColors.inkSoft,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _clock(DateTime d) {
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final sfx = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $sfx';
  }
}
