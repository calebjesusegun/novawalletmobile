import 'package:flutter/foundation.dart';

/// Exception thrown when validating [Money] constraints.
class MoneyValidationException implements Exception {
  const MoneyValidationException(this.message);

  final String message;

  @override
  String toString() => 'MoneyValidationException: $message';
}

/// Exception thrown when parsing a string representation of [Money].
class MoneyParseException implements Exception {
  const MoneyParseException(this.message, [this.source]);

  final String message;
  final String? source;

  @override
  String toString() =>
      'MoneyParseException: $message${source != null ? ' (source: "$source")' : ''}';
}

/// Exception thrown when a monetary operation overflows or underflows
/// signed 64-bit integer limits.
class MoneyOverflowException implements Exception {
  const MoneyOverflowException([
    this.message = 'Money amount exceeds signed 64-bit integer limits.',
  ]);

  final String message;

  @override
  String toString() => 'MoneyOverflowException: $message';
}

/// Immutable value object representing a monetary amount in integer kobo.
///
/// Under constraint HC-MONEY, all financial amounts in domain and data logic
/// MUST use integer kobo. Floating-point types (`double`) are never used
/// for monetary calculations or authoritative storage.
///
/// Arithmetic operations are strictly checked against signed 64-bit limits
/// (`[-9223372036854775808, 9223372036854775807]`), matching SQLite's
/// 64-bit integer storage bounds and preventing silent numeric overflow.
@immutable
class Money implements Comparable<Money> {
  /// Creates a [Money] value object from an integer number of [kobo].
  const Money.fromKobo(this.kobo);

  /// Zero money constant.
  const Money.zero() : kobo = 0;

  static final BigInt _minKobo = BigInt.parse('-9223372036854775808');
  static final BigInt _maxKobo = BigInt.parse('9223372036854775807');
  static final BigInt _hundred = BigInt.from(100);
  static final RegExp _thousandsRegex = RegExp(r'^\d{1,3}(,\d{3})+$');
  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');

  /// Minimum representable amount in kobo (-2^63).
  static const int minKobo = -9223372036854775808;

  /// Maximum representable amount in kobo (2^63 - 1).
  static const int maxKobo = 9223372036854775807;

  /// Currency symbol for Nigerian Naira.
  static const String currencySymbol = '₦';

  /// ISO currency code for Nigerian Naira.
  static const String currencyCode = 'NGN';

  /// The amount represented in integer kobo.
  final int kobo;

  /// Helper to validate intermediate arbitrary-precision calculations
  /// before converting back to signed 64-bit integer kobo.
  static Money _checked(BigInt value) {
    if (value < _minKobo || value > _maxKobo) {
      throw const MoneyOverflowException();
    }
    return Money.fromKobo(value.toInt());
  }

  /// Creates a [Money] value object from integer [naira] and optional integer [kobo].
  ///
  /// The [kobo] argument must be between 0 and 99 inclusive.
  /// Throws [ArgumentError] if [kobo] is out of range.
  /// Throws [MoneyOverflowException] if the resulting amount exceeds 64-bit bounds.
  factory Money.fromNaira(int naira, [int kobo = 0]) {
    if (kobo < 0 || kobo >= 100) {
      throw ArgumentError.value(
        kobo,
        'kobo',
        'Kobo remainder must be between 0 and 99 inclusive.',
      );
    }
    final whole = BigInt.from(naira) * _hundred;
    final fraction = BigInt.from(kobo);
    return _checked(naira < 0 ? whole - fraction : whole + fraction);
  }

  /// Parses a string representation of an amount into a [Money] instance.
  ///
  /// Accepts strings such as `'125450.00'`, `'₦125,450.00'`, `'10000'`,
  /// `'10,000.5'`, `'-₦125,450.00'`, or `'-500'`.
  ///
  /// Throws [MoneyParseException] if [input] is malformed.
  /// Throws [MoneyOverflowException] if the parsed amount exceeds 64-bit bounds.
  factory Money.parse(String input) {
    final result = _parseInternal(input);
    if (result.isMalformed) {
      throw MoneyParseException('Invalid monetary format: "$input"', input);
    }
    return _checked(result.value!);
  }

  /// Attempts to parse a string representation of an amount into a [Money] instance.
  ///
  /// Returns `null` if [input] is malformed or exceeds 64-bit bounds.
  static Money? tryParse(String input) {
    final result = _parseInternal(input);
    if (result.isMalformed) {
      return null;
    }
    final value = result.value!;
    if (value < _minKobo || value > _maxKobo) {
      return null;
    }
    return Money.fromKobo(value.toInt());
  }

  static _ParseResult _parseInternal(String input) {
    var cleaned = input.trim();
    if (cleaned.isEmpty) {
      return const _ParseResult.malformed();
    }

    var isNegative = false;
    if (cleaned.startsWith('-')) {
      isNegative = true;
      cleaned = cleaned.substring(1).trim();
    }

    // Strip currency symbols and whitespace between symbol and amount
    if (cleaned.startsWith('₦') || cleaned.startsWith('\u20A6')) {
      cleaned = cleaned.substring(1).trim();
    } else if (cleaned.toUpperCase().startsWith('NGN')) {
      cleaned = cleaned.substring(3).trim();
    }

    // Check again for negative sign if it followed the symbol, e.g. "₦-100"
    if (!isNegative && cleaned.startsWith('-')) {
      isNegative = true;
      cleaned = cleaned.substring(1).trim();
    }

    // Reject if empty or if there are internal spaces (e.g. "1 0")
    if (cleaned.isEmpty || cleaned.contains(' ')) {
      return const _ParseResult.malformed();
    }

    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return const _ParseResult.malformed();
    }

    final wholeStr = parts[0];
    final fracStr = parts.length == 2 ? parts[1] : null;

    // Both whole and fractional cannot be empty (e.g. ".")
    if (wholeStr.isEmpty && (fracStr == null || fracStr.isEmpty)) {
      return const _ParseResult.malformed();
    }

    BigInt wholePart;
    if (wholeStr.isEmpty) {
      wholePart = BigInt.zero;
    } else {
      // If wholeStr contains commas, it MUST follow valid thousands grouping: e.g. "1,000", "125,450"
      if (wholeStr.contains(',')) {
        if (!_thousandsRegex.hasMatch(wholeStr)) {
          return const _ParseResult.malformed();
        }
      } else {
        if (!_digitsOnlyRegex.hasMatch(wholeStr)) {
          return const _ParseResult.malformed();
        }
      }

      final normalizedWhole = wholeStr.replaceAll(',', '');
      final parsedWhole = BigInt.tryParse(normalizedWhole);
      if (parsedWhole == null) {
        return const _ParseResult.malformed();
      }
      wholePart = parsedWhole;
    }

    var koboPart = 0;
    if (fracStr != null && fracStr.isNotEmpty) {
      // Fractional part must be digits only and cannot contain commas
      if (!_digitsOnlyRegex.hasMatch(fracStr)) {
        return const _ParseResult.malformed();
      }
      if (fracStr.length == 1) {
        koboPart = int.parse(fracStr) * 10;
      } else if (fracStr.length == 2) {
        koboPart = int.parse(fracStr);
      } else {
        // More than 2 decimal places cannot be represented exactly in kobo
        return const _ParseResult.malformed();
      }
    }

    final totalKobo = (wholePart * _hundred) + BigInt.from(koboPart);
    return _ParseResult.success(isNegative ? -totalKobo : totalKobo);
  }

  /// Returns the whole Naira portion (signed integer division).
  int get naira => kobo ~/ 100;

  /// Returns the fractional kobo portion (0 to 99).
  int get koboRemainder => (BigInt.from(kobo).abs() % _hundred).toInt();

  /// Whether this amount is exactly zero.
  bool get isZero => kobo == 0;

  /// Whether this amount is strictly greater than zero.
  bool get isPositive => kobo > 0;

  /// Whether this amount is strictly less than zero.
  bool get isNegative => kobo < 0;

  /// Whether this amount is greater than or equal to zero.
  bool get isNonNegative => kobo >= 0;

  /// Returns the absolute value of this amount.
  /// Throws [MoneyOverflowException] if `kobo == minKobo` (-2^63).
  Money abs() => isNegative ? -this : this;

  /// Validates that this amount is greater than or equal to zero.
  /// Throws [MoneyValidationException] if negative.
  void ensureNonNegative([String message = 'Amount cannot be negative']) {
    if (isNegative) {
      throw MoneyValidationException(message);
    }
  }

  /// Validates that this amount is strictly greater than zero.
  /// Throws [MoneyValidationException] if zero or negative.
  void ensurePositive([String message = 'Amount must be greater than zero']) {
    if (!isPositive) {
      throw MoneyValidationException(message);
    }
  }

  /// Returns `this` if non-negative, otherwise throws [MoneyValidationException].
  Money checkNonNegative([String message = 'Amount cannot be negative']) {
    ensureNonNegative(message);
    return this;
  }

  /// Returns `this` if strictly positive, otherwise throws [MoneyValidationException].
  Money checkPositive([String message = 'Amount must be greater than zero']) {
    ensurePositive(message);
    return this;
  }

  /// Adds [other] to this amount with overflow protection.
  Money operator +(Money other) =>
      _checked(BigInt.from(kobo) + BigInt.from(other.kobo));

  /// Subtracts [other] from this amount with overflow protection.
  Money operator -(Money other) =>
      _checked(BigInt.from(kobo) - BigInt.from(other.kobo));

  /// Negates this amount with overflow protection.
  /// Throws [MoneyOverflowException] if `kobo == minKobo` (-2^63).
  Money operator -() => _checked(-BigInt.from(kobo));

  /// Multiplies this amount by an integer [factor] with overflow protection.
  Money operator *(int factor) =>
      _checked(BigInt.from(kobo) * BigInt.from(factor));

  /// Performs integer division of this amount by an integer [divisor]
  /// with zero-division and overflow protection (`minKobo ~/ -1`).
  Money operator ~/(int divisor) {
    if (divisor == 0) {
      throw UnsupportedError('Integer division by zero.');
    }
    return _checked(BigInt.from(kobo) ~/ BigInt.from(divisor));
  }

  /// Relational comparison operators.
  bool operator <(Money other) => kobo < other.kobo;
  bool operator <=(Money other) => kobo <= other.kobo;
  bool operator >(Money other) => kobo > other.kobo;
  bool operator >=(Money other) => kobo >= other.kobo;

  @override
  int compareTo(Money other) => kobo.compareTo(other.kobo);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.kobo == kobo);

  @override
  int get hashCode => kobo.hashCode;

  /// Formats this money value into a standardized Naira string.
  ///
  /// Examples:
  /// - `Money.fromKobo(12545000).format()` -> `'₦125,450.00'`
  /// - `Money.fromKobo(1000000).format()` -> `'₦10,000.00'`
  /// - `Money.fromKobo(0).format()` -> `'₦0.00'`
  /// - `Money.fromKobo(-12545000).format()` -> `'-₦125,450.00'`
  /// - `Money.fromKobo(1000000).format(includeSymbol: false)` -> `'10,000.00'`
  /// - `Money.fromKobo(1000000).format(includeKobo: false)` -> `'₦10,000'`
  String format({bool includeSymbol = true, bool includeKobo = true}) {
    final isNeg = kobo < 0;
    final bigKobo = BigInt.from(kobo).abs();
    final nairaStr = (bigKobo ~/ _hundred).toString();
    final koboValue = (bigKobo % _hundred).toInt();

    final formattedNaira = _formatThousands(nairaStr);
    final buffer = StringBuffer();

    if (isNeg) {
      buffer.write('-');
    }
    if (includeSymbol) {
      buffer.write(currencySymbol);
    }
    buffer.write(formattedNaira);

    if (includeKobo) {
      buffer.write('.');
      buffer.write(koboValue.toString().padLeft(2, '0'));
    }

    return buffer.toString();
  }

  /// Helper to format an integer string with comma thousands separators.
  static String _formatThousands(String digits) {
    final len = digits.length;
    if (len <= 3) {
      return digits;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  String toString() => format();
}

class _ParseResult {
  const _ParseResult.malformed() : isMalformed = true, value = null;

  const _ParseResult.success(this.value) : isMalformed = false;

  final bool isMalformed;
  final BigInt? value;
}
