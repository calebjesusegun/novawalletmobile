import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

/// An immutable snapshot of the user intent payload for a financial operation.
///
/// Per docs/ARCHITECTURE.md §8.3, the payload must contain enough immutable information
/// to replay the original user intent without reconstructing it from mutable screen state.
@immutable
sealed class OperationPayload {
  const OperationPayload();

  /// The financial amount associated with this operation.
  Money get amount;

  /// The corresponding [OperationType].
  OperationType get type;

  /// Serializes the payload to a JSON-compatible map for persistence.
  Map<String, dynamic> toMap();

  /// Deserializes an [OperationPayload] based on its [OperationType].
  static OperationPayload fromMap(
    OperationType type,
    Map<String, dynamic> map,
  ) {
    switch (type) {
      case OperationType.send:
        return SendMoneyPayload.fromMap(map);
      case OperationType.contribution:
        return ContributionPayload.fromMap(map);
    }
  }
}

/// Payload snapshot for a Send Money operation.
@immutable
class SendMoneyPayload extends OperationPayload {
  final String recipientAccountNumber;
  final String recipientName;
  final String bankName;
  @override
  final Money amount;
  final String? narration;

  SendMoneyPayload({
    required this.recipientAccountNumber,
    required this.recipientName,
    required this.bankName,
    required this.amount,
    this.narration,
  }) {
    if (recipientAccountNumber.trim().isEmpty) {
      throw ArgumentError.value(
        recipientAccountNumber,
        'recipientAccountNumber',
        'Recipient account number cannot be empty.',
      );
    }
    if (recipientName.trim().isEmpty) {
      throw ArgumentError.value(
        recipientName,
        'recipientName',
        'Recipient name cannot be empty.',
      );
    }
    if (bankName.trim().isEmpty) {
      throw ArgumentError.value(
        bankName,
        'bankName',
        'Bank name cannot be empty.',
      );
    }
    amount.ensurePositive();
  }

  @override
  OperationType get type => OperationType.send;

  @override
  Map<String, dynamic> toMap() {
    return {
      'recipientAccountNumber': recipientAccountNumber,
      'recipientName': recipientName,
      'bankName': bankName,
      'amountKobo': amount.kobo,
      if (narration != null) 'narration': narration,
    };
  }

  factory SendMoneyPayload.fromMap(Map<String, dynamic> map) {
    return SendMoneyPayload(
      recipientAccountNumber: map['recipientAccountNumber'] as String,
      recipientName: map['recipientName'] as String,
      bankName: map['bankName'] as String,
      amount: Money.fromKobo(map['amountKobo'] as int),
      narration: map['narration'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SendMoneyPayload &&
          other.recipientAccountNumber == recipientAccountNumber &&
          other.recipientName == recipientName &&
          other.bankName == bankName &&
          other.amount == amount &&
          other.narration == narration);

  @override
  int get hashCode => Object.hash(
    recipientAccountNumber,
    recipientName,
    bankName,
    amount,
    narration,
  );

  @override
  String toString() =>
      'SendMoneyPayload(to: $recipientName, account: $recipientAccountNumber, bank: $bankName, amount: $amount)';
}

/// Payload snapshot for a NovaSave contribution operation.
@immutable
class ContributionPayload extends OperationPayload {
  final String goalId;
  final String goalName;
  @override
  final Money amount;

  ContributionPayload({
    required this.goalId,
    required this.goalName,
    required this.amount,
  }) {
    if (goalId.trim().isEmpty) {
      throw ArgumentError.value(goalId, 'goalId', 'Goal ID cannot be empty.');
    }
    if (goalName.trim().isEmpty) {
      throw ArgumentError.value(
        goalName,
        'goalName',
        'Goal name cannot be empty.',
      );
    }
    amount.ensurePositive();
  }

  @override
  OperationType get type => OperationType.contribution;

  @override
  Map<String, dynamic> toMap() {
    return {'goalId': goalId, 'goalName': goalName, 'amountKobo': amount.kobo};
  }

  factory ContributionPayload.fromMap(Map<String, dynamic> map) {
    return ContributionPayload(
      goalId: map['goalId'] as String,
      goalName: map['goalName'] as String,
      amount: Money.fromKobo(map['amountKobo'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContributionPayload &&
          other.goalId == goalId &&
          other.goalName == goalName &&
          other.amount == amount);

  @override
  int get hashCode => Object.hash(goalId, goalName, amount);

  @override
  String toString() =>
      'ContributionPayload(goalId: $goalId, goalName: $goalName, amount: $amount)';
}
