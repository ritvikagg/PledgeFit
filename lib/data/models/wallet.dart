import '../../core/money.dart';
import 'wallet_transaction.dart';

class Wallet {
  final Money availableBalance;
  final Money totalDeposited;
  final Money totalReturned;
  final Money totalForfeited;
  final Money totalPlatformKept;
  final List<WalletTransaction> transactions;

  const Wallet({
    required this.availableBalance,
    required this.totalDeposited,
    required this.totalReturned,
    required this.totalForfeited,
    required this.totalPlatformKept,
    required this.transactions,
  });

  static const Wallet empty = Wallet(
    availableBalance: Money(0),
    totalDeposited: Money(0),
    totalReturned: Money(0),
    totalForfeited: Money(0),
    totalPlatformKept: Money(0),
    transactions: [],
  );

  Wallet copyWith({
    Money? availableBalance,
    Money? totalDeposited,
    Money? totalReturned,
    Money? totalForfeited,
    Money? totalPlatformKept,
    List<WalletTransaction>? transactions,
  }) {
    return Wallet(
      availableBalance: availableBalance ?? this.availableBalance,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      totalReturned: totalReturned ?? this.totalReturned,
      totalForfeited: totalForfeited ?? this.totalForfeited,
      totalPlatformKept: totalPlatformKept ?? this.totalPlatformKept,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'availableBalance': availableBalance.toJson(),
        'totalDeposited': totalDeposited.toJson(),
        'totalReturned': totalReturned.toJson(),
        'totalForfeited': totalForfeited.toJson(),
        'totalPlatformKept': totalPlatformKept.toJson(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  static Wallet fromJson(Map<String, dynamic> json) {
    return Wallet(
      availableBalance: Money.fromJson(json['availableBalance']),
      totalDeposited: Money.fromJson(json['totalDeposited']),
      totalReturned: Money.fromJson(json['totalReturned']),
      totalForfeited: Money.fromJson(json['totalForfeited']),
      totalPlatformKept: Money.fromJson(json['totalPlatformKept']),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

