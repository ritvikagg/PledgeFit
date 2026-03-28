import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/presentation.dart';
import '../../app_controller/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme/pledge_colors.dart';
import '../../core/ui/kit/pledge_shell.dart';
import '../../data/models/wallet_transaction.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    final wallet = ref.watch(displayWalletProvider);
    final isDemo = ref.watch(isUiDemoChallengeProvider);

    return appState.when(
      loading: () => const Scaffold(
        backgroundColor: PledgeColors.pageBg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: PledgeColors.pageBg,
        body: Center(child: Text('Error: $e')),
      ),
      data: (_) {
        return PledgePageScaffold(
          title: 'Wallet',
          padding: EdgeInsets.zero,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              if (isDemo)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PledgeColors.successGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Mock ledger for investor preview',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PledgeColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: PledgeColors.inkMuted,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wallet.availableBalance.format(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: PledgeColors.ink,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Updated just now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkSoft,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SmallMetric(
                      label: 'Deposited',
                      value: wallet.totalDeposited.format(),
                      color: PledgeColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallMetric(
                      label: 'Returned',
                      value: wallet.totalReturned.format(),
                      color: PledgeColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SmallMetric(
                      label: 'Forfeited',
                      value: wallet.totalForfeited.format(),
                      color: PledgeColors.penaltyAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Recent transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              if (wallet.transactions.isEmpty)
                Text(
                  'No activity yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PledgeColors.inkMuted,
                      ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: PledgeColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: _sorted(wallet.transactions)
                        .take(12)
                        .map((txn) => _WalletTxnRow(txn: txn))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

List<WalletTransaction> _sorted(List<WalletTransaction> txns) {
  final list = txns.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PledgeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PledgeColors.inkMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _WalletTxnRow extends StatelessWidget {
  const _WalletTxnRow({required this.txn});

  final WalletTransaction txn;

  @override
  Widget build(BuildContext context) {
    final isPenalty = txn.type == 'penalty';
    final isRestartForfeit = txn.type == 'restart_forfeit';
    final isRefund = txn.type == 'refund';
    final isTopup = txn.type == 'topup';
    Color dot;
    Color amountColor;
    IconData icon;
    if (isPenalty || isRestartForfeit) {
      dot = PledgeColors.penaltyAmber;
      amountColor = PledgeColors.penaltyAmber;
      icon = Icons.trending_down_rounded;
    } else if (isRefund || (isTopup && txn.amount.cents > 0)) {
      dot = PledgeColors.successGreen;
      amountColor = PledgeColors.successGreen;
      icon = isRefund ? Icons.south_west_rounded : Icons.north_east_rounded;
    } else {
      dot = PledgeColors.ink;
      amountColor = PledgeColors.ink;
      icon = Icons.north_east_rounded;
    }

    final amountStr = txn.type == 'deposit_locked' || isPenalty || isRestartForfeit
        ? '-${txn.amount.format()}'
        : '+${txn.amount.format()}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dot.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: dot, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMonthDayYear(txn.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PledgeColors.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                amountStr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
