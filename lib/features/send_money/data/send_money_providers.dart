import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/features/send_money/data/fake_recipient_directory.dart';
import 'package:novawallet/features/send_money/domain/recipient_directory.dart';

/// Provider for the recipient resolution directory.
final recipientDirectoryProvider = Provider<RecipientDirectory>((ref) {
  return const FakeRecipientDirectory();
});
