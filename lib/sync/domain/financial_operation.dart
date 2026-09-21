import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// Exception thrown when an invalid operation state transition is attempted.
class InvalidOperationTransitionException implements Exception {
  final OperationStatus currentStatus;
  final OperationStatus targetStatus;
  final String message;

  const InvalidOperationTransitionException({
    required this.currentStatus,
    required this.targetStatus,
    required this.message,
  });

  @override
  String toString() =>
      'InvalidOperationTransitionException: Cannot transition from $currentStatus '
      'to $targetStatus: $message';
}

/// Represents a durable money-moving financial operation in the NovaWallet sync system.
///
/// Also aliased as [PendingOperation] per docs/ARCHITECTURE.md §8.3.
///
/// Invariants enforced:
/// - Stable [id] and [idempotencyKey] never change across retries or state transitions.
/// - Valid state transitions follow the operation lifecycle (Section 10 of Architecture).
/// - Recoverable sync errors return/keep the operation in [OperationStatus.pending] state.
/// - Only terminal rejections transition the operation to [OperationStatus.failed].
/// - Once [OperationStatus.completed] or [OperationStatus.failed] is reached, no further
///   transitions are allowed (terminal state).
@immutable
class FinancialOperation {
  /// Unique local durable identifier.
  final OperationId id;

  /// Type of operation (Send Money or NovaSave Contribution).
  final OperationType type;

  /// Stable remote idempotency key reused across retries.
  final IdempotencyKey idempotencyKey;

  /// Immutable snapshot of the user's intent payload.
  final OperationPayload payload;

  /// Timestamp when the user created this operation.
  final DateTime createdAt;

  /// Current lifecycle state.
  final OperationStatus status;

  /// Number of times synchronization has attempted this operation.
  final int attemptCount;

  /// Timestamp of the most recent sync attempt.
  final DateTime? lastAttemptAt;

  /// Error metadata from the most recent sync failure, if any.
  final SyncError? lastError;

  /// Settlement reference returned by the remote backend upon success.
  final String? remoteReference;

  /// Timestamp when the operation settled successfully.
  final DateTime? completedAt;

  FinancialOperation({
    required this.id,
    required this.type,
    required this.idempotencyKey,
    required this.payload,
    required this.createdAt,
    required this.status,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.remoteReference,
    this.completedAt,
  }) {
    if (payload.type != type) {
      throw ArgumentError.value(
        type,
        'type',
        'Payload type (${payload.type}) must match operation type ($type)',
      );
    }
  }

  /// Creates a new pending financial operation.
  factory FinancialOperation.create({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required OperationPayload payload,
    DateTime? createdAt,
  }) {
    return FinancialOperation(
      id: id,
      type: payload.type,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt ?? DateTime.now(),
      status: OperationStatus.pending,
      attemptCount: 0,
    );
  }

  /// Convenience factory for creating a Send Money operation.
  factory FinancialOperation.send({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  }) {
    return FinancialOperation.create(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt,
    );
  }

  /// Convenience factory for creating a NovaSave contribution operation.
  factory FinancialOperation.contribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) {
    return FinancialOperation.create(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt,
    );
  }

  // --- State Transitions ---

  /// Transitions the operation into [OperationStatus.processing] when claimed by sync.
  ///
  /// Allowed from: [OperationStatus.pending], or [OperationStatus.processing] during
  /// uncertain crash-recovery resumption on startup.
  FinancialOperation markProcessing({DateTime? attemptTime}) {
    if (status.isTerminal) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.processing,
        message: 'Cannot reprocess an operation that has already reached a terminal state.',
      );
    }

    final now = attemptTime ?? DateTime.now();
    return copyWith(
      status: OperationStatus.processing,
      attemptCount: attemptCount + 1,
      lastAttemptAt: now,
    );
  }

  /// Transitions the operation into [OperationStatus.completed] upon successful remote settlement.
  ///
  /// Allowed only from [OperationStatus.processing].
  FinancialOperation markCompleted({
    required String remoteReference,
    DateTime? completedAt,
  }) {
    if (status != OperationStatus.processing) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.completed,
        message:
            'An operation can only be completed from the processing state.',
      );
    }
    if (remoteReference.trim().isEmpty) {
      throw ArgumentError.value(
        remoteReference,
        'remoteReference',
        'Remote reference cannot be empty.',
      );
    }

    final now = completedAt ?? DateTime.now();
    return copyWith(
      status: OperationStatus.completed,
      remoteReference: remoteReference,
      completedAt: now,
      clearLastError: true,
    );
  }

  /// Handles a recoverable sync failure (e.g. connection dropped, network timeout, 503).
  ///
  /// Transitions the operation BACK to [OperationStatus.pending] and records the
  /// [SyncError] metadata. Per HC-SYNC, the operation remains safely queued and retryable.
  FinancialOperation markRecoverableError({
    required SyncError error,
    DateTime? attemptTime,
  }) {
    if (status.isTerminal) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.pending,
        message: 'Cannot apply sync error to an operation in a terminal state.',
      );
    }
    if (!error.isRecoverable) {
      throw ArgumentError.value(
        error,
        'error',
        'Cannot apply a terminal error as a recoverable error. Use markTerminalFailure instead.',
      );
    }

    return copyWith(
      status: OperationStatus.pending,
      lastError: error,
      lastAttemptAt: attemptTime ?? error.timestamp,
    );
  }

  /// Transitions the operation to [OperationStatus.failed] upon an unrecoverable terminal rejection
  /// (e.g. account invalid, rejected by business rules).
  FinancialOperation markTerminalFailure({required SyncError error}) {
    if (status == OperationStatus.completed) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.failed,
        message: 'Cannot fail an operation that has already completed.',
      );
    }

    return copyWith(
      status: OperationStatus.failed,
      lastError: error,
      lastAttemptAt: error.timestamp,
    );
  }

  // --- Convenience Getters ---

  /// Whether this operation is queued and awaiting sync or retry.
  bool get isPending => status == OperationStatus.pending;

  /// Whether this operation is actively in-flight.
  bool get isProcessing => status == OperationStatus.processing;

  /// Whether this operation successfully completed.
  bool get isCompleted => status == OperationStatus.completed;

  /// Whether this operation encountered a terminal failure.
  bool get isFailed => status == OperationStatus.failed;

  /// Whether this operation is in a terminal state (completed or failed).
  bool get isTerminal => status.isTerminal;

  /// Whether this operation is eligible to be claimed and submitted by sync.
  bool get isEligibleForSync => status == OperationStatus.pending;

  /// Whether this operation has previously failed a sync attempt with a recoverable error.
  bool get hasRecoverableError => isPending && lastError != null;

  /// Returns a copy of this operation with updated properties.
  FinancialOperation copyWith({
    OperationId? id,
    OperationType? type,
    IdempotencyKey? idempotencyKey,
    OperationPayload? payload,
    DateTime? createdAt,
    OperationStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    SyncError? lastError,
    bool clearLastError = false,
    String? remoteReference,
    DateTime? completedAt,
  }) {
    return FinancialOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      remoteReference: remoteReference ?? this.remoteReference,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialOperation &&
          other.id == id &&
          other.type == type &&
          other.idempotencyKey == idempotencyKey &&
          other.payload == payload &&
          other.createdAt.isAtSameMomentAs(createdAt) &&
          other.status == status &&
          other.attemptCount == attemptCount &&
          other.lastAttemptAt == lastAttemptAt &&
          other.lastError == lastError &&
          other.remoteReference == remoteReference &&
          other.completedAt == completedAt);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    idempotencyKey,
    payload,
    createdAt,
    status,
    attemptCount,
    lastAttemptAt,
    lastError,
    remoteReference,
    completedAt,
  );

  @override
  String toString() =>
      'FinancialOperation(id: $id, type: $type, status: $status, attempts: $attemptCount)';
}

/// Architectural alias for [FinancialOperation] per docs/ARCHITECTURE.md §8.3.
typedef PendingOperation = FinancialOperation;
