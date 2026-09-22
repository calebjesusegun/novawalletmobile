import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/amount_entry_controller.dart';

void main() {
  group('SND-005–SND-008 / MNY-003 / MNY-006 — AmountEntryController', () {
    const testRecipient = Recipient(
      accountNumber: '0123456789',
      name: 'John Doe',
      bankName: 'NovaBank',
    );

    late AmountEntryController controller;

    setUp(() {
      controller = AmountEntryController(
        recipient: testRecipient,
        spendableBalance: Money.fromNaira(50000), // ₦50,000.00
        confirmedBalance: Money.fromNaira(50000),
        isOffline: false,
        lastUpdatedAt: DateTime.utc(2026, 9, 21),
      );
    });

    test('initial state has zero amount and disabled continue', () {
      expect(controller.state.recipient, equals(testRecipient));
      expect(controller.state.amount, equals(const Money.zero()));
      expect(controller.state.rawInput, isEmpty);
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isFalse);
      expect(controller.state.balanceAfter, isNull);
    });

    test('entering empty string resets state to zero without error', () {
      controller.onAmountChanged('1000');
      expect(controller.state.amount, equals(Money.fromNaira(1000)));

      controller.onAmountChanged('');
      expect(controller.state.amount, equals(const Money.zero()));
      expect(controller.state.rawInput, isEmpty);
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isFalse);
    });

    test('entering zero rejects with greater-than-zero error (SND-006 / UI-SND-08)', () {
      controller.onAmountChanged('0');

      expect(controller.state.amount, equals(const Money.zero()));
      expect(
        controller.state.validationError,
        equals('Amount must be greater than zero.'),
      );
      expect(controller.state.canContinue, isFalse);
      expect(controller.state.balanceAfter, isNull);
    });

    test(
      'entering negative amount rejects with greater-than-zero error (SND-006)',
      () {
        controller.onAmountChanged('-500');

        expect(
          controller.state.validationError,
          equals('Amount must be greater than zero.'),
        );
        expect(controller.state.canContinue, isFalse);
      },
    );

    test('entering amount exceeding spendable balance rejects (SND-007 / UI-SND-07 / MNY-006)', () {
      controller.onAmountChanged('55000'); // > 50,000 spendable

      expect(controller.state.amount, equals(Money.fromNaira(55000)));
      expect(
        controller.state.validationError,
        equals('Amount exceeds available balance.'),
      );
      expect(controller.state.canContinue, isFalse);
      expect(controller.state.balanceAfter, isNull);
    });

    test('entering valid positive amount enables continue and computes balanceAfter (SND-005 / UI-SND-06)', () {
      controller.onAmountChanged('10000'); // ₦10,000.00

      expect(controller.state.amount, equals(Money.fromNaira(10000)));
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isTrue);
      // Balance after = 50,000 - 10,000 = 40,000
      expect(controller.state.balanceAfter, equals(Money.fromNaira(40000)));
    });

    test('entering amount exactly equal to spendable balance is valid', () {
      controller.onAmountChanged('50000'); // Exactly 50,000

      expect(controller.state.amount, equals(Money.fromNaira(50000)));
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isTrue);
      expect(controller.state.balanceAfter, equals(const Money.zero()));
    });

    test('updateProjection revalidates current input against new spendable balance', () {
      controller.onAmountChanged('40000');
      expect(controller.state.canContinue, isTrue);

      // Spendable balance drops to ₦30,000 due to offline queue spendability deduction
      controller.updateProjection(
        spendableBalance: Money.fromNaira(30000),
        confirmedBalance: Money.fromNaira(50000),
      );

      // 40,000 now exceeds 30,000 spendable
      expect(
        controller.state.validationError,
        equals('Amount exceeds available balance.'),
      );
      expect(controller.state.canContinue, isFalse);
    });

    test('updateOffline updates isOffline flag', () {
      expect(controller.state.isOffline, isFalse);

      controller.updateOffline(true);
      expect(controller.state.isOffline, isTrue);

      controller.updateOffline(false);
      expect(controller.state.isOffline, isFalse);
    });

    test('validate sets greater-than-zero error on empty input', () {
      controller.validate();

      expect(
        controller.state.validationError,
        equals('Amount must be greater than zero.'),
      );
      expect(controller.state.canContinue, isFalse);
    });
  });
}
