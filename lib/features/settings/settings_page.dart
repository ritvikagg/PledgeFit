import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../services/auth/auth_controller.dart';

/// Hub for local mock settings. Wire navigation to real auth / APIs later.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).asData?.value;

    return PledgePageScaffold(
      title: 'Settings',
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _SettingsGroup(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Account details',
                subtitle: session == null
                    ? 'Name, username, email'
                    : session.fullName.isNotEmpty
                        ? session.fullName
                        : session.email,
                onTap: () => context.push('/settings/account'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Devices',
            children: [
              _SettingsTile(
                icon: Icons.watch_later_outlined,
                label: 'Connected devices',
                subtitle: 'Apple Health, Health Connect',
                onTap: () => context.push('/settings/devices'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Support',
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                subtitle: 'FAQ and contact',
                onTap: () => context.push('/settings/help'),
              ),
              _SettingsTile(
                icon: Icons.gavel_outlined,
                label: 'Appeals',
                subtitle: 'Challenge outcomes & penalties',
                onTap: () => context.push('/settings/appeals'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Session',
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log out',
                subtitle: 'Sign out on this device',
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  ref.invalidate(appControllerProvider);
                  if (!context.mounted) return;
                  context.go('/welcome');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PledgeColors.inkMuted,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: PledgeColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PledgeColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: _withDividers(children)),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i < tiles.length - 1) {
        out.add(const Divider(height: 1, indent: 56));
      }
    }
    return out;
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: PledgeColors.primaryGreen, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: PledgeColors.inkMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
