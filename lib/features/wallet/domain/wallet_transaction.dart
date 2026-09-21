import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';

/// Domain entity representing a transaction in the user's wallet.
///
/// Under HC-MONEY:
/// - [amount] is strictly backed by integer kobo via [Money].
/// - [createdAt] is normalized to UTC.
/// - Represents ledger entries displayed on the Wallet activity feed (UI-WAL-01).
@immutable
class WalletTransaction {
  final String id;
  final TransactionType type;
  final Money amount;
  final String counterparty;
  final DateTime createdAt;
  final TransactionStatus status;
  final String? reference;
  final String? narration;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.counterparty,
    required this.createdAt,
    this.status = TransactionStatus.completed,
    this.reference,
    this.narration,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Transaction ID cannot be empty.');
    }
    if (counterparty.trim().isEmpty) {
      throw ArgumentError.value(
        counterparty,
        'counterparty',
        'Counterparty cannot be empty.',
      );
    }
    amount.ensurePositive();
  }

  WalletTransaction copyWith({
    String? id,
    TransactionType? type,
    Money? amount,
    String? counterparty,
    DateTime? createdAt,
    TransactionStatus? status,
    String? reference,
    String? narration,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      counterparty: counterparty ?? this.counterparty,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      narration: narration ?? this.narration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletTransaction &&
          other.id == id &&
          other.type == type &&
          other.amount == amount &&
          other.counterparty == counterparty &&
          other.createdAt.isAtSameMomentAs(createdAt) &&
          other.status == status &&
          other.reference == reference &&
          other.narration == narration);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    counterparty,
    createdAt.millisecondsSinceEpoch,
    status,
    reference,
    narration,
  );

  @override
  String toString() =>
      'WalletTransaction(id: $id, type: $type, amount: $amount, to/from: "$counterparty", status: $status)';
}
