import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/health/health_sync_ui.dart';
import '../../../services/health/step_platform.dart';
import '../../theme/pledge_colors.dart';
import 'pledge_buttons.dart';

/// Renders the resolved [HealthSyncBannerViewModel] with consistent styling.
class HealthSyncBannerCard extends StatelessWidget {
  const HealthSyncBannerCard({
    super.key,
    required this.model,
    this.onRetrySync,
    this.onInstallHealthConnect,
    this.compact = false,
  });

  final HealthSyncBannerViewModel model;
  final VoidCallback? onRetrySync;
  final VoidCallback? onInstallHealthConnect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isError = model.kind == HealthSyncBannerKind.syncFailed ||
        model.kind == HealthSyncBannerKind.permissionDenied ||
        model.kind == HealthSyncBannerKind.healthConnectUnavailable ||
        model.kind == HealthSyncBannerKind.activityPermissionDenied;

    final isSuccess = model.kind == HealthSyncBannerKind.connectedOk ||
        model.kind == HealthSyncBannerKind.noChallengeHealthConnected;

    final bg = isError
        ? PledgeColors.penaltyAmberBg
        : (isSuccess
            ? PledgeColors.successGreenBg
            : PledgeColors.penaltyAmberBg);
    final border = isError
        ? PledgeColors.penaltyAmber.withValues(alpha: 0.35)
        : (isSuccess
            ? PledgeColors.successGreen.withValues(alpha: 0.25)
            : PledgeColors.penaltyAmber.withValues(alpha: 0.35));

    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                size: compact ? 18 : 20,
                color: isSuccess
                    ? PledgeColors.successGreen
                    : PledgeColors.penaltyAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  model.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: PledgeColors.ink,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            model.body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.4,
                ),
          ),
          if (model.lastGoodSyncLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last good sync: ${model.lastGoodSyncLabel}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PledgeColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (model.showOpenSettings ||
              model.showInstallHealthConnect ||
              model.showRetrySync) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (model.showRetrySync)
                  TextButton.icon(
                    onPressed: onRetrySync,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Retry sync'),
                  ),
                if (model.showOpenSettings)
                  TextButton.icon(
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Open settings'),
                  ),
                if (model.showInstallHealthConnect)
                  TextButton.icon(
                    onPressed:
                        onInstallHealthConnect ?? () => _openPlayStoreHc(),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Get Health Connect'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPlayStoreHc() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Primary CTA row used under banners on Home.
class HealthSyncConnectCta extends StatelessWidget {
  const HealthSyncConnectCta({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PledgePrimaryButton(
      label: connectHealthCtaLabel(),
      icon: Icons.favorite_rounded,
      onPressed: onPressed,
    );
  }
}
