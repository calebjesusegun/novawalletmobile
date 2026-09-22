import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';

void main() {
  group('SND-001 / SND-004 — Recipient Domain Model', () {
    test('instantiates with required fields and default bank', () {
      const recipient = Recipient(
        accountNumber: '0123456789',
        name: 'John Doe',
      );

      expect(recipient.accountNumber, equals('0123456789'));
      expect(recipient.name, equals('John Doe'));
      expect(recipient.bankName, equals('NovaBank'));
    });

    test('supports equality and value comparisons', () {
      const r1 = Recipient(
        accountNumber: '0123456789',
        name: 'John Doe',
        bankName: 'NovaBank',
      );
      const r2 = Recipient(
        accountNumber: '0123456789',
        name: 'John Doe',
        bankName: 'NovaBank',
      );
      const r3 = Recipient(
        accountNumber: '0987654321',
        name: 'Jane Smith',
        bankName: 'FirstBank',
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('toString formats readable description', () {
      const recipient = Recipient(
        accountNumber: '0123456789',
        name: 'John Doe',
        bankName: 'NovaBank',
      );

      expect(
        recipient.toString(),
        equals('Recipient(John Doe, 0123456789, NovaBank)'),
      );
    });
  });
}
