import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';

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
  );
});
