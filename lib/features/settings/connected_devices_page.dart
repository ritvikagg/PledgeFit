import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_controller/app_controller.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../data/models/connected_devices_state.dart';

/// Mock toggles — implement [HealthStepSyncService] per provider later.
class ConnectedDevicesPage extends ConsumerWidget {
  const ConnectedDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices =
        ref.watch(appControllerProvider).value?.connectedDevices ??
            ConnectedDevicesState.none;

    Future<void> patch(ConnectedDevicesState next) async {
      await ref.read(appControllerProvider.notifier).saveConnectedDevices(next);
    }

    return PledgePageScaffold(
      title: 'Connected devices',
      showBack: true,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Connect a step source for automatic sync. Integrations are mock-only for now.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PledgeColors.inkMuted,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          _DeviceTile(
            title: 'Apple Health',
            subtitle: devices.appleHealth ? 'Connected' : 'Not connected',
            icon: Icons.favorite_outline,
            value: devices.appleHealth,
            onChanged: (v) => patch(devices.copyWith(appleHealth: v)),
          ),
          const SizedBox(height: 12),
          _DeviceTile(
            title: 'Google Fit',
            subtitle: devices.googleFit ? 'Connected' : 'Not connected',
            icon: Icons.directions_run_outlined,
            value: devices.googleFit,
            onChanged: (v) => patch(devices.copyWith(googleFit: v)),
          ),
          const SizedBox(height: 12),
          _DeviceTile(
            title: 'Fitbit',
            subtitle: devices.fitbit ? 'Connected' : 'Not connected',
            icon: Icons.watch_outlined,
            value: devices.fitbit,
            onChanged: (v) => patch(devices.copyWith(fitbit: v)),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: PledgeColors.primaryGreen),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: value ? PledgeColors.successGreen : PledgeColors.inkMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        value: value,
        activeThumbColor: PledgeColors.primaryGreen,
        onChanged: onChanged,
      ),
    );
  }
}
