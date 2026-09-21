import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// Policy governing spendable balance calculation and validation when
/// operations are queued locally while offline.
///
/// Requirement: MNY-006 (docs/REQUIREMENTS_TRACEABILITY.md)
/// Architecture: docs/ARCHITECTURE.md §16 & §26
///
/// Rules:
/// 1. The headline wallet balance always displays the confirmed cached balance.
/// 2. The spendable balance for new outgoing operations deducts all active
///    ([OperationStatus.pending] and [OperationStatus.processing]) outgoing
///    operations from the confirmed balance:
///    `spendableBalance = max(Money.zero, confirmedBalance - sum(activePendingKobo))`
/// 3. If the total active pending operations equal or exceed the confirmed balance,
///    the spendable balance is [Money.zero] (never negative).
/// 4. Completed operations do not double-deduct from spendable balance.
/// 5. Failed operations release their reservation immediately upon failure.
/// 6. All calculations use exact [Money] arithmetic. If reservations overflow
///    the 64-bit integer limit, calculation fails closed to [Money.zero].
@immutable
class SpendableBalancePolicy {
  const SpendableBalancePolicy();

  /// Calculates the total kobo reserved by active pending/processing operations.
  ///
  /// Optionally excludes an operation identified by [excluding] (useful when
  /// re-validating an existing pending operation so it is not self-counted).
  ///
  /// Under HC-MONEY:
  /// - Active operations are accumulated using exact [Money] arithmetic.
  /// - If total reservations exceed [Money.maxKobo], throws [MoneyOverflowException].
  Money calculateReservedAmount(
    Iterable<FinancialOperation> operations, {
    OperationId? excluding,
  }) {
    var reserved = const Money.zero();
    for (final op in operations) {
      if (excluding != null && op.id == excluding) {
        continue;
      }
      if (op.reservesFunds) {
        reserved += op.payload.amount;
      }
    }
    return reserved;
  }

  /// Calculates the current spendable balance given the [confirmedBalance] and [operations].
  ///
  /// Optionally excludes an operation identified by [excluding].
  ///
  /// Fails closed:
  /// - If [confirmedBalance] is non-positive, returns [Money.zero].
  /// - If reserved amount calculation or subtraction overflows, returns [Money.zero].
  /// - If reserved amount equals or exceeds confirmed balance, returns [Money.zero].
  Money calculateSpendableBalance({
    required Money confirmedBalance,
    required Iterable<FinancialOperation> operations,
    OperationId? excluding,
  }) {
    if (!confirmedBalance.isPositive) {
      return const Money.zero();
    }

    try {
      final reserved = calculateReservedAmount(
        operations,
        excluding: excluding,
      );
      final remaining = confirmedBalance - reserved;
      return remaining.isPositive ? remaining : const Money.zero();
    } on MoneyOverflowException {
      // Fail closed: unrepresentable reservation or subtraction overflow -> nothing spendable
      return const Money.zero();
    }
  }

  /// Determines whether [amount] can be spent/transferred given [confirmedBalance]
  /// and currently queued [operations].
  ///
  /// Returns `true` if [amount] is strictly positive and does not exceed the
  /// available [calculateSpendableBalance].
  bool canSpend({
    required Money amount,
    required Money confirmedBalance,
    required Iterable<FinancialOperation> operations,
    OperationId? excluding,
  }) {
    if (!amount.isPositive) {
      return false;
    }
    final spendable = calculateSpendableBalance(
      confirmedBalance: confirmedBalance,
      operations: operations,
      excluding: excluding,
    );
    return amount <= spendable;
  }
}
