import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// Contract for the remote banking service.
///
/// Per docs/ARCHITECTURE.md §14, there is no real backend for this take-home
/// assessment. The client communicates with the fake remote exclusively via
/// this narrow interface to prove idempotency, offline sync, and error handling.
abstract class RemoteApi {
  /// Submits a Send Money operation to the remote service.
  ///
  /// Must be idempotent: repeated submissions with the same idempotency key
  /// return the original result without applying a duplicate financial effect.
  Future<RemoteOperationResult> sendMoney(FinancialOperation operation);

  /// Submits a NovaSave goal contribution to the remote service.
  ///
  /// Must be idempotent: repeated submissions with the same idempotency key
  /// return the original result without applying a duplicate financial effect.
  Future<RemoteOperationResult> contribute(FinancialOperation operation);

  /// Polymorphic dispatcher that routes [operation] to either [sendMoney]
  /// or [contribute] based on [operation.type].
  Future<RemoteOperationResult> submitOperation(FinancialOperation operation);

  /// Fetches the authoritative remote wallet balance snapshot.
  Future<WalletSnapshot> fetchWalletSnapshot();

  /// Fetches the paginated remote transaction history.
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  });
}
