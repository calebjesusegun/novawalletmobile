import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';

/// Immutable domain model representing savings progress toward a financial target.
///
/// Under constraint HC-MONEY:
/// - All internal domain and financial calculations are derived strictly from
///   integer kobo using the [Money] value object.
/// - Domain logic never uses `double` or floating-point arithmetic.
/// - Ratios and percentages are calculated using exact integer basis points
///   (1% = 100 basis points, 100% = 10,000 basis points) via [BigInt] to protect
///   against silent 64-bit integer multiplication overflow.
/// - For UI rendering (e.g. Flutter's [LinearProgressIndicator]), an explicit
///   boundary converter [toProgressFraction] is provided,
///   strictly isolating floating-point values to the presentation edge.
@immutable
class SavingsProgress {
  /// Creates a [SavingsProgress] calculation model.
  ///
  /// - [targetAmount] must be strictly greater than zero; otherwise throws [ArgumentError].
  /// - [savedAmount] cannot be negative; otherwise throws [ArgumentError].
  SavingsProgress({required this.targetAmount, required this.savedAmount}) {
    if (targetAmount.isZero || targetAmount.isNegative) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'Target amount must be strictly greater than zero.',
      );
    }
    if (savedAmount.isNegative) {
      throw ArgumentError.value(
        savedAmount,
        'savedAmount',
        'Saved amount cannot be negative.',
      );
    }
  }

  /// Factory constructor to calculate savings progress.
  factory SavingsProgress.calculate({
    required Money targetAmount,
    required Money savedAmount,
  }) = SavingsProgress;

  /// The target monetary amount for the savings goal.
  final Money targetAmount;

  /// The currently confirmed or projected saved amount.
  final Money savedAmount;

  static final BigInt _basisPointsMultiplier = BigInt.from(10000);
  static final BigInt _maxBasisPoints = BigInt.from(10000);

  /// Computes arbitrary-precision basis points without capping.
  BigInt get _rawBasisPoints {
    if (savedAmount.isZero) {
      return BigInt.zero;
    }
    final numerator = BigInt.from(savedAmount.kobo) * _basisPointsMultiplier;
    final denominator = BigInt.from(targetAmount.kobo);
    return numerator ~/ denominator;
  }

  /// Progress in basis points capped at 10,000 (100.00%).
  ///
  /// Comparison against 10,000 is performed in [BigInt] prior to converting
  /// to [int], preventing silent integer saturation when [savedAmount] is
  /// orders of magnitude greater than [targetAmount].
  int get basisPoints {
    final raw = _rawBasisPoints;
    return raw > _maxBasisPoints ? 10000 : raw.toInt();
  }

  /// Total basis points without capping, represented as [BigInt] to preserve
  /// exactness even when the ratio exceeds 64-bit integer limits.
  BigInt get uncappedBasisPoints => _rawBasisPoints;

  /// Integer percentage capped at 100% (e.g. 30 for 30%).
  int get percentage => basisPoints ~/ 100;

  /// Nearest-integer rounded percentage capped at 100%.
  int get roundedPercentage {
    final rounded = (basisPoints + 50) ~/ 100;
    return rounded > 100 ? 100 : rounded;
  }

  /// The remaining amount needed to reach the target.
  ///
  /// If [savedAmount] is greater than or equal to [targetAmount],
  /// returns [Money.zero] (₦0.00). It never returns a negative balance.
  Money get remainingAmount {
    if (savedAmount >= targetAmount) {
      return const Money.zero();
    }
    return targetAmount - savedAmount;
  }

  /// The amount saved beyond the target, or [Money.zero] if not exceeded.
  Money get excessAmount {
    if (savedAmount > targetAmount) {
      return savedAmount - targetAmount;
    }
    return const Money.zero();
  }

  /// Whether the saved amount has reached or exceeded the target.
  bool get isGoalReached => savedAmount >= targetAmount;

  /// Whether the saved amount strictly exceeds the target amount.
  bool get isOverTarget => savedAmount > targetAmount;

  /// Formats the progress percentage into a display string.
  ///
  /// Examples:
  /// - `formatPercentage()` -> `'30%'`
  /// - `formatPercentage(includeSymbol: false)` -> `'30'`
  /// - `formatPercentage(decimalPlaces: 2)` -> `'30.00%'`
  /// - `formatPercentage(decimalPlaces: 2)` (for 33.33%) -> `'33.33%'`
  ///
  /// This formatting is performed purely via integer arithmetic without `double`.
  String formatPercentage({
    bool includeSymbol = true,
    int decimalPlaces = 0,
    bool rounded = false,
  }) {
    if (decimalPlaces < 0 || decimalPlaces > 2) {
      throw ArgumentError.value(
        decimalPlaces,
        'decimalPlaces',
        'decimalPlaces must be between 0 and 2 inclusive.',
      );
    }

    final buffer = StringBuffer();

    if (decimalPlaces == 0) {
      final val = rounded ? roundedPercentage : percentage;
      buffer.write(val.toString());
    } else if (decimalPlaces == 1) {
      final tenths = (basisPoints + 5) ~/ 10;
      final whole = tenths ~/ 10;
      final frac = tenths % 10;
      buffer.write('$whole.$frac');
    } else {
      // 2 decimal places: exact basis points
      final whole = basisPoints ~/ 100;
      final frac = (basisPoints % 100).toString().padLeft(2, '0');
      buffer.write('$whole.$frac');
    }

    if (includeSymbol) {
      buffer.write('%');
    }

    return buffer.toString();
  }

  /// Converts progress to a UI rendering fraction strictly within `[0.0, 1.0]`
  /// for Flutter progress indicators (such as `LinearProgressIndicator(value: ...)`).
  ///
  /// This is the explicit presentation boundary converter. All domain arithmetic
  /// and financial state remain strictly integer-based via [basisPoints] and [Money].
  double toProgressFraction() {
    if (savedAmount.isZero) {
      return 0.0;
    }
    if (isGoalReached) {
      return 1.0;
    }
    return (savedAmount.kobo / targetAmount.kobo).clamp(0.0, 1.0);
  }

  /// Projects savings progress assuming a successful [contribution].
  ///
  /// - [contribution] must not be negative; otherwise throws [ArgumentError].
  /// - A zero contribution is permitted and returns an identical progress state.
  SavingsProgress projectContribution(Money contribution) {
    if (contribution.isNegative) {
      throw ArgumentError.value(
        contribution,
        'contribution',
        'Contribution amount cannot be negative.',
      );
    }
    return SavingsProgress(
      targetAmount: targetAmount,
      savedAmount: savedAmount + contribution,
    );
  }

  /// Alias for [projectContribution].
  SavingsProgress withContribution(Money contribution) =>
      projectContribution(contribution);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsProgress &&
          other.targetAmount == targetAmount &&
          other.savedAmount == savedAmount);

  @override
  int get hashCode => Object.hash(targetAmount, savedAmount);

  @override
  String toString() =>
      'SavingsProgress(saved: $savedAmount, target: $targetAmount, '
      'progress: ${formatPercentage()}, remaining: $remainingAmount)';
}
