import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

/// Exception thrown when an operation payload map is missing required fields or has invalid types.
class PayloadFormatException implements FormatException {
  @override
  final String message;
  @override
  final dynamic source;
  @override
  final int? offset;

  const PayloadFormatException(this.message, [this.source, this.offset]);

  @override
  String toString() => 'PayloadFormatException: $message';
}

/// An immutable snapshot of the user intent payload for a financial operation.
///
/// Per docs/ARCHITECTURE.md §8.3, the payload must contain enough immutable information
/// to replay the original user intent without reconstructing it from mutable screen state.
@immutable
sealed class OperationPayload {
  const OperationPayload();

  /// Current schema version for payload serialization.
  static const int currentSchemaVersion = 1;

  /// The financial amount associated with this operation.
  Money get amount;

  /// The corresponding [OperationType].
  OperationType get type;

  /// The schema version of this payload.
  int get schemaVersion => currentSchemaVersion;

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
      'schemaVersion': OperationPayload.currentSchemaVersion,
      'recipientAccountNumber': recipientAccountNumber,
      'recipientName': recipientName,
      'bankName': bankName,
      'amountKobo': amount.kobo,
      if (narration != null) 'narration': narration,
    };
  }

  factory SendMoneyPayload.fromMap(Map<String, dynamic> map) {
    final recipientAccountNumber = map['recipientAccountNumber'];
    if (recipientAccountNumber is! String) {
      throw PayloadFormatException(
        'Missing or invalid recipientAccountNumber: $recipientAccountNumber',
        map,
      );
    }

    final recipientName = map['recipientName'];
    if (recipientName is! String) {
      throw PayloadFormatException(
        'Missing or invalid recipientName: $recipientName',
        map,
      );
    }

    final bankName = map['bankName'];
    if (bankName is! String) {
      throw PayloadFormatException(
        'Missing or invalid bankName: $bankName',
        map,
      );
    }

    final amountKobo = map['amountKobo'];
    if (amountKobo is! int) {
      throw PayloadFormatException(
        'Missing or invalid amountKobo: $amountKobo',
        map,
      );
    }

    final narration = map['narration'];
    if (narration != null && narration is! String) {
      throw PayloadFormatException('Invalid narration: $narration', map);
    }

    try {
      return SendMoneyPayload(
        recipientAccountNumber: recipientAccountNumber,
        recipientName: recipientName,
        bankName: bankName,
        amount: Money.fromKobo(amountKobo),
        narration: narration as String?,
      );
    } catch (e) {
      throw PayloadFormatException('Invalid SendMoneyPayload values: $e', map);
    }
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
    return {
      'schemaVersion': OperationPayload.currentSchemaVersion,
      'goalId': goalId,
      'goalName': goalName,
      'amountKobo': amount.kobo,
    };
  }

  factory ContributionPayload.fromMap(Map<String, dynamic> map) {
    final goalId = map['goalId'];
    if (goalId is! String) {
      throw PayloadFormatException('Missing or invalid goalId: $goalId', map);
    }

    final goalName = map['goalName'];
    if (goalName is! String) {
      throw PayloadFormatException(
        'Missing or invalid goalName: $goalName',
        map,
      );
    }

    final amountKobo = map['amountKobo'];
    if (amountKobo is! int) {
      throw PayloadFormatException(
        'Missing or invalid amountKobo: $amountKobo',
        map,
      );
    }

    try {
      return ContributionPayload(
        goalId: goalId,
        goalName: goalName,
        amount: Money.fromKobo(amountKobo),
      );
    } catch (e) {
      throw PayloadFormatException(
        'Invalid ContributionPayload values: $e',
        map,
      );
    }
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
