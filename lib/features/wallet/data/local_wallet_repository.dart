import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';

/// Concrete implementation of [WalletRepository] backed by Drift DAOs.
class LocalWalletRepository implements WalletRepository {
  final WalletDao walletDao;
  final TransactionDao transactionDao;

  LocalWalletRepository({
    required this.walletDao,
    required this.transactionDao,
  });

  @override
  Future<WalletSnapshot?> getWalletSnapshot() => walletDao.getWalletSnapshot();

  @override
  Future<void> setWalletSnapshot(WalletSnapshot snapshot) =>
      walletDao.setWalletSnapshot(snapshot);

  @override
  Stream<WalletSnapshot?> watchWalletSnapshot() =>
      walletDao.watchWalletSnapshot();

  @override
  Future<void> saveTransaction(WalletTransaction transaction) =>
      transactionDao.insertTransaction(transaction);

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) =>
      transactionDao.insertTransactions(transactions);

  @override
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  }) => transactionDao.getRecentTransactions(limit: limit, offset: offset);

  @override
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit}) =>
      transactionDao.watchRecentTransactions(limit: limit);

  @override
  Future<WalletTransaction?> getTransactionById(String id) =>
      transactionDao.getTransactionById(id);
}
