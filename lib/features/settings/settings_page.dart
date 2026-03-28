import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_shell.dart';

/// Hub for local mock settings. Wire navigation to real auth / APIs later.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                subtitle: 'Name, username, email',
                onTap: () => context.push('/settings/account'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Step tracker',
            children: [
              _SettingsTile(
                icon: Icons.watch_later_outlined,
                label: 'Connected devices',
                subtitle: 'Apple Health, Google Fit, Fitbit',
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
            border: Border.all(color: const Color(0xFFF3F4F6)),
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
