import 'package:drift/drift.dart';

/// Database table storing cached wallet balance and timestamp.
///
/// Implements wallet cache persistence per docs/ARCHITECTURE.md §13.3.
/// Allows offline rendering of confirmed balance and last-updated time.
@DataClassName('WalletCacheEntry')
class WalletCache extends Table {
  /// Singleton primary key (fixed ID = 1) ensuring exactly one active balance snapshot.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Confirmed wallet balance in integer kobo.
  Int64Column get balanceKobo => int64()();

  /// Timestamp when balance was last updated/refreshed (UTC epoch milliseconds).
  Int64Column get lastUpdatedAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table storing confirmed or cached transactions for the wallet.
///
/// Implements transaction cache persistence per docs/ARCHITECTURE.md §13.3.
@DataClassName('TransactionEntry')
class TransactionsTable extends Table {
  /// Unique transaction identifier.
  TextColumn get id => text()();

  /// Transaction type: 'debit' or 'credit'.
  TextColumn get transactionType => text()();

  /// Monetary amount in integer kobo.
  Int64Column get amountKobo => int64()();

  /// Counterparty name or label (e.g. recipient name, sender name, goal name).
  TextColumn get counterparty => text()();

  /// Transaction creation timestamp (UTC epoch milliseconds).
  Int64Column get createdAt => int64()();

  /// Transaction status: 'completed', 'pending', 'failed'.
  TextColumn get status => text().withDefault(const Constant('completed'))();

  /// Remote settlement reference, nullable.
  TextColumn get reference => text().nullable()();

  /// Optional narration / description.
  TextColumn get narration => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table storing savings goals for NovaSave.
///
/// Implements goals persistence per docs/ARCHITECTURE.md §13.2.
@DataClassName('SavingsGoalEntry')
class SavingsGoalsTable extends Table {
  /// Unique goal identifier.
  TextColumn get id => text()();

  /// Goal display name.
  TextColumn get name => text()();

  /// Target amount in integer kobo.
  Int64Column get targetAmountKobo => int64()();

  /// Current saved amount in integer kobo.
  Int64Column get savedAmountKobo => int64()();

  /// Target completion date (UTC epoch milliseconds).
  Int64Column get targetDate => int64()();

  /// Timestamp when goal was created (UTC epoch milliseconds).
  Int64Column get createdAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}
