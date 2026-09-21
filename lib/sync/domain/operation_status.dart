/// Represents the lifecycle state of a specific financial operation.
///
/// Per HC-STATE-SEPARATION and HC-OFFLINE-DURABILITY:
/// - [pending]: The operation is durably stored and waiting to be processed by sync.
/// - [processing]: The operation has been atomically claimed and is currently in-flight.
/// - [completed]: The operation successfully settled remotely and produced its single financial effect.
/// - [failed]: The operation was terminally rejected (e.g. invalid recipient account).
enum OperationStatus {
  /// Waiting to be claimed and delivered.
  pending,

  /// Actively claimed and being submitted to the remote backend.
  processing,

  /// Successfully confirmed by the remote backend. Terminal state.
  completed,

  /// Terminally rejected. Terminal state.
  failed;

  /// Returns `true` if this operation is pending synchronization or retry.
  bool get isPending => this == OperationStatus.pending;

  /// Returns `true` if this operation is currently in-flight.
  bool get isProcessing => this == OperationStatus.processing;

  /// Returns `true` if this operation reached successful completion.
  bool get isCompleted => this == OperationStatus.completed;

  /// Returns `true` if this operation encountered a terminal failure.
  bool get isFailed => this == OperationStatus.failed;

  /// Returns `true` if this status is terminal (completed or failed).
  bool get isTerminal =>
      this == OperationStatus.completed || this == OperationStatus.failed;
}
