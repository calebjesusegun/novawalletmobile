import 'dart:async';
import 'dart:io';

import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// Classifies exceptions encountered during sync attempts into structured [SyncError] metadata.
///
/// Implements requirements:
/// - HC-SYNC: Sync failure does not automatically mean the underlying financial operation is terminally failed.
/// - HC-RETRY: Failed attempts remain observable and recoverable according to the design.
/// - SYNC-012: Recoverable sync failure keeps operation durable and retryable (UI-SND-18, UI-NSV-21).
/// - UI-SND-13 / UI-SND-18: Distinguishes recoverable connection failures from terminal business rejections.
class FailureClassifier {
  const FailureClassifier._();

  /// Classifies any encountered error into a [SyncError].
  ///
  /// Transient failures (transport drops, timeouts, 500/503 server errors) are classified
  /// as recoverable (`isRecoverable == true`).
  ///
  /// Business rejections (invalid account numbers, frozen accounts, conflicting idempotency keys)
  /// are classified as terminal (`isRecoverable == false`).
  static SyncError classify(Object error, [DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now().toUtc();

    if (error is RemoteApiException) {
      return error.toSyncError(timestamp: now);
    }

    if (error is TimeoutException) {
      return SyncError.recoverable(
        message: 'The request timed out. Please check your connection and try again.',
        code: 'TIMEOUT',
        timestamp: now,
      );
    }

    if (error is SocketException) {
      return SyncError.recoverable(
        message: 'Unable to connect to the banking service. Please check your internet connection.',
        code: 'SOCKET_ERROR',
        timestamp: now,
      );
    }

    if (error is FormatException || error is ArgumentError) {
      return SyncError.terminal(
        message: error.toString(),
        code: 'DATA_VALIDATION_ERROR',
        timestamp: now,
      );
    }

    // Default to recoverable to avoid accidental abandonment of user intent / money
    return SyncError.recoverable(
      message: error.toString(),
      code: 'UNCLASSIFIED_ERROR',
      timestamp: now,
    );
  }

  /// Maps a [SyncError] to a user-friendly presentation message matching the approved designs
  /// (UI-SND-13, UI-SND-18, UI-NSV-15, UI-NSV-21).
  static String userMessage(SyncError error) {
    if (error.isRecoverable) {
      if (error.code == 'RESPONSE_LOST') {
        return 'The transfer was sent, but the confirmation response was interrupted. '
            'Tap Retry to check status safely without double-charging.';
      }
      return 'Network connection issue. Your transaction is saved safely and will be sent '
          'when you reconnect, or you can tap Retry.';
    }

    return error.message;
  }
}
