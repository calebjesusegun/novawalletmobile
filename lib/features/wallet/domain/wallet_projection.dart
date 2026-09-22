import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/spendable_balance_policy.dart';

/// Pure domain projection of the user's wallet.
///
/// Under docs/ARCHITECTURE.md §7.1, §13.3, §16, and AGENTS.md:
/// - [confirmedBalance] is the authoritative headline balance (never decremented
///   before remote confirmation).
/// - [spendableBalance] reserves in-flight debits under MNY-004 so the user
///   cannot double-spend.
/// - [activities] is a unified, reverse-chronological list of recent activity items
///   fusing confirmed transactions and queued/processing operations.
@immutable
class WalletProjection {
  /// Authoritative headline balance displayed on the wallet card.
  final Money confirmedBalance;

  /// Effective spendable balance available for new transfers/contributions (MNY-004).
  final Money spendableBalance;

  /// Total amount of active in-flight debits currently reserving funds.
  final Money pendingDebitTotal;

  /// Timestamp of the last confirmed balance update (UTC).
  final DateTime lastUpdatedAt;

  /// Reverse-chronological activity items combining confirmed and in-flight items.
  final List<WalletActivityItem> activities;

  /// Active in-flight financial operations affecting this wallet.
  final List<FinancialOperation> pendingOperations;

  WalletProjection({
    required this.confirmedBalance,
    required this.spendableBalance,
    required this.pendingDebitTotal,
    required DateTime lastUpdatedAt,
    required List<WalletActivityItem> activities,
    required List<FinancialOperation> pendingOperations,
  }) : lastUpdatedAt = lastUpdatedAt.toUtc(),
       activities = List.unmodifiable(activities),
       pendingOperations = List.unmodifiable(pendingOperations);

  /// True if there are active in-flight operations pending sync.
  bool get hasPendingTransactions => pendingOperations.any(
    (op) =>
        op.status == OperationStatus.pending ||
        op.status == OperationStatus.processing,
  );

  /// True if any queued operation encountered a sync failure or error.
  bool get hasSyncFailure => pendingOperations.any(
    (op) => op.status == OperationStatus.failed || op.lastError != null,
  );

  /// Count of active pending/processing operations.
  int get pendingCount => pendingOperations
      .where(
        (op) =>
            op.status == OperationStatus.pending ||
            op.status == OperationStatus.processing,
      )
      .length;

  /// Constructs a [WalletProjection] from raw state sources.
  factory WalletProjection.build({
    WalletSnapshot? snapshot,
    List<WalletTransaction> confirmedTransactions = const [],
    List<FinancialOperation> operations = const [],
    SpendableBalancePolicy policy = const SpendableBalancePolicy(),
  }) {
    final confirmed = snapshot?.balance ?? const Money.zero();
    final updatedAt = snapshot?.lastUpdatedAt ?? DateTime.now().toUtc();

    // Calculate spendable balance and pending reservations under MNY-004
    final spendable = policy.calculateSpendableBalance(
      confirmedBalance: confirmed,
      operations: operations,
    );
    final reserved = policy.calculateReservedAmount(operations);

    // Filter uncompleted operations to overlay on confirmed transactions
    final activeOps = operations
        .where((op) => op.status != OperationStatus.completed)
        .toList();

    // Map confirmed transactions to activity items, deduplicating by stable reference or ID
    final seenKeys = <String>{};
    final uniqueConfirmed = <WalletTransaction>[];
    for (final tx in confirmedTransactions) {
      final key = tx.reference ?? tx.id;
      if (seenKeys.add(key)) {
        uniqueConfirmed.add(tx);
      }
    }

    final confirmedItems = uniqueConfirmed
        .map(WalletActivityItem.fromTransaction)
        .toList();

    // Map active operations to activity items
    final pendingItems = activeOps
        .map(WalletActivityItem.fromOperation)
        .toList();

    // Combine and sort in reverse chronological order
    final allActivities = <WalletActivityItem>[
      ...pendingItems,
      ...confirmedItems,
    ];

    allActivities.sort((a, b) {
      final cmp = b.timestamp.compareTo(a.timestamp);
      if (cmp != 0) return cmp;
      // If timestamps match, prioritize pending sync items first
      if (a.isPendingSync && !b.isPendingSync) return -1;
      if (!a.isPendingSync && b.isPendingSync) return 1;
      return 0;
    });

    return WalletProjection(
      confirmedBalance: confirmed,
      spendableBalance: spendable,
      pendingDebitTotal: reserved,
      lastUpdatedAt: updatedAt,
      activities: allActivities,
      pendingOperations: activeOps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletProjection &&
          other.confirmedBalance == confirmedBalance &&
          other.spendableBalance == spendableBalance &&
          other.pendingDebitTotal == pendingDebitTotal &&
          other.lastUpdatedAt.isAtSameMomentAs(lastUpdatedAt) &&
          listEquals(other.activities, activities) &&
          listEquals(other.pendingOperations, pendingOperations));

  @override
  int get hashCode => Object.hash(
    confirmedBalance,
    spendableBalance,
    pendingDebitTotal,
    lastUpdatedAt.millisecondsSinceEpoch,
    Object.hashAll(activities),
    Object.hashAll(pendingOperations),
  );

  @override
  String toString() =>
      'WalletProjection(confirmed: $confirmedBalance, spendable: $spendableBalance, pending: $pendingDebitTotal, activities: ${activities.length})';
}
