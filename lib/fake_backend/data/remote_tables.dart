import 'package:drift/drift.dart';

/// Database table storing remote idempotency records for the fake backend.
///
/// Implements docs/ARCHITECTURE.md §11.4:
/// Fake-remote persisted state must survive process restart scenarios,
/// but must be accessed only through the fake-remote boundary.
@DataClassName('RemoteIdempotencyEntry')
class RemoteIdempotencyTable extends Table {
  /// Stable idempotency key (primary key).
  TextColumn get idempotencyKey => text()();

  /// Logical operation ID.
  TextColumn get operationId => text()();

  /// Operation type: 'send' or 'contribution'.
  TextColumn get operationType => text()();

  /// Encoded JSON representation of the payload.
  TextColumn get payloadJson => text()();

  /// The generated remote transaction reference.
  TextColumn get remoteReference => text()();

  /// Monetary amount debited in integer kobo.
  Int64Column get debitAmountKobo => int64()();

  /// Settlement timestamp (UTC epoch milliseconds).
  Int64Column get settledAt => int64()();

  /// Record creation timestamp (UTC epoch milliseconds).
  Int64Column get recordedAt => int64()();

  /// Optional metadata JSON.
  TextColumn get metadataJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {idempotencyKey};
}

/// Database table storing authoritative remote wallet balance for the fake backend.
@DataClassName('RemoteWalletStateEntry')
class RemoteWalletStateTable extends Table {
  /// Singleton primary key (fixed ID = 1).
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Remote wallet balance in integer kobo.
  Int64Column get balanceKobo => int64()();

  /// Timestamp when remote balance was last updated (UTC epoch milliseconds).
  Int64Column get lastUpdatedAt => int64()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table storing authoritative remote transaction log for the fake backend.
@DataClassName('RemoteTransactionEntry')
class RemoteTransactionsTable extends Table {
  /// Transaction ID / reference.
  TextColumn get id => text()();

  /// Transaction type: 'debit' or 'credit'.
  TextColumn get transactionType => text()();

  /// Monetary amount in integer kobo.
  Int64Column get amountKobo => int64()();

  /// Counterparty name or label.
  TextColumn get counterparty => text()();

  /// Transaction timestamp (UTC epoch milliseconds).
  Int64Column get createdAt => int64()();

  /// Transaction status ('completed', etc.).
  TextColumn get status => text().withDefault(const Constant('completed'))();

  /// Remote settlement reference.
  TextColumn get reference => text().nullable()();

  /// Optional narration.
  TextColumn get narration => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
