import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_progress.dart';

void main() {
  group('SavingsProgress Acceptance Criteria (T-MNY-002)', () {
    test('Given ₦150,000 saved toward ₦500,000, progress resolves to 30% '
        'and remaining amount is exact ₦350,000', () {
      final target = Money.fromNaira(500000);
      final saved = Money.fromNaira(150000);

      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: saved,
      );

      // Acceptance: progress resolves to 30%
      expect(progress.percentage, 30);
      expect(progress.basisPoints, 3000);
      expect(progress.formatPercentage(), '30%');

      // Acceptance: Remaining amount calculation is exact integer kobo
      // ₦500,000 - ₦150,000 = ₦350,000 remaining
      expect(progress.remainingAmount, Money.fromNaira(350000));
      expect(progress.remainingAmount.kobo, 35000000);
      expect(progress.remainingAmount.format(), '₦350,000.00');

      // Flags
      expect(progress.isGoalReached, isFalse);
      expect(progress.isOverTarget, isFalse);
      expect(progress.excessAmount, const Money.zero());
    });

    test(
      'Given a successful ₦50,000 contribution, projected/confirmed progress '
      'resolves to 40% and remaining amount is ₦300,000',
      () {
        final target = Money.fromNaira(500000);
        final initialSaved = Money.fromNaira(150000);
        final initialProgress = SavingsProgress(
          targetAmount: target,
          savedAmount: initialSaved,
        );

        final contribution = Money.fromNaira(50000);

        // Projected contribution
        final projected = initialProgress.projectContribution(contribution);

        // Acceptance: resolves to 40%
        expect(projected.percentage, 40);
        expect(projected.basisPoints, 4000);
        expect(projected.formatPercentage(), '40%');

        // Saved amount updated
        expect(projected.savedAmount, Money.fromNaira(200000));
        expect(projected.savedAmount.kobo, 20000000);

        // Remaining amount is exact ₦300,000
        expect(projected.remainingAmount, Money.fromNaira(300000));
        expect(projected.remainingAmount.kobo, 30000000);
        expect(projected.remainingAmount.format(), '₦300,000.00');

        // withContribution alias produces identical result
        expect(initialProgress.withContribution(contribution), projected);
      },
    );

    test(
      'Progress calculation does not use floating-point money arithmetic',
      () {
        // 0.1 + 0.2 in double equals 0.30000000000000004
        // In exact integer kobo, calculations are perfectly exact
        const target = Money.fromKobo(10000000); // ₦100,000.00
        const step1 = Money.fromKobo(1000000); // ₦10,000.00 (10%)
        const step2 = Money.fromKobo(2000000); // ₦20,000.00 (20%)

        final progress = SavingsProgress(
          targetAmount: target,
          savedAmount: step1 + step2,
        );

        expect(progress.savedAmount.kobo, 3000000);
        expect(progress.basisPoints, 3000);
        expect(progress.percentage, 30);
        expect(progress.remainingAmount.kobo, 7000000);
        expect(progress.remainingAmount, const Money.fromKobo(7000000));
      },
    );
  });

  group('SavingsProgress Edge Cases & Invariants', () {
    test('rejects zero target amount with ArgumentError', () {
      expect(
        () => SavingsProgress(
          targetAmount: const Money.zero(),
          savedAmount: const Money.zero(),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Target amount must be strictly greater than zero'),
          ),
        ),
      );
    });

    test('rejects negative target amount with ArgumentError', () {
      expect(
        () => SavingsProgress(
          targetAmount: Money.fromNaira(-50000),
          savedAmount: const Money.zero(),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Target amount must be strictly greater than zero'),
          ),
        ),
      );
    });

    test('rejects negative saved amount with ArgumentError', () {
      expect(
        () => SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(-1000),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Saved amount cannot be negative'),
          ),
        ),
      );
    });

    test('rejects negative contribution attempt with ArgumentError', () {
      final progress = SavingsProgress(
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
      );

      expect(
        () => progress.projectContribution(Money.fromNaira(-5000)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Contribution amount cannot be negative'),
          ),
        ),
      );

      expect(
        () => progress.withContribution(Money.fromNaira(-5000)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('zero contribution leaves progress unchanged', () {
      final progress = SavingsProgress(
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
      );

      final result = progress.projectContribution(const Money.zero());
      expect(result.savedAmount, progress.savedAmount);
      expect(result.targetAmount, progress.targetAmount);
      expect(result.percentage, progress.percentage);
      expect(result.remainingAmount, progress.remainingAmount);
    });

    test('zero saved amount produces 0% and full remaining target', () {
      final target = Money.fromNaira(250000);
      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: const Money.zero(),
      );

      expect(progress.percentage, 0);
      expect(progress.basisPoints, 0);
      expect(progress.uncappedBasisPoints, BigInt.zero);
      expect(progress.remainingAmount, target);
      expect(progress.excessAmount, const Money.zero());
      expect(progress.isGoalReached, isFalse);
      expect(progress.isOverTarget, isFalse);
      expect(progress.toProgressFraction(), 0.0);
    });

    test('saved amount exactly equal to target resolves to 100%', () {
      final target = Money.fromNaira(500000);
      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: target,
      );

      expect(progress.percentage, 100);
      expect(progress.basisPoints, 10000);
      expect(progress.uncappedBasisPoints, BigInt.from(10000));
      expect(progress.remainingAmount, const Money.zero());
      expect(progress.excessAmount, const Money.zero());
      expect(progress.isGoalReached, isTrue);
      expect(progress.isOverTarget, isFalse);
      expect(progress.toProgressFraction(), 1.0);
      expect(progress.formatPercentage(), '100%');
    });

    test('saved amount exceeding target caps progress at 100% and flags over-achievement', () {
      final target = Money.fromNaira(500000);
      final saved = Money.fromNaira(600000); // 120% of target

      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: saved,
      );

      // Capped progress strictly at 100% / 10,000 bps
      expect(progress.percentage, 100);
      expect(progress.basisPoints, 10000);
      expect(progress.formatPercentage(), '100%');
      expect(progress.toProgressFraction(), 1.0);

      // Uncapped arbitrary-precision basis points
      expect(progress.uncappedBasisPoints, BigInt.from(12000));

      // Remaining amount is 0 kobo, never negative
      expect(progress.remainingAmount, const Money.zero());
      expect(progress.remainingAmount.kobo, 0);

      // Excess amount is exactly ₦100,000
      expect(progress.excessAmount, Money.fromNaira(100000));
      expect(progress.excessAmount.kobo, 10000000);

      // Flags
      expect(progress.isGoalReached, isTrue);
      expect(progress.isOverTarget, isTrue);
    });

    test('contributing to exceed target transitions smoothly to 100% and over-target', () {
      final progress = SavingsProgress(
        targetAmount: Money.fromNaira(100000),
        savedAmount: Money.fromNaira(90000),
      );

      expect(progress.percentage, 90);
      expect(progress.remainingAmount, Money.fromNaira(10000));
      expect(progress.isGoalReached, isFalse);

      final updated = progress.projectContribution(Money.fromNaira(25000));
      expect(updated.savedAmount, Money.fromNaira(115000));
      expect(updated.percentage, 100);
      expect(updated.uncappedBasisPoints, BigInt.from(11500));
      expect(updated.remainingAmount, const Money.zero());
      expect(updated.excessAmount, Money.fromNaira(15000));
      expect(updated.isGoalReached, isTrue);
      expect(updated.isOverTarget, isTrue);
    });
  });

  group('SavingsProgress Basis Points & Rational Calculations', () {
    test('calculates exact basis points for 1/3 progress (33.33%)', () {
      final progress = SavingsProgress(
        targetAmount: const Money.fromKobo(300),
        savedAmount: const Money.fromKobo(100),
      );

      // 100 * 10000 ~/ 300 = 3333 bps
      expect(progress.basisPoints, 3333);
      expect(progress.percentage, 33);
      expect(progress.roundedPercentage, 33);
      expect(progress.formatPercentage(decimalPlaces: 2), '33.33%');
      expect(progress.formatPercentage(decimalPlaces: 1), '33.3%');
    });

    test('calculates exact basis points for 2/3 progress (66.66%)', () {
      final progress = SavingsProgress(
        targetAmount: const Money.fromKobo(300),
        savedAmount: const Money.fromKobo(200),
      );

      // 200 * 10000 ~/ 300 = 6666 bps
      expect(progress.basisPoints, 6666);
      expect(progress.percentage, 66);
      expect(progress.roundedPercentage, 67);
      expect(progress.formatPercentage(decimalPlaces: 2), '66.66%');
      expect(progress.formatPercentage(decimalPlaces: 1), '66.6%');
      expect(progress.formatPercentage(rounded: true), '67%');
    });

    test('never reports 100% or 100.0% before goal is actually reached', () {
      // 9,995 kobo saved toward 10,000 kobo (₦99.95 of ₦100.00, ₦0.05 remaining)
      final progress9995 = SavingsProgress(
        targetAmount: const Money.fromKobo(10000),
        savedAmount: const Money.fromKobo(9995),
      );

      expect(progress9995.isGoalReached, isFalse);
      expect(progress9995.remainingAmount, const Money.fromKobo(5));
      expect(progress9995.basisPoints, 9995);
      expect(progress9995.percentage, 99);
      expect(progress9995.roundedPercentage, 99); // Capped at 99%, never 100%
      expect(progress9995.formatPercentage(), '99%');
      expect(progress9995.formatPercentage(rounded: true), '99%');
      expect(
        progress9995.formatPercentage(decimalPlaces: 1),
        '99.9%',
      ); // Not 100.0%
      expect(progress9995.formatPercentage(decimalPlaces: 2), '99.95%');
      expect(progress9995.toProgressFraction(), 0.9995);

      // 9,950 kobo saved toward 10,000 kobo (₦99.50 of ₦100.00)
      final progress9950 = SavingsProgress(
        targetAmount: const Money.fromKobo(10000),
        savedAmount: const Money.fromKobo(9950),
      );

      expect(progress9950.isGoalReached, isFalse);
      expect(progress9950.basisPoints, 9950);
      expect(progress9950.roundedPercentage, 99);
      expect(progress9950.formatPercentage(), '99%');
      expect(progress9950.formatPercentage(rounded: true), '99%');
      expect(progress9950.formatPercentage(decimalPlaces: 1), '99.5%');
    });

    test('handles large monetary amounts without 64-bit integer overflow', () {
      // 50 billion Naira in kobo = 5,000,000,000,000 kobo (5 * 10^12)
      // When multiplied by 10,000, numerator is 5 * 10^16 (fits in BigInt easily)
      final target = Money.fromNaira(100000000000); // 100 billion Naira
      final saved = Money.fromNaira(30000000000); // 30 billion Naira

      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: saved,
      );

      expect(progress.percentage, 30);
      expect(progress.basisPoints, 3000);
      expect(progress.remainingAmount, Money.fromNaira(70000000000));
      expect(progress.toProgressFraction(), 0.3);
    });

    test('handles near-max 64-bit bounds without crashing', () {
      // Testing with large 64-bit kobo values
      const target = Money.fromKobo(100000000000000000);
      const saved = Money.fromKobo(40000000000000000);

      final progress = SavingsProgress(
        targetAmount: target,
        savedAmount: saved,
      );

      expect(progress.percentage, 40);
      expect(progress.basisPoints, 4000);
      expect(progress.remainingAmount, const Money.fromKobo(60000000000000000));
      expect(progress.toProgressFraction(), 0.4);
    });

    test(
      'handles extreme ratio (maxKobo / 1 kobo) without 64-bit int saturation',
      () {
        const target = Money.fromKobo(1);
        const saved = Money.fromKobo(Money.maxKobo);

        final progress = SavingsProgress(
          targetAmount: target,
          savedAmount: saved,
        );

        // Capped metrics must remain 100% and 10,000 bps without saturation or overflow
        expect(progress.percentage, 100);
        expect(progress.basisPoints, 10000);
        expect(progress.isGoalReached, isTrue);
        expect(progress.isOverTarget, isTrue);
        expect(progress.remainingAmount, const Money.zero());
        expect(progress.excessAmount, const Money.fromKobo(Money.maxKobo - 1));
        expect(progress.toProgressFraction(), 1.0);

        // Uncapped basis points preserves exact arbitrary-precision BigInt:
        // 9223372036854775807 * 10000 = 92233720368547758070000
        expect(
          progress.uncappedBasisPoints,
          BigInt.parse('92233720368547758070000'),
        );
      },
    );
  });

  group('SavingsProgress Presentation Formatting & UI Converter', () {
    test(
      'formatPercentage supports symbol, no-symbol, and decimal options',
      () {
        final progress = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(150000),
        );

        expect(progress.formatPercentage(), '30%');
        expect(progress.formatPercentage(includeSymbol: false), '30');
        expect(progress.formatPercentage(decimalPlaces: 1), '30.0%');
        expect(progress.formatPercentage(decimalPlaces: 2), '30.00%');
      },
    );

    test(
      'formatPercentage throws ArgumentError for unsupported decimal places',
      () {
        final progress = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(150000),
        );

        expect(
          () => progress.formatPercentage(decimalPlaces: -1),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => progress.formatPercentage(decimalPlaces: 3),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'toProgressFraction provides strictly clamped [0.0, 1.0] boundary values',
      () {
        final p0 = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: const Money.zero(),
        );
        final p30 = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(150000),
        );
        final p40 = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(200000),
        );
        final p100 = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(500000),
        );
        final p150 = SavingsProgress(
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(750000),
        );

        expect(p0.toProgressFraction(), 0.0);
        expect(p30.toProgressFraction(), 0.3);
        expect(p40.toProgressFraction(), 0.4);
        expect(p100.toProgressFraction(), 1.0);
        expect(p150.toProgressFraction(), 1.0); // strictly clamped to 1.0
      },
    );

    test('value equality, hashCode, and toString', () {
      final p1 = SavingsProgress(
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
      );
      final p2 = SavingsProgress(
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
      );
      final p3 = SavingsProgress(
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(200000),
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));

      final stringOutput = p1.toString();
      expect(stringOutput, contains('₦150,000.00'));
      expect(stringOutput, contains('₦500,000.00'));
      expect(stringOutput, contains('30%'));
      expect(stringOutput, contains('₦350,000.00'));
    });
  });
}
