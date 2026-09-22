import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/domain/recipient_directory.dart';

/// Fake in-memory directory for resolving recipient accounts.
///
/// Implements SND-003, SND-004.
/// The approved design uses '0123456789' resolving to 'John Doe' (UI-SND-04).
class FakeRecipientDirectory implements RecipientDirectory {
  const FakeRecipientDirectory({
    Map<String, Recipient>? directory,
    Duration? resolutionDelay,
  }) : _directory = directory ?? _defaultDirectory,
       _resolutionDelay = resolutionDelay ?? Duration.zero;

  static const Map<String, Recipient> _defaultDirectory = {
    '0123456789': Recipient(
      accountNumber: '0123456789',
      name: 'John Doe',
      bankName: 'NovaBank',
    ),
    '0987654321': Recipient(
      accountNumber: '0987654321',
      name: 'Jane Smith',
      bankName: 'FirstBank',
    ),
  };

  final Map<String, Recipient> _directory;
  final Duration _resolutionDelay;

  @override
  Future<Recipient?> resolveRecipient(String accountNumber) async {
    if (_resolutionDelay > Duration.zero) {
      await Future<void>.delayed(_resolutionDelay);
    }

    final sanitized = accountNumber.trim().replaceAll(RegExp(r'\s+'), '');

    // NUBAN accounts are strictly 10 numeric digits
    if (sanitized.length != 10 || !RegExp(r'^\d{10}$').hasMatch(sanitized)) {
      return null;
    }

    return _directory[sanitized];
  }
}
