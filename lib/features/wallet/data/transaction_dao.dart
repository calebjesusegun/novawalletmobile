import 'package:drift/drift.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';

/// Clean mapping between Drift [TransactionEntry] and domain [WalletTransaction].
class TransactionMapper {
  const TransactionMapper._();

  static TransactionsTableCompanion toCompanion(WalletTransaction tx) {
    return TransactionsTableCompanion(
      id: Value(tx.id),
      transactionType: Value(tx.type.name),
      amountKobo: Value(BigInt.from(tx.amount.kobo)),
      counterparty: Value(tx.counterparty),
      createdAt: Value(BigInt.from(tx.createdAt.millisecondsSinceEpoch)),
      status: Value(tx.status.name),
      reference: Value(tx.reference),
      narration: Value(tx.narration),
    );
  }

  static WalletTransaction toDomain(TransactionEntry row) {
    return WalletTransaction(
      id: row.id,
      type: TransactionType.values.byName(row.transactionType),
      amount: Money.fromKobo(row.amountKobo.toInt()),
      counterparty: row.counterparty,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt.toInt(),
        isUtc: true,
      ),
      status: TransactionStatus.values.byName(row.status),
      reference: row.reference,
      narration: row.narration,
    );
  }
}

/// Data Access Object for local confirmed and cached transactions.
///
/// Implements transaction cache persistence per docs/ARCHITECTURE.md §13.3 and WAL-002.
/// Supports pagination/lazy loading for large transaction lists per HC-PERFORMANCE.
class TransactionDao {
  final AppDatabase db;

  TransactionDao(this.db);

  /// Inserts a transaction into durable cache.
  Future<void> insertTransaction(WalletTransaction tx) async {
    await db
        .into(db.transactionsTable)
        .insert(TransactionMapper.toCompanion(tx));
  }

  /// Inserts multiple transactions in an atomic batch.
  Future<void> insertTransactions(List<WalletTransaction> transactions) async {
    await db.batch((batch) {
      batch.insertAll(
        db.transactionsTable,
        transactions.map(TransactionMapper.toCompanion).toList(),
      );
    });
  }

  /// Retrieves a transaction by its unique ID.
  Future<WalletTransaction?> getTransactionById(String id) async {
    final row = await (db.select(
      db.transactionsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? TransactionMapper.toDomain(row) : null;
  }

  /// Retrieves recent transactions ordered by creation date descending (newest first).
  ///
  /// Supports [limit] and [offset] for lazy loading / pagination (HC-PERFORMANCE).
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  }) async {
    final query = db.select(db.transactionsTable)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    final rows = await query.get();
    return rows.map(TransactionMapper.toDomain).toList();
  }

  /// Watches recent transactions as a Stream for reactive UI updates.
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit}) {
    final query = db.select(db.transactionsTable)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().map(
      (rows) => rows.map(TransactionMapper.toDomain).toList(),
    );
  }

  /// Deletes all cached transactions (useful for test resets).
  Future<int> clearTransactions() async {
    return db.delete(db.transactionsTable).go();
  }
}
