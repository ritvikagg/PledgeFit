import '../../core/money.dart';
import '../../core/id_generator.dart';

class WalletTransaction {
  final String id;
  final DateTime createdAt;
  final String description;
  final Money amount; // For display only; totals are computed from state.
  final String type; // e.g. "deposit_locked", "returned", "platform_kept"

  const WalletTransaction({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.amount,
    required this.type,
  });

  static WalletTransaction create({
    required String type,
    required String description,
    required Money amount,
    required DateTime createdAt,
  }) {
    return WalletTransaction(
      id: generateId(prefix: 'txn'),
      createdAt: createdAt,
      type: type,
      description: description,
      amount: amount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'amount': amount.toJson(),
        'type': type,
      };

  static WalletTransaction fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String,
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      type: json['type'] as String,
    );
  }
}

