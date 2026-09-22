import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// Contract for durable queue and lifecycle management of financial operations.
///
/// Implements requirements:
/// - HC-OFFLINE-DURABILITY: Operations must be durably persisted before acknowledging "saved".
/// - HC-IDEMPOTENCY: Reuses stable [OperationId] and [IdempotencyKey].
/// - HC-SYNC: Centralized store for pending-operation processing.
/// - SYNC-002, SND-015, NSV-017: Enqueue offline actions reliably.
abstract interface class OperationRepository {
  /// Durably enqueues a [FinancialOperation] in the local persistent store.
  ///
  /// Guarantees:
  /// - Only operations in [OperationStatus.pending] can be enqueued.
  /// - Persisted to database before returning.
  /// - Rethrows on any storage error so caller never receives a false saved/pending acknowledgment.
  Future<FinancialOperation> enqueue(FinancialOperation operation);

  /// Convenience method to create and durably enqueue a Send Money operation.
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  });

  /// Convenience method to create and durably enqueue a NovaSave Contribution operation.
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  });

  /// Retrieves an operation by its local [OperationId].
  Future<FinancialOperation?> getOperationById(OperationId id);

  /// Retrieves an operation by its remote [IdempotencyKey].
  Future<FinancialOperation?> getOperationByIdempotencyKey(IdempotencyKey key);

  /// Retrieves all operations in [OperationStatus.pending], ordered oldest first.
  Future<List<FinancialOperation>> getPendingOperations();

  /// Retrieves all active operations (pending + processing) that reserve funds.
  Future<List<FinancialOperation>> getActiveOperations();

  /// Retrieves all persisted operations.
  Future<List<FinancialOperation>> getAllOperations();

  /// Atomically claims an eligible pending operation for sync processing.
  Future<bool> claim(OperationId id, {DateTime? at});

  /// Updates an entire operation entity in persistent storage.
  Future<void> update(FinancialOperation operation);

  /// Transitions an operation from processing back to pending with recoverable error metadata.
  Future<FinancialOperation> markPendingWithError(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  });

  /// Transitions an operation from processing to completed with remote settlement reference.
  Future<FinancialOperation> markCompleted(
    OperationId id, {
    required String remoteReference,
    DateTime? at,
  });

  /// Transitions an operation from processing to terminal failure.
  Future<FinancialOperation> markFailed(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  });

  /// Recovers operations left in processing state after an abrupt shutdown.
  Future<int> recoverInterrupted();

  /// Watches all pending operations for reactive UI and sync coordination.
  Stream<List<FinancialOperation>> watchPendingOperations();

  /// Watches all active operations for real-time spendable balance calculations.
  Stream<List<FinancialOperation>> watchActiveOperations();

  /// Watches a specific operation by its [OperationId].
  Stream<FinancialOperation?> watchOperationById(OperationId id);
}
