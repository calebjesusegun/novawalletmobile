import 'package:flutter/foundation.dart';
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
@immutable
class SpendableBalancePolicy {
  const SpendableBalancePolicy();

  /// Calculates the current spendable balance given the [confirmedBalance] and [operations].
  Money calculateSpendableBalance({
    required Money confirmedBalance,
    required Iterable<FinancialOperation> operations,
  }) {
    var activePendingKobo = 0;
    for (final op in operations) {
      if (op.isPending || op.isProcessing) {
        activePendingKobo += op.payload.amount.kobo;
      }
    }

    final remainingKobo = confirmedBalance.kobo - activePendingKobo;
    return remainingKobo > 0
        ? Money.fromKobo(remainingKobo)
        : const Money.zero();
  }

  /// Calculates the total kobo reserved by active pending/processing operations.
  Money calculateReservedAmount(Iterable<FinancialOperation> operations) {
    var reservedKobo = 0;
    for (final op in operations) {
      if (op.isPending || op.isProcessing) {
        reservedKobo += op.payload.amount.kobo;
      }
    }
    return Money.fromKobo(reservedKobo);
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
  }) {
    if (amount.isZero || amount.isNegative) {
      return false;
    }
    final spendable = calculateSpendableBalance(
      confirmedBalance: confirmedBalance,
      operations: operations,
    );
    return amount <= spendable;
  }
}
