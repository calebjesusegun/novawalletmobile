import 'package:novawallet/sync/domain/sync_error.dart';

/// Base exception for all remote API errors.
///
/// Under HC-SYNC and docs/ARCHITECTURE.md §12.4, remote exceptions expose
/// whether they are transient/recoverable (e.g. network timeout, 503) or
/// terminal (e.g. business rejection, insufficient funds, conflicting key).
abstract class RemoteApiException implements Exception {
  final String message;
  final String code;
  final bool isRecoverable;

  const RemoteApiException({
    required this.message,
    required this.code,
    required this.isRecoverable,
  });

  /// Maps this remote exception directly to a domain [SyncError] metadata object.
  SyncError toSyncError({DateTime? timestamp}) {
    return SyncError(
      message: message,
      code: code,
      isRecoverable: isRecoverable,
      timestamp: (timestamp ?? DateTime.now()).toUtc(),
    );
  }

  @override
  String toString() =>
      '$runtimeType [$code]: $message (recoverable: $isRecoverable)';
}

/// Thrown when a transient network, connection, or socket error occurs.
///
/// Recoverable: operation should remain pending in queue and retryable upon reconnection.
class RemoteTransportException extends RemoteApiException {
  const RemoteTransportException({
    super.message =
        'Network connection failed. Please check your internet connection.',
    super.code = 'TRANSPORT_ERROR',
  }) : super(isRecoverable: true);
}

/// Thrown when the remote server experiences an internal error (e.g. HTTP 500, 503 Service Unavailable).
///
/// Recoverable: operation should remain pending and retryable.
class RemoteServerException extends RemoteApiException {
  const RemoteServerException({
    super.message =
        'Remote banking service is temporarily unavailable. Please try again.',
    super.code = 'SERVER_ERROR',
  }) : super(isRecoverable: true);
}

/// Thrown when the remote server settles the operation, but the response is lost before delivery to the client.
///
/// Implements requirement SYNC-011 and TST-007 (Uncertain response scenario).
/// Recoverable: operation remains pending. Upon replay with the SAME idempotency key,
/// the remote server returns the cached result without a second debit.
class RemoteResponseLostException extends RemoteApiException {
  final String remoteReference;

  const RemoteResponseLostException({
    required this.remoteReference,
    super.message = 'Operation accepted by bank, but response was lost due to connection interruption.',
    super.code = 'RESPONSE_LOST',
  }) : super(isRecoverable: true);
}

/// Thrown when a non-recoverable business or regulatory rejection occurs at the bank
/// (e.g. invalid account number, account frozen, bank transfer blocked).
///
/// Non-recoverable (terminal): operation transitions to failed state and releases reservation.
class RemoteBusinessRejectionException extends RemoteApiException {
  const RemoteBusinessRejectionException({
    required super.message,
    super.code = 'BUSINESS_REJECTION',
  }) : super(isRecoverable: false);
}

/// Thrown when a repeated idempotency key is submitted with a different payload.
///
/// Implements requirement SYNC-009 ("Repeated key with conflicting payload is rejected/flagged").
/// Terminal error.
class ConflictingIdempotencyKeyException extends RemoteApiException {
  final String idempotencyKey;

  ConflictingIdempotencyKeyException({
    required this.idempotencyKey,
    String? message,
  }) : super(
         message:
             message ??
             'Idempotency key "$idempotencyKey" was previously submitted with a different payload.',
         code: 'CONFLICTING_KEY',
         isRecoverable: false,
       );
}

/// Thrown when the remote account balance has insufficient funds for the operation.
///
/// Terminal error.
class InsufficientRemoteFundsException extends RemoteApiException {
  final int requestedKobo;
  final int availableKobo;

  InsufficientRemoteFundsException({
    required this.requestedKobo,
    required this.availableKobo,
    String? message,
  }) : super(
         message:
             message ??
             'Insufficient remote balance: requested $requestedKobo kobo, available $availableKobo kobo.',
         code: 'INSUFFICIENT_FUNDS',
         isRecoverable: false,
       );
}

/// Thrown when an operation is invalid or incompatible with the requested remote endpoint.
///
/// Terminal error.
class InvalidRemoteOperationException extends RemoteApiException {
  const InvalidRemoteOperationException(
    String message, {
    super.code = 'INVALID_OPERATION',
  }) : super(message: message, isRecoverable: false);
}
