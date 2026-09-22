import 'package:flutter/foundation.dart';

/// Represents a resolved recipient for Send Money.
///
/// Implements SND-001, SND-004.
@immutable
class Recipient {
  const Recipient({
    required this.accountNumber,
    required this.name,
    this.bankName = 'NovaBank',
  });

  /// The 10-digit NUBAN account number of the recipient.
  final String accountNumber;

  /// The verified display name of the recipient (e.g. 'John Doe').
  final String name;

  /// The financial institution of the recipient (e.g. 'NovaBank').
  final String bankName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipient &&
          runtimeType == other.runtimeType &&
          accountNumber == other.accountNumber &&
          name == other.name &&
          bankName == other.bankName;

  @override
  int get hashCode => Object.hash(accountNumber, name, bankName);

  @override
  String toString() => 'Recipient($name, $accountNumber, $bankName)';
}
