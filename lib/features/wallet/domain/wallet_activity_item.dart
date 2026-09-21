import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';

/// Presentation-ready domain item representing an entry in the Wallet activity list.
///
/// Encapsulates both confirmed transactions (from SQLite cache) and in-flight
/// pending/processing operations (from the sync queue) without leaking Drift or
/// raw sync coordinator internals to presentation widgets.
///
/// Under HC-MONEY:
/// - [amount] is strictly backed by integer kobo via [Money].
/// - [timestamp] is normalized to UTC.
@immutable
class WalletActivityItem {
  /// Unique identifier (transaction ID or operation ID value).
  final String id;

  /// Primary label (e.g. recipient name, counterparty, or goal name).
  final String title;

  /// Secondary descriptor (e.g. "Transfer", "Contribution", "Deposit").
  final String subtitle;

  /// Exact monetary value of the transaction.
  final Money amount;

  /// Whether the funds are debited or credited.
  final TransactionType type;

  /// Date and time when the activity occurred or was queued (UTC).
  final DateTime timestamp;

  /// Visual and lifecycle status of the item.
  final TransactionStatus status;

  /// True if this item represents an unconfirmed local queue operation.
  final bool isPendingSync;

  /// True if this in-flight operation encountered a sync failure.
  final bool hasSyncError;

  /// Stable operation identity, if this item originated from a queued [FinancialOperation].
  final OperationId? operationId;

  /// Remote transaction reference or receipt number, if settled.
  final String? reference;

  /// Optional narration or memo.
  final String? narration;

  /// Specific counterparty details (e.g. bank name and account number).
  final String? counterpartyDetail;

  /// Human-readable failure explanation if this operation failed.
  final String? failureReason;

  WalletActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required DateTime timestamp,
    required this.status,
    this.isPendingSync = false,
    this.hasSyncError = false,
    this.operationId,
    this.reference,
    this.narration,
    this.counterpartyDetail,
    this.failureReason,
  }) : timestamp = timestamp.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Activity item ID cannot be empty.');
    }
    amount.ensurePositive();
  }

  /// Creates a [WalletActivityItem] projection from a confirmed [WalletTransaction].
  factory WalletActivityItem.fromTransaction(WalletTransaction tx) {
    return WalletActivityItem(
      id: tx.id,
      title: tx.counterparty,
      subtitle: tx.type == TransactionType.credit ? 'Deposit' : 'Transfer',
      amount: tx.amount,
      type: tx.type,
      timestamp: tx.createdAt,
      status: tx.status,
      isPendingSync: false,
      hasSyncError: false,
      reference: tx.reference,
      narration: tx.narration,
      counterpartyDetail: tx.narration,
    );
  }

  /// Creates a [WalletActivityItem] projection from a queued or processing [FinancialOperation].
  factory WalletActivityItem.fromOperation(FinancialOperation op) {
    final payload = op.payload;
    final String title;
    final String subtitle;
    final String? counterpartyDetail;

    if (payload is SendMoneyPayload) {
      title = payload.recipientName;
      subtitle = 'Transfer';
      counterpartyDetail =
          '${payload.bankName} • ${payload.recipientAccountNumber}';
    } else if (payload is ContributionPayload) {
      title = payload.goalName;
      subtitle = 'NovaSave';
      counterpartyDetail = 'NovaSave Goal';
    } else {
      title = 'Transaction';
      subtitle = op.type.name;
      counterpartyDetail = null;
    }

    final hasError = op.lastError != null;
    final TransactionStatus status;
    switch (op.status) {
      case OperationStatus.pending:
        status = hasError
            ? TransactionStatus.failed
            : TransactionStatus.pending;
      case OperationStatus.processing:
        status = TransactionStatus.processing;
      case OperationStatus.completed:
        status = TransactionStatus.completed;
      case OperationStatus.failed:
        status = TransactionStatus.failed;
    }

    return WalletActivityItem(
      id: op.id.value,
      title: title,
      subtitle: subtitle,
      amount: payload.amount,
      type: TransactionType.debit,
      timestamp: op.createdAt,
      status: status,
      isPendingSync: op.status != OperationStatus.completed,
      hasSyncError: hasError,
      operationId: op.id,
      reference: op.remoteReference,
      counterpartyDetail: counterpartyDetail,
      failureReason: op.lastError?.message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletActivityItem &&
          other.id == id &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.amount == amount &&
          other.type == type &&
          other.timestamp.isAtSameMomentAs(timestamp) &&
          other.status == status &&
          other.isPendingSync == isPendingSync &&
          other.operationId == operationId &&
          other.reference == reference &&
          other.narration == narration &&
          other.counterpartyDetail == counterpartyDetail &&
          other.failureReason == failureReason);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subtitle,
    amount,
    type,
    timestamp.millisecondsSinceEpoch,
    status,
    isPendingSync,
    operationId,
    reference,
    narration,
    counterpartyDetail,
    failureReason,
  );

  @override
  String toString() =>
      'WalletActivityItem(id: $id, title: "$title", amount: $amount, status: $status, isPendingSync: $isPendingSync)';
}
