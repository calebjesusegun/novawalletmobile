import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/fake_backend/remote_idempotency_record.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

/// Storage abstraction for the fake remote's server-side ledger.
///
/// Implements requirements:
/// - SYNC-008: Fake remote deduplicates repeated idempotency keys.
/// - docs/ARCHITECTURE.md §11.4: Fake-remote persistence boundary.
abstract class RemoteIdempotencyLedger {
  /// Retrieves the recorded operation for [idempotencyKey], or null if not yet processed.
  Future<RemoteIdempotencyRecord?> getRecord(String idempotencyKey);

  /// Saves a newly processed operation to the ledger.
  Future<void> saveRecord(RemoteIdempotencyRecord record);

  /// Retrieves the current authoritative remote wallet balance.
  Future<Money> getBalance();

  /// Updates the remote wallet balance.
  Future<void> setBalance(Money balance);

  /// Appends a confirmed transaction to the remote ledger.
  Future<void> addTransaction(WalletTransaction transaction);

  /// Retrieves paginated remote transactions ordered by creation date descending.
  Future<List<WalletTransaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  });

  /// Atomically executes an operation by checking idempotency, debiting balance,
  /// appending the transaction, and storing the record in a single ledger transaction.
  ///
  /// If [idempotencyKey] was already recorded:
  /// - Verifies payload match (throws if conflict).
  /// - Returns the previously recorded result with `isDuplicate: true` without another debit.
  Future<RemoteOperationResult> executeAtomicOperation({
    required String idempotencyKey,
    required OperationPayload payload,
    required Money debitAmount,
    required WalletTransaction transaction,
    required RemoteIdempotencyRecord record,
  });

  /// Clears all records, balance, and transactions (for test resets).
  Future<void> clear();
}
