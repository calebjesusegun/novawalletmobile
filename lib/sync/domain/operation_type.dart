/// Represents the distinct types of money-moving financial operations.
enum OperationType {
  /// Send money to a recipient.
  send,

  /// Contribute funds to a NovaSave savings goal.
  contribution;

  /// Returns `true` if this is a Send Money operation.
  bool get isSend => this == OperationType.send;

  /// Returns `true` if this is a NovaSave contribution operation.
  bool get isContribution => this == OperationType.contribution;
}
