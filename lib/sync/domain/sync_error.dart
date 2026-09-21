import 'package:flutter/foundation.dart';

/// Represents error metadata captured during an operation synchronization attempt.
///
/// Under HC-SYNC, a synchronization failure does not automatically mean the underlying
/// financial operation has terminally failed. Recoverable errors (e.g. connectivity drop,
/// timeout, 503) keep the operation pending and retryable.
@immutable
class SyncError {
  /// A human-readable description of the error.
  final String message;

  /// An optional machine-readable error code (e.g. `NETWORK_TIMEOUT`, `INVALID_ACCOUNT`).
  final String? code;

  /// Whether this error is transient and recoverable via retry.
  ///
  /// If `true`, the operation transitions back to [OperationStatus.pending] with this metadata.
  /// If `false`, the operation transitions to [OperationStatus.failed] (terminal failure).
  final bool isRecoverable;

  /// When this error occurred.
  final DateTime timestamp;

  const SyncError({
    required this.message,
    this.code,
    required this.isRecoverable,
    required this.timestamp,
  });

  /// Creates a recoverable sync error (e.g. network failure, timeout).
  factory SyncError.recoverable({
    required String message,
    String? code,
    DateTime? timestamp,
  }) {
    return SyncError(
      message: message,
      code: code,
      isRecoverable: true,
      timestamp: (timestamp ?? DateTime.now()).toUtc(),
    );
  }

  /// Creates a terminal sync error (e.g. validation rejection, closed account).
  factory SyncError.terminal({
    required String message,
    String? code,
    DateTime? timestamp,
  }) {
    return SyncError(
      message: message,
      code: code,
      isRecoverable: false,
      timestamp: (timestamp ?? DateTime.now()).toUtc(),
    );
  }

  /// Serializes to map for durable persistence.
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      if (code != null) 'code': code,
      'isRecoverable': isRecoverable,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  /// Deserializes from map.
  factory SyncError.fromMap(Map<String, dynamic> map) {
    return SyncError(
      message: map['message'] as String,
      code: map['code'] as String?,
      isRecoverable: map['isRecoverable'] as bool,
      timestamp: DateTime.parse(map['timestamp'] as String).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncError &&
          other.message == message &&
          other.code == code &&
          other.isRecoverable == isRecoverable &&
          other.timestamp.isAtSameMomentAs(timestamp));

  @override
  int get hashCode => Object.hash(message, code, isRecoverable, timestamp);

  @override
  String toString() =>
      'SyncError(message: $message, code: $code, isRecoverable: $isRecoverable, timestamp: $timestamp)';
}
