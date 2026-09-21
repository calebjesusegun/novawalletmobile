import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/fake_backend_providers.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/data/sync_providers.dart';

/// Provider for [WalletDao].
final walletDaoProvider = Provider<WalletDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WalletDao(db);
});

/// Provider for [TransactionDao].
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionDao(db);
});

/// Provider for [WalletRepository].
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return LocalWalletRepository(
    walletDao: ref.watch(walletDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    remoteApi: ref.watch(remoteApiProvider),
  );
});

/// Reactive stream of the cached confirmed wallet balance snapshot.
final walletSnapshotStreamProvider = StreamProvider<WalletSnapshot?>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchWalletSnapshot();
});

/// Reactive stream of the recent cached confirmed transactions.
final walletRecentTransactionsStreamProvider =
    StreamProvider<List<WalletTransaction>>((ref) {
      final repo = ref.watch(walletRepositoryProvider);
      return repo.watchRecentTransactions();
    });

/// Reactive provider yielding the unified [WalletProjection].
///
/// Fuses:
/// - confirmed wallet balance ([walletSnapshotStreamProvider])
/// - confirmed transaction history ([walletRecentTransactionsStreamProvider])
/// - active in-flight sync operations ([activeOperationsStreamProvider])
///
/// Implements MNY-004 spendable balance reservation and UI-WAL-01 through UI-WAL-06 presentation data.
final walletProjectionProvider = Provider<AsyncValue<WalletProjection>>((ref) {
  final snapshotAsync = ref.watch(walletSnapshotStreamProvider);
  final transactionsAsync = ref.watch(walletRecentTransactionsStreamProvider);
  final operationsAsync = ref.watch(activeOperationsStreamProvider);

  // If any source failed and has no cached value, return error
  if (snapshotAsync.hasError && !snapshotAsync.hasValue) {
    return AsyncValue.error(snapshotAsync.error!, snapshotAsync.stackTrace!);
  }
  if (transactionsAsync.hasError && !transactionsAsync.hasValue) {
    return AsyncValue.error(
      transactionsAsync.error!,
      transactionsAsync.stackTrace!,
    );
  }
  if (operationsAsync.hasError && !operationsAsync.hasValue) {
    return AsyncValue.error(
      operationsAsync.error!,
      operationsAsync.stackTrace!,
    );
  }

  // If still loading initial values without cache
  if (snapshotAsync.isLoading && !snapshotAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final snapshot = snapshotAsync.valueOrNull;
  final transactions = transactionsAsync.valueOrNull ?? const [];
  final operations = operationsAsync.valueOrNull ?? const [];

  return AsyncValue.data(
    WalletProjection.build(
      snapshot: snapshot,
      confirmedTransactions: transactions,
      operations: operations,
    ),
  );
});
