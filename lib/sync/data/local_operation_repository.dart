import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// Concrete Drift SQLite implementation of [OperationRepository].
///
/// Hides all database and SQL details from domain, application, and UI layers.
/// Provides durable enqueue and atomic state transitions for offline actions.
class LocalOperationRepository implements OperationRepository {
  final PendingOperationsDao _dao;

  LocalOperationRepository(this._dao);

  @override
  Future<FinancialOperation> enqueue(FinancialOperation operation) async {
    if (operation.status != OperationStatus.pending) {
      throw StateError(
        'Cannot enqueue operation ${operation.id}: must be in pending status, but was ${operation.status}.',
      );
    }
    if (operation.attemptCount != 0) {
      throw StateError(
        'Cannot enqueue operation ${operation.id}: attemptCount must be 0 for a new intent.',
      );
    }

    // Insert into Drift SQLite. If a constraint or I/O failure occurs,
    // this call throws and the caller never receives a false saved acknowledgment (SYNC-002).
    await _dao.insertOperation(operation);

    // Confirm read-back from persistent storage to guarantee durability
    final persisted = await _dao.getOperationById(operation.id);
    if (persisted == null) {
      throw StateError(
        'Persistence confirmation failed for operation ${operation.id}',
      );
    }
    return persisted;
  }

  @override
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  }) {
    final operation = FinancialOperation.send(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt,
    );
    return enqueue(operation);
  }

  @override
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) {
    final operation = FinancialOperation.contribution(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt,
    );
    return enqueue(operation);
  }

  @override
  Future<FinancialOperation?> getOperationById(OperationId id) =>
      _dao.getOperationById(id);

  @override
  Future<FinancialOperation?> getOperationByIdempotencyKey(
    IdempotencyKey key,
  ) => _dao.getOperationByIdempotencyKey(key);

  @override
  Future<List<FinancialOperation>> getPendingOperations() =>
      _dao.getPendingOperations();

  @override
  Future<List<FinancialOperation>> getActiveOperations() =>
      _dao.getActiveOperations();

  @override
  Future<List<FinancialOperation>> getAllOperations() =>
      _dao.getAllOperations();

  @override
  Future<bool> claim(OperationId id, {DateTime? at}) =>
      _dao.claimOperation(id, at: at);

  @override
  Future<void> update(FinancialOperation operation) =>
      _dao.updateOperation(operation);

  @override
  Future<FinancialOperation> markPendingWithError(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) async {
    final op = await _dao.getOperationById(id);
    if (op == null) {
      throw StateError('Cannot mark error: operation $id not found.');
    }
    final updated = op.markRecoverableError(error: error, at: at);
    await _dao.updateOperation(updated);
    return updated;
  }

  @override
  Future<FinancialOperation> markCompleted(
    OperationId id, {
    required String remoteReference,
    DateTime? at,
  }) async {
    final op = await _dao.getOperationById(id);
    if (op == null) {
      throw StateError('Cannot mark completed: operation $id not found.');
    }
    final updated = op.markCompleted(remoteReference: remoteReference, at: at);
    await _dao.updateOperation(updated);
    return updated;
  }

  @override
  Future<FinancialOperation> markFailed(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) async {
    final op = await _dao.getOperationById(id);
    if (op == null) {
      throw StateError('Cannot mark failed: operation $id not found.');
    }
    final updated = op.markTerminalFailure(error: error, at: at);
    await _dao.updateOperation(updated);
    return updated;
  }

  @override
  Future<int> recoverInterrupted() => _dao.recoverInterruptedOperations();

  @override
  Stream<List<FinancialOperation>> watchPendingOperations() =>
      _dao.watchPendingOperations();

  @override
  Stream<List<FinancialOperation>> watchActiveOperations() =>
      _dao.watchActiveOperations();
}
