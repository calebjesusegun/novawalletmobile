import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';

/// Abstract contract for local wallet and transaction data access.
///
/// Implements repository boundary hiding Drift persistence details per docs/ARCHITECTURE.md §15.
abstract class WalletRepository {
  /// Retrieves the current cached wallet balance snapshot.
  Future<WalletSnapshot?> getWalletSnapshot();

  /// Updates the cached wallet balance snapshot.
  Future<void> setWalletSnapshot(WalletSnapshot snapshot);

  /// Watches the cached wallet balance snapshot reactively.
  Stream<WalletSnapshot?> watchWalletSnapshot();

  /// Records a confirmed transaction in local cache.
  Future<void> saveTransaction(WalletTransaction transaction);

  /// Records multiple transactions in local cache.
  Future<void> saveTransactions(List<WalletTransaction> transactions);

  /// Retrieves recent transactions with optional lazy pagination limits.
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  });

  /// Watches recent transactions reactively.
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit});

  /// Retrieves a transaction by ID.
  Future<WalletTransaction?> getTransactionById(String id);
}
