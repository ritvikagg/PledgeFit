import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_controller/app_controller.dart';
import '../../core/ui/money_text.dart';
import '../../core/ui/section_card.dart';
import '../../core/ui/metric_row.dart';

import '../../data/models/wallet_transaction.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);
    return appState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (model) {
        final wallet = model.wallet;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Wallet'),
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SectionCard(
                  title: 'Wallet summary',
                  subtitle: const Text('Fake in-app currency for MVP'),
                  child: Column(
                    children: [
                      MetricRow(
                        label: 'Available balance',
                        value: MoneyText(wallet.availableBalance, bold: true),
                      ),
                      MetricRow(
                        label: 'Total deposited (locked)',
                        value: MoneyText(wallet.totalDeposited, bold: true),
                      ),
                      MetricRow(
                        label: 'Total returned to wallet',
                        value: MoneyText(wallet.totalReturned, bold: true),
                      ),
                      MetricRow(
                        label: 'Total forfeited (penalties)',
                        value: MoneyText(wallet.totalForfeited, bold: true),
                      ),
                      MetricRow(
                        label: 'Total kept by platform',
                        value: MoneyText(wallet.totalPlatformKept, bold: true),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Transaction history',
                  subtitle: const Text('Ordered newest first'),
                  child: wallet.transactions.isEmpty
                      ? const Text('No wallet activity yet.')
                      : _TransactionList(
                          transactions: wallet.transactions,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction txn;

  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${txn.createdAt.year}-${txn.createdAt.month.toString().padLeft(2, '0')}-${txn.createdAt.day.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(txn.description),
      subtitle: Text(subtitle),
      trailing: MoneyText(txn.amount, bold: true),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<WalletTransaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final sorted = transactions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visible = sorted.take(30).toList();
    return Column(
      children: visible.map((txn) => _TransactionTile(txn: txn)).toList(),
    );
  }
}

