import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/controllers/contribute_amount_controller.dart';

void main() {
  group('ContributeAmountController Unit Tests (NSV-009, NSV-010, MNY-003, MNY-006)', () {
    final sampleGoal = SavingsGoal(
      id: 'goal-emergency-fund',
      name: 'Emergency Fund',
      targetAmount: Money.fromNaira(500000),
      savedAmount: Money.fromNaira(150000),
      targetDate: DateTime(2026, 12, 30),
    );

    late ContributeAmountController controller;

    setUp(() {
      controller = ContributeAmountController(
        goal: sampleGoal,
        spendableBalance: Money.fromNaira(125450), // ₦125,450.00
        confirmedBalance: Money.fromNaira(125450),
        isOffline: false,
      );
    });

    test(
      'initial state has zero amount, null error, and disabled continue',
      () {
        expect(controller.state.goal, equals(sampleGoal));
        expect(controller.state.amount, equals(const Money.zero()));
        expect(controller.state.rawInput, isEmpty);
        expect(controller.state.validationError, isNull);
        expect(controller.state.canContinue, isFalse);
        expect(
          controller.state.projectedSavedAmount,
          equals(sampleGoal.savedAmount),
        );
        expect(controller.state.projectedPercentage, equals(30));
      },
    );

    test('entering empty string resets amount without validation error', () {
      controller.onAmountChanged('50000');
      expect(controller.state.amount, equals(Money.fromNaira(50000)));

      controller.onAmountChanged('');
      expect(controller.state.amount, equals(const Money.zero()));
      expect(controller.state.rawInput, isEmpty);
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isFalse);
    });

    test('entering valid ₦50,000 contribution calculates 40% projected progress (UI-NSV-09 / MNY-003)', () {
      controller.onAmountChanged('50000');

      expect(controller.state.amount, equals(Money.fromNaira(50000)));
      expect(controller.state.validationError, isNull);
      expect(controller.state.canContinue, isTrue);

      // ₦150,000 + ₦50,000 = ₦200,000 of ₦500,000 (40%)
      expect(
        controller.state.projectedSavedAmount,
        equals(Money.fromNaira(200000)),
      );
      expect(controller.state.projectedPercentage, equals(40));
      expect(
        controller.state.projectedProgress.toProgressFraction(),
        closeTo(0.40, 0.0001),
      );
    });

    test('entering amount exceeding spendable balance displays UI-NSV-10 error and disables continue (NSV-010 / MNY-006)', () {
      controller.onAmountChanged('200000'); // ₦200,000 > ₦125,450

      expect(controller.state.amount, equals(Money.fromNaira(200000)));
      expect(
        controller.state.validationError,
        equals(
          'Amount is more than your wallet balance. Enter ₦125,450.00 or less.',
        ),
      );
      expect(controller.state.canContinue, isFalse);
    });

    test('entering zero rejects with greater-than-zero error', () {
      controller.onAmountChanged('0');

      expect(controller.state.amount, equals(const Money.zero()));
      expect(
        controller.state.validationError,
        equals('Enter an amount greater than ₦0.00.'),
      );
      expect(controller.state.canContinue, isFalse);
    });

    test('entering non-numeric characters displays valid amount error', () {
      controller.onAmountChanged('invalid');

      expect(controller.state.amount, equals(const Money.zero()));
      expect(controller.state.validationError, equals('Enter a valid amount.'));
      expect(controller.state.canContinue, isFalse);
    });

    test('updateProjection re-evaluates existing input against new balance', () {
      controller.onAmountChanged('50000');
      expect(controller.state.canContinue, isTrue);

      // Spendable balance drops to ₦30,000 due to concurrent in-flight debit
      controller.updateProjection(
        spendableBalance: Money.fromNaira(30000),
        confirmedBalance: Money.fromNaira(125450),
      );

      expect(controller.state.canContinue, isFalse);
      expect(
        controller.state.validationError,
        equals(
          'Amount is more than your wallet balance. Enter ₦30,000.00 or less.',
        ),
      );
    });
  });
}
