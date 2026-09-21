/// Base exception for remote API errors.
abstract class RemoteApiException implements Exception {
  final String message;
  const RemoteApiException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a repeated idempotency key is submitted with a different payload.
///
/// Implements requirement SYNC-009 ("Repeated key with conflicting payload is rejected/flagged").
class ConflictingIdempotencyKeyException extends RemoteApiException {
  final String idempotencyKey;

  const ConflictingIdempotencyKeyException({
    required this.idempotencyKey,
    String? message,
  }) : super(
         message ??
             'Idempotency key "$idempotencyKey" was previously submitted with a different payload.',
       );
}

/// Thrown when the remote account balance has insufficient funds for the operation.
class InsufficientRemoteFundsException extends RemoteApiException {
  final int requestedKobo;
  final int availableKobo;

  const InsufficientRemoteFundsException({
    required this.requestedKobo,
    required this.availableKobo,
    String? message,
  }) : super(
         message ??
             'Insufficient remote balance: requested $requestedKobo kobo, available $availableKobo kobo.',
       );
}

/// Thrown when an operation is invalid or incompatible with the requested remote endpoint.
class InvalidRemoteOperationException extends RemoteApiException {
  const InvalidRemoteOperationException(super.message);
}
