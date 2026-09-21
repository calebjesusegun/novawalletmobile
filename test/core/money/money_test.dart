import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';

void main() {
  group('Money Construction & Invariants', () {
    test('creates Money directly from integer kobo', () {
      const money = Money.fromKobo(12545000);
      expect(money.kobo, 12545000);
      expect(money.naira, 125450);
      expect(money.koboRemainder, 0);
    });

    test('creates Money with zero constant', () {
      const money = Money.zero();
      expect(money.kobo, 0);
      expect(money.isZero, isTrue);
      expect(money.isPositive, isFalse);
      expect(money.isNegative, isFalse);
      expect(money.isNonNegative, isTrue);
    });

    test('creates Money from Naira and kobo', () {
      final money = Money.fromNaira(125450, 50);
      expect(money.kobo, 12545050);
      expect(money.naira, 125450);
      expect(money.koboRemainder, 50);
    });

    test('creates Money from negative Naira and kobo', () {
      final money = Money.fromNaira(-100, 25);
      expect(money.kobo, -10025);
      expect(money.naira, -100);
      expect(money.koboRemainder, 25);
    });

    test('throws ArgumentError if kobo component is out of 0..99 range in fromNaira', () {
      expect(() => Money.fromNaira(100, -1), throwsArgumentError);
      expect(() => Money.fromNaira(100, 100), throwsArgumentError);
    });
  });

  group('Money Acceptance Criteria (T-MNY-001)', () {
    test(
      'Given 12545000 kobo, when formatted, then the result is ₦125,450.00',
      () {
        const money = Money.fromKobo(12545000);
        expect(money.format(), '₦125,450.00');
        expect(money.toString(), '₦125,450.00');
      },
    );

    test(
      'Given 1000000 kobo, when formatted, then the result is ₦10,000.00',
      () {
        const money = Money.fromKobo(1000000);
        expect(money.format(), '₦10,000.00');
        expect(money.toString(), '₦10,000.00');
      },
    );

    test('formats zero kobo as ₦0.00', () {
      const money = Money.zero();
      expect(money.format(), '₦0.00');
    });

    test('formats negative amounts with leading minus sign', () {
      const money = Money.fromKobo(-12545000);
      expect(money.format(), '-₦125,450.00');
    });

    test('formats without currency symbol when requested', () {
      const money = Money.fromKobo(12545000);
      expect(money.format(includeSymbol: false), '125,450.00');

      const negative = Money.fromKobo(-12545000);
      expect(negative.format(includeSymbol: false), '-125,450.00');
    });

    test('formatCompact and format without kobo remainder when requested', () {
      const money = Money.fromKobo(12545000);
      expect(money.format(includeKobo: false), '₦125,450');
      expect(money.formatCompact(), '₦125,450');

      // Financial safety: non-zero fractional kobo is never silently dropped
      const withRemainder = Money.fromKobo(12545075);
      expect(withRemainder.format(includeKobo: false), '₦125,450.75');
      expect(withRemainder.formatCompact(), '₦125,450.75');
    });

    test('formats fractional kobo with leading zero padding', () {
      const singleDigitKobo = Money.fromKobo(5);
      expect(singleDigitKobo.format(), '₦0.05');

      const fiftyKobo = Money.fromKobo(50);
      expect(fiftyKobo.format(), '₦0.50');
    });

    test('formats large amounts with multiple commas', () {
      const oneBillionNaira = Money.fromKobo(100000000000);
      expect(oneBillionNaira.format(), '₦1,000,000,000.00');
    });
  });

  group('Money Arithmetic & Exactness', () {
    test('exact integer addition', () {
      const a = Money.fromKobo(10050); // ₦100.50
      const b = Money.fromKobo(20075); // ₦200.75
      final result = a + b;
      expect(result, const Money.fromKobo(30125));
      expect(result.format(), '₦301.25');
    });

    test('exact integer subtraction', () {
      const a = Money.fromKobo(50000); // ₦500.00
      const b = Money.fromKobo(15025); // ₦150.25
      final result = a - b;
      expect(result, const Money.fromKobo(34975));
      expect(result.format(), '₦349.75');
    });

    test('subtraction leading to negative amount', () {
      const a = Money.fromKobo(10000);
      const b = Money.fromKobo(25000);
      final result = a - b;
      expect(result, const Money.fromKobo(-15000));
      expect(result.isNegative, isTrue);
      expect(result.format(), '-₦150.00');
    });

    test('unary negation', () {
      const a = Money.fromKobo(10000);
      final negated = -a;
      expect(-a, const Money.fromKobo(-10000));
      expect(-negated, a);
    });

    test('multiplication by integer factor', () {
      const a = Money.fromKobo(1500); // ₦15.00
      final result = a * 3;
      expect(result, const Money.fromKobo(4500));
    });

    test('truncating integer division', () {
      const a = Money.fromKobo(10000); // ₦100.00
      final result = a ~/ 3;
      expect(result, const Money.fromKobo(3333));
    });

    test('division by zero throws UnsupportedError', () {
      const a = Money.fromKobo(10000);
      expect(() => a ~/ 0, throwsA(isA<UnsupportedError>()));
    });

    test('absolute value', () {
      const negative = Money.fromKobo(-5000);
      expect(negative.abs(), const Money.fromKobo(5000));

      const positive = Money.fromKobo(5000);
      expect(positive.abs(), const Money.fromKobo(5000));
    });

    test('guarantees no floating-point precision loss (e.g. 0.1 + 0.2)', () {
      const tenKobo = Money.fromKobo(10);
      const twentyKobo = Money.fromKobo(20);
      final sum = tenKobo + twentyKobo;
      expect(sum.kobo, 30);
      expect(sum.format(), '₦0.30');
    });
  });

  group('Money Comparison & Ordering', () {
    const smaller = Money.fromKobo(5000);
    const larger = Money.fromKobo(10000);
    const equalToSmaller = Money.fromKobo(5000);

    test('relational operators', () {
      expect(smaller < larger, isTrue);
      expect(smaller <= larger, isTrue);
      expect(smaller <= equalToSmaller, isTrue);
      expect(larger > smaller, isTrue);
      expect(larger >= smaller, isTrue);
      expect(smaller >= equalToSmaller, isTrue);
      expect(smaller > larger, isFalse);
      expect(larger < smaller, isFalse);
    });

    test('compareTo implementation', () {
      expect(smaller.compareTo(larger), lessThan(0));
      expect(larger.compareTo(smaller), greaterThan(0));
      expect(smaller.compareTo(equalToSmaller), 0);
    });

    test('sorting a list of Money values', () {
      final list = [
        const Money.fromKobo(2000),
        const Money.fromKobo(500),
        const Money.fromKobo(5000),
        const Money.fromKobo(0),
      ]..sort();

      expect(list, [
        const Money.fromKobo(0),
        const Money.fromKobo(500),
        const Money.fromKobo(2000),
        const Money.fromKobo(5000),
      ]);
    });

    test('value equality and hashCode', () {
      const a = Money.fromKobo(12345);
      const b = Money.fromKobo(12345);
      const c = Money.fromKobo(54321);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('Money Zero & Negative Validations', () {
    test('isZero, isPositive, isNegative, isNonNegative properties', () {
      const positive = Money.fromKobo(100);
      const zero = Money.fromKobo(0);
      const negative = Money.fromKobo(-100);

      expect(positive.isPositive, isTrue);
      expect(positive.isZero, isFalse);
      expect(positive.isNegative, isFalse);
      expect(positive.isNonNegative, isTrue);

      expect(zero.isPositive, isFalse);
      expect(zero.isZero, isTrue);
      expect(zero.isNegative, isFalse);
      expect(zero.isNonNegative, isTrue);

      expect(negative.isPositive, isFalse);
      expect(negative.isZero, isFalse);
      expect(negative.isNegative, isTrue);
      expect(negative.isNonNegative, isFalse);
    });

    test('ensureNonNegative passes for zero and positive amounts', () {
      expect(() => const Money.zero().ensureNonNegative(), returnsNormally);
      expect(
        () => const Money.fromKobo(1000).ensureNonNegative(),
        returnsNormally,
      );
    });

    test(
      'ensureNonNegative throws MoneyValidationException for negative amounts',
      () {
        expect(
          () => const Money.fromKobo(-1).ensureNonNegative(),
          throwsA(isA<MoneyValidationException>()),
        );
      },
    );

    test('ensurePositive passes for strictly positive amounts', () {
      expect(() => const Money.fromKobo(1).ensurePositive(), returnsNormally);
    });

    test('ensurePositive throws MoneyValidationException for zero and negative amounts', () {
      expect(
        () => const Money.zero().ensurePositive(),
        throwsA(isA<MoneyValidationException>()),
      );
      expect(
        () => const Money.fromKobo(-500).ensurePositive(),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('checkNonNegative and checkPositive return this when valid', () {
      const valid = Money.fromKobo(500);
      expect(valid.checkNonNegative(), equals(valid));
      expect(valid.checkPositive(), equals(valid));
    });

    test('checkNonNegative and checkPositive throw when invalid', () {
      const negative = Money.fromKobo(-500);
      expect(
        () => negative.checkNonNegative(),
        throwsA(isA<MoneyValidationException>()),
      );

      const zero = Money.zero();
      expect(
        () => zero.checkPositive(),
        throwsA(isA<MoneyValidationException>()),
      );
    });
  });

  group('Money Parsing', () {
    test('parses plain integer and decimal strings', () {
      expect(Money.parse('10000'), const Money.fromKobo(1000000));
      expect(Money.parse('125450.00'), const Money.fromKobo(12545000));
      expect(Money.parse('10.5'), const Money.fromKobo(1050));
      expect(Money.parse('10.05'), const Money.fromKobo(1005));
      expect(Money.parse('0'), const Money.zero());
      expect(Money.parse('.50'), const Money.fromKobo(50));
    });

    test('parses strings formatted with commas and currency symbols', () {
      expect(Money.parse('₦125,450.00'), const Money.fromKobo(12545000));
      expect(Money.parse('NGN 10,000.00'), const Money.fromKobo(1000000));
      expect(Money.parse(' ₦ 10,000 '), const Money.fromKobo(1000000));
    });

    test('parses negative strings', () {
      expect(Money.parse('-₦125,450.00'), const Money.fromKobo(-12545000));
      expect(Money.parse('₦-125,450.00'), const Money.fromKobo(-12545000));
      expect(Money.parse('-50.25'), const Money.fromKobo(-5025));
    });

    test(
      'tryParse returns null on invalid formats and strict grammar violations',
      () {
        expect(Money.tryParse(''), isNull);
        expect(Money.tryParse('   '), isNull);
        expect(Money.tryParse('abc'), isNull);
        expect(Money.tryParse('10.123'), isNull); // More than 2 decimal places
        expect(Money.tryParse('10.0.0'), isNull);
        expect(Money.tryParse('₦'), isNull);
        expect(Money.tryParse('-'), isNull);
        expect(Money.tryParse('.'), isNull); // Solitary dot with no digits
        expect(Money.tryParse('50.'), isNull); // Trailing dot without fraction
        expect(Money.tryParse('007'), isNull); // Leading zero on whole number
        expect(Money.tryParse('0,001'), isNull); // Leading zero with comma
        expect(Money.tryParse('01'), isNull); // Leading zero
        expect(Money.tryParse('ngn 100'), isNull); // Lowercase ngn rejected
        expect(Money.tryParse('1,2,3'), isNull); // Malformed comma grouping
        expect(Money.tryParse('1 0'), isNull); // Internal space between digits
        expect(Money.tryParse('1,00'), isNull); // Invalid thousands grouping
        expect(Money.tryParse(',100'), isNull); // Leading comma
        expect(Money.tryParse('100,'), isNull); // Trailing comma
        expect(Money.tryParse('10,000.0,0'), isNull); // Comma in fraction
        expect(Money.tryParse('1' * 41), isNull); // Exceeds 40 characters
      },
    );

    test('parse throws MoneyParseException on invalid format', () {
      expect(() => Money.parse('invalid'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('12.345'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('.'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('50.'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('007'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('0,001'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('ngn 100'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('1,2,3'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('1 0'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('1,00'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse(',100'), throwsA(isA<MoneyParseException>()));
      expect(() => Money.parse('100,'), throwsA(isA<MoneyParseException>()));
      expect(
        () => Money.parse('10,000.0,0'),
        throwsA(isA<MoneyParseException>()),
      );
      expect(() => Money.parse('1' * 41), throwsA(isA<MoneyParseException>()));
    });
  });

  group('Boundary & 64-Bit Overflow Protection', () {
    const maxMoney = Money.fromKobo(Money.maxKobo);
    const minMoney = Money.fromKobo(Money.minKobo);

    test('represents and formats exact 64-bit bounds', () {
      expect(maxMoney.kobo, 9223372036854775807);
      expect(minMoney.kobo, -9223372036854775808);

      expect(maxMoney.format(), '₦92,233,720,368,547,758.07');
      expect(minMoney.format(), '-₦92,233,720,368,547,758.08');

      expect(maxMoney.koboRemainder, 7);
      expect(minMoney.koboRemainder, 8);
    });

    test('addition overflow throws MoneyOverflowException', () {
      expect(
        () => maxMoney + const Money.fromKobo(1),
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test('subtraction underflow throws MoneyOverflowException', () {
      expect(
        () => minMoney - const Money.fromKobo(1),
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test(
      'negation of minKobo throws MoneyOverflowException (does not roll over)',
      () {
        expect(() => -minMoney, throwsA(isA<MoneyOverflowException>()));
      },
    );

    test('abs() of minKobo throws MoneyOverflowException', () {
      expect(() => minMoney.abs(), throwsA(isA<MoneyOverflowException>()));
    });

    test('minKobo divided by -1 throws MoneyOverflowException', () {
      expect(() => minMoney ~/ -1, throwsA(isA<MoneyOverflowException>()));
    });

    test('multiplication overflow throws MoneyOverflowException', () {
      expect(() => maxMoney * 2, throwsA(isA<MoneyOverflowException>()));
      expect(() => minMoney * 2, throwsA(isA<MoneyOverflowException>()));
      expect(
        () => const Money.fromKobo(5000000000000000000) * 3,
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test('fromNaira handles boundary values and throws on overflow', () {
      // 92233720368547758 Naira + 7 kobo = maxKobo
      final atMax = Money.fromNaira(92233720368547758, 7);
      expect(atMax, maxMoney);

      // 1 kobo beyond max
      expect(
        () => Money.fromNaira(92233720368547758, 8),
        throwsA(isA<MoneyOverflowException>()),
      );
      expect(
        () => Money.fromNaira(92233720368547759, 0),
        throwsA(isA<MoneyOverflowException>()),
      );

      // -92233720368547758 Naira - 8 kobo = minKobo
      final atMin = Money.fromNaira(-92233720368547758, 8);
      expect(atMin, minMoney);

      // 1 kobo below min
      expect(
        () => Money.fromNaira(-92233720368547758, 9),
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test('parsing handles boundary amounts and rejects oversized inputs', () {
      expect(Money.parse('92233720368547758.07'), maxMoney);
      expect(Money.parse('-92233720368547758.08'), minMoney);

      expect(
        () => Money.parse('92233720368547758.08'),
        throwsA(isA<MoneyOverflowException>()),
      );
      expect(
        () => Money.parse('999999999999999999999999999'),
        throwsA(isA<MoneyOverflowException>()),
      );

      expect(Money.tryParse('92233720368547758.08'), isNull);
      expect(Money.tryParse('999999999999999999999999999'), isNull);
    });
  });
}
