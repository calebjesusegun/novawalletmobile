import 'package:novawallet/features/send_money/domain/recipient.dart';

/// Contract for looking up and resolving recipient account numbers.
///
/// Implements SND-004.
abstract interface class RecipientDirectory {
  /// Resolves an account number to a [Recipient] entity, or returns `null` if not found.
  Future<Recipient?> resolveRecipient(String accountNumber);
}
