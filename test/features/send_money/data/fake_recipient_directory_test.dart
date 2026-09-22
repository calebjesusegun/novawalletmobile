import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/features/send_money/data/fake_recipient_directory.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';

void main() {
  group('SND-003 / SND-004 — FakeRecipientDirectory', () {
    const directory = FakeRecipientDirectory();

    test('resolves supported John Doe fixture (UI-SND-04)', () async {
      final recipient = await directory.resolveRecipient('0123456789');

      expect(recipient, isNotNull);
      expect(recipient!.name, equals('John Doe'));
      expect(recipient.accountNumber, equals('0123456789'));
      expect(recipient.bankName, equals('NovaBank'));
    });

    test('resolves second supported fixture Jane Smith', () async {
      final recipient = await directory.resolveRecipient('0987654321');

      expect(recipient, isNotNull);
      expect(recipient!.name, equals('Jane Smith'));
      expect(recipient.accountNumber, equals('0987654321'));
      expect(recipient.bankName, equals('FirstBank'));
    });

    test('strips surrounding and internal whitespace', () async {
      final recipient = await directory.resolveRecipient('  01234 56789  ');

      expect(recipient, isNotNull);
      expect(recipient!.name, equals('John Doe'));
    });

    test('returns null for unregistered 10-digit account', () async {
      final recipient = await directory.resolveRecipient('1234567890');

      expect(recipient, isNull);
    });

    test('returns null for short accounts (< 10 digits)', () async {
      final recipient = await directory.resolveRecipient('012345');

      expect(recipient, isNull);
    });

    test('returns null for accounts > 10 digits', () async {
      final recipient = await directory.resolveRecipient('012345678901');

      expect(recipient, isNull);
    });

    test('returns null for non-numeric characters', () async {
      final recipient = await directory.resolveRecipient('01234abcde');

      expect(recipient, isNull);
    });

    test('supports custom injected directory fixtures', () async {
      const custom = FakeRecipientDirectory(
        directory: {
          '1122334455': Recipient(
            accountNumber: '1122334455',
            name: 'Alice Johnson',
            bankName: 'ZenithBank',
          ),
        },
      );

      final recipient = await custom.resolveRecipient('1122334455');
      expect(recipient?.name, equals('Alice Johnson'));

      final defaultFixture = await custom.resolveRecipient('0123456789');
      expect(defaultFixture, isNull);
    });
  });
}
