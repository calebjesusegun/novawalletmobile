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

/// Exception thrown when an internal operation domain invariant is violated.
class OperationInvariantException implements Exception {
  final String message;

  const OperationInvariantException(this.message);

  @override
  String toString() => 'OperationInvariantException: $message';
}

/// Represents a durable money-moving financial operation in the NovaWallet sync system.
///
/// Also aliased as [PendingOperation] per docs/ARCHITECTURE.md §8.3.
///
/// Under HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT, and HC-SYNC:
/// - One logical financial action has ONE stable [id] and ONE stable [idempotencyKey].
/// - Retries and state transitions NEVER change or regenerate these identities.
/// - The unchecked public constructor and public `copyWith` are eliminated to prevent
///   arbitrary tampering with lifecycle or identity fields.
/// - New operations are created via [FinancialOperation.create], [FinancialOperation.send],
///   or [FinancialOperation.contribution].
/// - Operations rehydrated from persistent storage use [FinancialOperation.restore],
///   which validates all state-to-field combinations strictly.
/// - State transitions follow a strict finite-state machine:
///   * `pending -> processing` via [markProcessing]
///   * `processing -> pending` via [recoverInterrupted] (crash recovery)
///   * `processing -> pending` via [markRecoverableError] (recoverable network failure)
///   * `processing -> completed` via [markCompleted] (remote settlement with reference)
///   * `processing -> failed` via [markTerminalFailure] (terminal business/validation rejection)
///   * `completed -> none` (terminal)
///   * `failed -> none` (terminal)
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

  /// Timestamp when the user created this operation (normalized to UTC).
  final DateTime createdAt;

  /// Current lifecycle state.
  final OperationStatus status;

  /// Number of times synchronization has attempted this operation.
  final int attemptCount;

  /// Timestamp of the most recent sync attempt (normalized to UTC).
  final DateTime? lastAttemptAt;

  /// Error metadata from the most recent sync failure, if any.
  final SyncError? lastError;

  /// Settlement reference returned by the remote backend upon success.
  final String? remoteReference;

  /// Timestamp when the operation settled successfully (normalized to UTC).
  final DateTime? completedAt;

  /// Private constructor enforcing that all instances are constructed via
  /// validated factories or state transitions.
  const FinancialOperation._({
    required this.id,
    required this.type,
    required this.idempotencyKey,
    required this.payload,
    required this.createdAt,
    required this.status,
    required this.attemptCount,
    this.lastAttemptAt,
    this.lastError,
    this.remoteReference,
    this.completedAt,
  });

  /// Creates a new pending financial operation.
  factory FinancialOperation.create({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required OperationPayload payload,
    DateTime? createdAt,
  }) {
    return FinancialOperation._(
      id: id,
      type: payload.type,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      status: OperationStatus.pending,
      attemptCount: 0,
      lastAttemptAt: null,
      lastError: null,
      remoteReference: null,
      completedAt: null,
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

  /// Rehydrates an existing [FinancialOperation] from persistent storage (e.g. Drift/SQLite).
  ///
  /// Strictly validates all field invariants and state combinations:
  /// - [attemptCount] must be non-negative.
  /// - [payload.type] must match [type].
  /// - `pending` operations must NOT have a remote reference or completed timestamp.
  /// - `processing` operations must NOT have a remote reference or completed timestamp,
  ///   and must have [attemptCount] >= 1.
  /// - `completed` operations MUST have a non-blank [remoteReference] and [completedAt],
  ///   [completedAt] must be at or after [createdAt], and MUST NOT have an active [lastError].
  /// - `failed` operations MUST have a terminal (non-recoverable) [lastError], and
  ///   must NOT have a remote reference or completed timestamp.
  factory FinancialOperation.restore({
    required OperationId id,
    required OperationType type,
    required IdempotencyKey idempotencyKey,
    required OperationPayload payload,
    required DateTime createdAt,
    required OperationStatus status,
    required int attemptCount,
    DateTime? lastAttemptAt,
    SyncError? lastError,
    String? remoteReference,
    DateTime? completedAt,
  }) {
    if (payload.type != type) {
      throw ArgumentError.value(
        type,
        'type',
        'Payload type (${payload.type}) must match operation type ($type).',
      );
    }
    if (attemptCount < 0) {
      throw ArgumentError.value(
        attemptCount,
        'attemptCount',
        'Attempt count cannot be negative.',
      );
    }

    final normalizedCreatedAt = createdAt.toUtc();
    final normalizedLastAttemptAt = lastAttemptAt?.toUtc();
    final normalizedCompletedAt = completedAt?.toUtc();
    final trimmedReference = remoteReference?.trim();

    switch (status) {
      case OperationStatus.pending:
        if (trimmedReference != null && trimmedReference.isNotEmpty) {
          throw ArgumentError(
            'A pending operation cannot have a remote reference.',
          );
        }
        if (normalizedCompletedAt != null) {
          throw ArgumentError(
            'A pending operation cannot have a completedAt timestamp.',
          );
        }
        if (lastError != null && !lastError.isRecoverable) {
          throw ArgumentError(
            'A pending operation cannot carry a terminal failure error.',
          );
        }

      case OperationStatus.processing:
        if (trimmedReference != null && trimmedReference.isNotEmpty) {
          throw ArgumentError(
            'A processing operation cannot have a remote reference.',
          );
        }
        if (normalizedCompletedAt != null) {
          throw ArgumentError(
            'A processing operation cannot have a completedAt timestamp.',
          );
        }
        if (attemptCount == 0) {
          throw ArgumentError(
            'A processing operation must have an attemptCount >= 1.',
          );
        }

      case OperationStatus.completed:
        if (trimmedReference == null || trimmedReference.isEmpty) {
          throw ArgumentError(
            'A completed operation must have a non-empty remote reference.',
          );
        }
        if (normalizedCompletedAt == null) {
          throw ArgumentError(
            'A completed operation must have a completedAt timestamp.',
          );
        }
        if (normalizedCompletedAt.isBefore(normalizedCreatedAt)) {
          throw ArgumentError(
            'Completed timestamp cannot be before creation timestamp.',
          );
        }
        if (lastError != null) {
          throw ArgumentError(
            'A completed operation cannot have an active lastError.',
          );
        }

      case OperationStatus.failed:
        if (trimmedReference != null && trimmedReference.isNotEmpty) {
          throw ArgumentError(
            'A failed operation cannot have a remote reference.',
          );
        }
        if (normalizedCompletedAt != null) {
          throw ArgumentError(
            'A failed operation cannot have a completedAt timestamp.',
          );
        }
        if (lastError == null) {
          throw ArgumentError(
            'A failed operation must have a lastError metadata.',
          );
        }
        if (lastError.isRecoverable) {
          throw ArgumentError(
            'A failed operation must have a terminal (non-recoverable) error.',
          );
        }
    }

    return FinancialOperation._(
      id: id,
      type: type,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: normalizedCreatedAt,
      status: status,
      attemptCount: attemptCount,
      lastAttemptAt: normalizedLastAttemptAt,
      lastError: lastError,
      remoteReference: trimmedReference,
      completedAt: normalizedCompletedAt,
    );
  }

  // --- Strict Lifecycle State Transitions ---

  /// Transitions the operation into [OperationStatus.processing] when claimed by sync.
  ///
  /// Allowed ONLY from [OperationStatus.pending]. Rejects transitions from
  /// already processing, completed, or failed operations.
  ///
  /// Safely increments [attemptCount], sets [lastAttemptAt] to [at] (normalized to UTC),
  /// and clears any previous recoverable [lastError] so no stale failure banner
  /// survives during active delivery.
  FinancialOperation markProcessing({DateTime? at}) {
    if (status != OperationStatus.pending) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.processing,
        message:
            'An operation can only transition to processing from pending status. '
            'Current status: $status.',
      );
    }

    if (attemptCount == 0x7FFFFFFFFFFFFFFF) {
      throw const OperationInvariantException(
        'Attempt count exceeds the supported 64-bit integer limit.',
      );
    }

    final attemptTime = (at ?? DateTime.now()).toUtc();
    return _copy(
      status: OperationStatus.processing,
      attemptCount: attemptCount + 1,
      lastAttemptAt: attemptTime,
      clearLastError: true,
    );
  }

  /// Recovers an in-flight operation that was interrupted by an app crash or process kill.
  ///
  /// Allowed ONLY from [OperationStatus.processing].
  ///
  /// Per docs/ARCHITECTURE.md §10.3 and OperationRepository.recoverInterrupted:
  /// - Returns the operation to [OperationStatus.pending] so it is eligible to be claimed again.
  /// - Preserves the exact [idempotencyKey] and [attemptCount].
  FinancialOperation recoverInterrupted() {
    if (status != OperationStatus.processing) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.pending,
        message:
            'Cannot recover interrupted operation from non-processing status ($status).',
      );
    }

    return _copy(status: OperationStatus.pending);
  }

  /// Handles a recoverable sync failure (e.g. connection dropped, network timeout, HTTP 503).
  ///
  /// Allowed ONLY from [OperationStatus.processing].
  ///
  /// Invariants:
  /// - [error.isRecoverable] MUST be `true`.
  /// - Transitions the operation BACK to [OperationStatus.pending].
  /// - Records the [SyncError] metadata and attempt timestamp.
  /// - Preserves the exact [idempotencyKey] for future retry.
  FinancialOperation markRecoverableError({
    required SyncError error,
    DateTime? at,
  }) {
    if (status != OperationStatus.processing) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.pending,
        message:
            'A recoverable sync error can only be recorded from processing status ($status).',
      );
    }
    if (!error.isRecoverable) {
      throw ArgumentError.value(
        error,
        'error',
        'Cannot record a terminal error as a recoverable error. Use markTerminalFailure instead.',
      );
    }

    final attemptTime = (at ?? error.timestamp).toUtc();
    return _copy(
      status: OperationStatus.pending,
      lastError: error,
      lastAttemptAt: attemptTime,
    );
  }

  /// Transitions the operation to [OperationStatus.failed] upon an unrecoverable terminal rejection
  /// (e.g. account invalid, rejected by business rules, unauthorized).
  ///
  /// Allowed ONLY from [OperationStatus.processing].
  ///
  /// Invariants:
  /// - [error.isRecoverable] MUST be `false`.
  /// - Rejects transitions from `pending`, `completed`, or already `failed` operations.
  /// - Releases reservations immediately in the spendable balance policy.
  FinancialOperation markTerminalFailure({
    required SyncError error,
    DateTime? at,
  }) {
    if (status != OperationStatus.processing) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.failed,
        message:
            'A terminal failure can only be recorded from processing status ($status).',
      );
    }
    if (error.isRecoverable) {
      throw ArgumentError.value(
        error,
        'error',
        'Cannot record a recoverable error as a terminal failure. '
            'A transient sync error must never terminally fail an operation.',
      );
    }

    final failureTime = (at ?? error.timestamp).toUtc();
    return _copy(
      status: OperationStatus.failed,
      lastError: error,
      lastAttemptAt: failureTime,
    );
  }

  /// Transitions the operation into [OperationStatus.completed] upon successful remote settlement.
  ///
  /// Allowed ONLY from [OperationStatus.processing].
  ///
  /// Invariants:
  /// - [remoteReference] must be non-empty and non-whitespace; stored trimmed.
  /// - [completedAt] timestamp is set (normalized to UTC).
  /// - Any prior [lastError] is cleared.
  FinancialOperation markCompleted({
    required String remoteReference,
    DateTime? at,
  }) {
    if (status != OperationStatus.processing) {
      throw InvalidOperationTransitionException(
        currentStatus: status,
        targetStatus: OperationStatus.completed,
        message:
            'An operation can only be completed from the processing status ($status).',
      );
    }
    final trimmed = remoteReference.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        remoteReference,
        'remoteReference',
        'Remote reference cannot be empty or whitespace.',
      );
    }

    final completionTime = (at ?? DateTime.now()).toUtc();
    return _copy(
      status: OperationStatus.completed,
      remoteReference: trimmed,
      completedAt: completionTime,
      clearLastError: true,
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
  bool get hasRecoverableError =>
      isPending && lastError != null && lastError!.isRecoverable;

  /// Whether this operation reserves funds against spendable wallet balance.
  bool get reservesFunds => isPending || isProcessing;

  /// Internal transition helper that structurally prevents tampering with
  /// immutable identities ([id], [idempotencyKey], [type], [payload], [createdAt]).
  FinancialOperation _copy({
    required OperationStatus status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    SyncError? lastError,
    bool clearLastError = false,
    String? remoteReference,
    DateTime? completedAt,
  }) {
    return FinancialOperation._(
      id: id,
      type: type,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt,
      status: status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      remoteReference: remoteReference ?? this.remoteReference,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static bool _sameMoment(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialOperation &&
          other.id == id &&
          other.type == type &&
          other.idempotencyKey == idempotencyKey &&
          other.payload == payload &&
          _sameMoment(other.createdAt, createdAt) &&
          other.status == status &&
          other.attemptCount == attemptCount &&
          _sameMoment(other.lastAttemptAt, lastAttemptAt) &&
          other.lastError == lastError &&
          other.remoteReference == remoteReference &&
          _sameMoment(other.completedAt, completedAt));

  @override
  int get hashCode => Object.hash(
    id,
    type,
    idempotencyKey,
    payload,
    createdAt.millisecondsSinceEpoch,
    status,
    attemptCount,
    lastAttemptAt?.millisecondsSinceEpoch,
    lastError,
    remoteReference,
    completedAt?.millisecondsSinceEpoch,
  );

  @override
  String toString() =>
      'FinancialOperation(id: $id, type: $type, status: $status, attempts: $attemptCount)';
}

/// Architectural alias for [FinancialOperation] per docs/ARCHITECTURE.md §8.3.
typedef PendingOperation = FinancialOperation;
