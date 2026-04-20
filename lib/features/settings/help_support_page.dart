import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_buttons.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../services/health/health_sync_copy.dart';

/// FAQ and contact — wire mailto / ticketing API later.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static final _faqs = <(String, String)>[
    (HealthSyncCopy.faqWhyHealthTitle, HealthSyncCopy.faqWhyHealthBody),
    (HealthSyncCopy.faqPermissionsTitle, HealthSyncCopy.faqPermissionsBody),
    (HealthSyncCopy.faqDisconnectTitle, HealthSyncCopy.faqDisconnectBody),
    (HealthSyncCopy.faqNotShowingTitle, HealthSyncCopy.faqNotShowingBody),
    (HealthSyncCopy.faqHowOftenTitle, HealthSyncCopy.faqHowOftenBody),
    (
      'How do penalties work?',
      'If you miss a daily step goal, 20% of that day’s deposit is forfeited. '
          'Reaching your cumulative step target by the end date returns what’s left of your stake.',
    ),
    (
      'Can I lower my goal mid-challenge?',
      'No. You can only increase how many days you’re running or your daily step goal while active.',
    ),
    (
      'What happens if I restart?',
      'Your refundable balance for the current challenge is forfeited to the platform. '
          'You can then set a new goal from scratch.',
    ),
  ];

  static const _supportEmail = 'support@stepstake.app';

  @override
  Widget build(BuildContext context) {
    return PledgePageScaffold(
      title: 'Help & support',
      showBack: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            '${HealthSyncCopy.appName} · Help',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Questions about step sync, challenges, and your account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PledgeColors.inkMuted,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'FAQ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          ..._faqs.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PledgeColors.cardBorder),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PledgeColors.cardBorder),
                ),
                backgroundColor: PledgeColors.card,
                collapsedBackgroundColor: PledgeColors.card,
                title: Text(
                  e.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      e.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: PledgeColors.inkMuted,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PledgePrimaryButton(
            label: 'Contact support',
            icon: Icons.support_agent_rounded,
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _supportEmail));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email copied — paste it in your mail app.'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _LinkRow(
            icon: Icons.email_outlined,
            label: 'Email support',
            detail: _supportEmail,
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: _supportEmail));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied to clipboard.')),
              );
            },
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.bug_report_outlined,
            label: 'Report a problem',
            detail: 'Copies email + subject suggestion',
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '$_supportEmail\nSubject: ${HealthSyncCopy.appName} bug report\n\nDescribe what happened:',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft text copied to clipboard.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PledgeColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: PledgeColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy_rounded,
                size: 18,
                color: PledgeColors.inkMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
