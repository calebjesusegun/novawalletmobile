import 'package:drift/drift.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/sync/data/pending_operation_mapper.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_status.dart';

/// Data Access Object providing direct persistence operations on the [PendingOperations] table.
///
/// Implements durable local operations store as required by docs/ARCHITECTURE.md §13.1, §15, §16.
///
/// Guarantees:
/// - Exact integer-kobo money representation preserved via [PendingOperationMapper].
/// - Stable [OperationId] and [IdempotencyKey] never mutated.
/// - Atomic operation claiming for serialization across concurrent sync triggers (HC-SYNC, SYNC-010).
/// - Comprehensive query and update operations for the sync coordinator.
class PendingOperationsDao {
  final AppDatabase db;

  PendingOperationsDao(this.db);

  /// Inserts a newly created [FinancialOperation] into durable persistence.
  ///
  /// Fails if an operation with the same [OperationId] or [IdempotencyKey] already exists.
  Future<void> insertOperation(FinancialOperation operation) async {
    final companion = PendingOperationMapper.toCompanion(operation);
    await db.into(db.pendingOperations).insert(companion);
  }

  /// Finds an operation by its local durable [OperationId].
  Future<FinancialOperation?> getOperationById(OperationId id) async {
    final query = db.select(db.pendingOperations)
      ..where((tbl) => tbl.id.equals(id.value));
    final row = await query.getSingleOrNull();
    return row != null ? PendingOperationMapper.toDomain(row) : null;
  }

  /// Finds an operation by its stable remote [IdempotencyKey].
  Future<FinancialOperation?> getOperationByIdempotencyKey(
    IdempotencyKey key,
  ) async {
    final query = db.select(db.pendingOperations)
      ..where((tbl) => tbl.idempotencyKey.equals(key.value));
    final row = await query.getSingleOrNull();
    return row != null ? PendingOperationMapper.toDomain(row) : null;
  }

  /// Returns all operations currently in [OperationStatus.pending], ordered oldest first.
  ///
  /// Used by the sync coordinator to discover operations eligible for processing.
  Future<List<FinancialOperation>> getPendingOperations() async {
    final query = db.select(db.pendingOperations)
      ..where((tbl) => tbl.status.equals(OperationStatus.pending.name))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(PendingOperationMapper.toDomain).toList();
  }

  /// Returns all active operations that reserve funds against the wallet balance
  /// (both [OperationStatus.pending] and [OperationStatus.processing]), ordered by creation.
  ///
  /// Used by [SpendableBalancePolicy] to calculate spendable balance offline.
  Future<List<FinancialOperation>> getActiveOperations() async {
    final query = db.select(db.pendingOperations)
      ..where(
        (tbl) => tbl.status.isIn([
          OperationStatus.pending.name,
          OperationStatus.processing.name,
        ]),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(PendingOperationMapper.toDomain).toList();
  }

  /// Returns all persisted operations in the database, ordered oldest first.
  Future<List<FinancialOperation>> getAllOperations() async {
    final query = db.select(db.pendingOperations)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(PendingOperationMapper.toDomain).toList();
  }

  /// Atomically claims an eligible pending operation for sync processing.
  ///
  /// Per docs/ARCHITECTURE.md §11.2 and SYNC-010:
  /// Performs an atomic conditional update:
  /// ```sql
  /// UPDATE pending_operations
  /// SET status = 'processing', attempt_count = attempt_count + 1, last_attempt_at = ?
  /// WHERE id = ? AND status = 'pending'
  /// ```
  /// Returns `true` if this caller won the claim; `false` if the operation was
  /// already claimed, completed, failed, or does not exist.
  Future<bool> claimOperation(OperationId id, {DateTime? at}) async {
    final attemptTime = (at ?? DateTime.now()).toUtc();
    final attemptMillis = BigInt.from(attemptTime.millisecondsSinceEpoch);

    final affected = await db.transaction(() async {
      final current =
          await (db.select(db.pendingOperations)..where(
                (tbl) =>
                    tbl.id.equals(id.value) &
                    tbl.status.equals(OperationStatus.pending.name),
              ))
              .getSingleOrNull();

      if (current == null) {
        return 0;
      }

      final updated =
          await (db.update(db.pendingOperations)..where(
                (tbl) =>
                    tbl.id.equals(id.value) &
                    tbl.status.equals(OperationStatus.pending.name),
              ))
              .write(
                PendingOperationsCompanion(
                  status: Value(OperationStatus.processing.name),
                  attemptCount: Value(current.attemptCount + 1),
                  lastAttemptAt: Value(attemptMillis),
                  lastErrorJson: const Value(null),
                ),
              );

      return updated;
    });

    return affected > 0;
  }

  /// Updates an entire operation entity in durable persistence.
  ///
  /// Validates that the operation exists before updating.
  Future<void> updateOperation(FinancialOperation operation) async {
    final companion = PendingOperationMapper.toCompanion(operation);
    final count = await (db.update(
      db.pendingOperations,
    )..where((tbl) => tbl.id.equals(operation.id.value))).write(companion);

    if (count == 0) {
      throw StateError(
        'Cannot update operation ${operation.id}: record not found.',
      );
    }
  }

  /// Recovers operations left in [OperationStatus.processing] after an abrupt process termination.
  ///
  /// Per docs/ARCHITECTURE.md §10.3:
  /// Resets status back to [OperationStatus.pending] while preserving the exact
  /// idempotency key and attempt count so they become eligible to be claimed again.
  Future<int> recoverInterruptedOperations() async {
    return (db.update(db.pendingOperations)
          ..where((tbl) => tbl.status.equals(OperationStatus.processing.name)))
        .write(
          PendingOperationsCompanion(
            status: Value(OperationStatus.pending.name),
          ),
        );
  }

  /// Watches all pending operations via Stream for reactive UI updates.
  Stream<List<FinancialOperation>> watchPendingOperations() {
    final query = db.select(db.pendingOperations)
      ..where((tbl) => tbl.status.equals(OperationStatus.pending.name))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map(
      (rows) => rows.map(PendingOperationMapper.toDomain).toList(),
    );
  }

  /// Watches all active operations (pending + processing) for spendable balance updates.
  Stream<List<FinancialOperation>> watchActiveOperations() {
    final query = db.select(db.pendingOperations)
      ..where(
        (tbl) => tbl.status.isIn([
          OperationStatus.pending.name,
          OperationStatus.processing.name,
        ]),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map(
      (rows) => rows.map(PendingOperationMapper.toDomain).toList(),
    );
  }
}
