import 'package:flutter/foundation.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// The status outcome of an explicit single-operation retry attempt.
enum RetryStatus {
  /// The operation was retried and successfully processed to completion.
  success,

  /// The operation was retried and failed with a recoverable or terminal error.
  failed,

  /// The retry was skipped because the device is currently offline.
  offline,

  /// The retry was skipped because the operation is currently claimed or in-flight
  /// by an ongoing sync pass (prevents concurrent race conditions).
  alreadyProcessing,

  /// The operation is not eligible for retry (e.g. not found, already completed, or terminally failed).
  notRetryable,
}

/// The result returned by an explicit single-operation retry invocation.
@immutable
class RetryResult {
  final RetryStatus status;
  final SyncError? error;
  final String? remoteReference;

  const RetryResult({required this.status, this.error, this.remoteReference});

  const RetryResult.success({this.remoteReference})
    : status = RetryStatus.success,
      error = null;

  const RetryResult.failed(this.error)
    : status = RetryStatus.failed,
      remoteReference = null;

  const RetryResult.offline()
    : status = RetryStatus.offline,
      error = null,
      remoteReference = null;

  const RetryResult.alreadyProcessing()
    : status = RetryStatus.alreadyProcessing,
      error = null,
      remoteReference = null;

  const RetryResult.notRetryable()
    : status = RetryStatus.notRetryable,
      error = null,
      remoteReference = null;

  bool get isSuccess => status == RetryStatus.success;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetryResult &&
          other.status == status &&
          other.error == error &&
          other.remoteReference == remoteReference);

  @override
  int get hashCode => Object.hash(status, error, remoteReference);

  @override
  String toString() =>
      'RetryResult(status: $status, error: $error, reference: $remoteReference)';
}

/// Defines retry eligibility rules per HC-RETRY, HC-IDEMPOTENCY, and HC-SYNC.
///
/// Under HC-RETRY:
/// - There is NO silent, unmetered background timer loop.
/// - Retries are strictly event-driven: user tap ('userRetry'), network reconnect ('reconnect'),
///   or app start/resume ('startup').
/// - An operation cannot be retried if it is already claimed/processing (race protection).
/// - An operation cannot be retried if it is terminally failed or already completed.
class RetryPolicy {
  const RetryPolicy._();

  /// Evaluates whether a given [operation] is currently eligible for retry.
  static bool canRetry(FinancialOperation? operation, {bool isOnline = true}) {
    if (operation == null) return false;
    if (!isOnline) return false;

    switch (operation.status) {
      case OperationStatus.pending:
        return true;
      case OperationStatus.processing:
        // Already in-flight; cannot race concurrent attempts
        return false;
      case OperationStatus.completed:
      case OperationStatus.failed:
        // Terminal states cannot be retried
        return false;
    }
  }
}
