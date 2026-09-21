import 'package:drift/drift.dart';

/// Database table representing durable money-moving operations.
///
/// Implements the operations table specified in docs/ARCHITECTURE.md §11, §13.1, and §16.
///
/// Under HC-MONEY, HC-OFFLINE-DURABILITY, HC-IDEMPOTENCY, and HC-EXACTLY-ONCE-EFFECT:
/// - One logical operation has ONE stable [id] and ONE stable [idempotencyKey].
/// - [amountKobo] is stored strictly as integer kobo (INT64 / BigInt equivalent).
/// - [payloadJson] stores the complete, immutable intent snapshot serialized with schema version.
/// - [status] represents the durable lifecycle state (pending, processing, completed, failed).
/// - [lastErrorJson] captures transient/terminal error metadata without discarding user intent.
/// - [remoteReference] records backend settlement reference upon successful delivery.
@DataClassName('PendingOperationEntry')
class PendingOperations extends Table {
  /// Unique local durable identifier (e.g. UUIDv4 string).
  TextColumn get id => text()();

  /// Stable remote idempotency key reused across retries.
  TextColumn get idempotencyKey => text().unique()();

  /// Operation type discriminator: 'send' or 'contribution'.
  TextColumn get operationType => text()();

  /// Complete JSON serialization of the user's intent payload.
  TextColumn get payloadJson => text()();

  /// Monetary amount in integer kobo.
  Int64Column get amountKobo => int64()();

  /// Current lifecycle state: 'pending', 'processing', 'completed', 'failed'.
  TextColumn get status => text()();

  /// Number of sync attempts performed.
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Timestamp when the operation was originally queued (UTC epoch milliseconds).
  Int64Column get createdAt => int64()();

  /// Timestamp of the most recent sync attempt (UTC epoch milliseconds), nullable.
  Int64Column get lastAttemptAt => int64().nullable()();

  /// Serialized [SyncError] JSON metadata, nullable.
  TextColumn get lastErrorJson => text().nullable()();

  /// Settlement reference returned by remote backend on completion, nullable.
  TextColumn get remoteReference => text().nullable()();

  /// Timestamp when the operation settled successfully (UTC epoch milliseconds), nullable.
  Int64Column get completedAt => int64().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
