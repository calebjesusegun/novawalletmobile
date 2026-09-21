import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_progress.dart';

/// Domain entity representing a savings goal.
///
/// In accordance with the NovaWallet architecture:
/// - Monetary fields [targetAmount] and [savedAmount] are modeled as [Money]
///   (backed strictly by integer kobo).
/// - Derived properties [remainingAmount] and [progress] are calculated
///   directly via [SavingsProgress] without floating-point arithmetic.
@immutable
class SavingsGoal {
  /// Creates a [SavingsGoal] entity.
  ///
  /// - [id] and [name] must not be empty or blank; otherwise throws [ArgumentError].
  /// - [targetAmount] must be strictly greater than zero; otherwise throws [ArgumentError].
  /// - [savedAmount] defaults to [Money.zero()] and cannot be negative;
  ///   otherwise throws [ArgumentError].
  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    Money? savedAmount,
    required this.targetDate,
  }) : savedAmount = savedAmount ?? const Money.zero() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Goal id cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Goal name cannot be empty.');
    }
    if (targetAmount.isZero || targetAmount.isNegative) {
      throw ArgumentError.value(
        targetAmount,
        'targetAmount',
        'Target amount must be strictly greater than zero.',
      );
    }
    if (this.savedAmount.isNegative) {
      throw ArgumentError.value(
        this.savedAmount,
        'savedAmount',
        'Saved amount cannot be negative.',
      );
    }
  }

  /// Unique identifier for this savings goal.
  final String id;

  /// User-defined display name for this goal (e.g. "Emergency Fund").
  final String name;

  /// Target monetary amount to reach.
  final Money targetAmount;

  /// Amount saved so far.
  final Money savedAmount;

  /// The target completion date.
  final DateTime targetDate;

  /// Derived savings progress calculation model.
  SavingsProgress get progress =>
      SavingsProgress(targetAmount: targetAmount, savedAmount: savedAmount);

  /// Derived remaining amount required to reach the target.
  ///
  /// Returns [Money.zero] if the target has been reached or exceeded.
  Money get remainingAmount => progress.remainingAmount;

  /// Derived excess amount saved beyond the target.
  Money get excessAmount => progress.excessAmount;

  /// Integer percentage capped at 100%.
  int get percentage => progress.percentage;

  /// Integer basis points capped at 10,000 (100.00%).
  int get basisPoints => progress.basisPoints;

  /// Whether the target amount has been reached or exceeded.
  bool get isGoalReached => progress.isGoalReached;

  /// Whether the saved amount strictly exceeds the target amount.
  bool get isOverTarget => progress.isOverTarget;

  /// Returns a copy of this goal updated with an added [contribution].
  ///
  /// Throws [ArgumentError] if [contribution] is negative.
  SavingsGoal withContribution(Money contribution) {
    if (contribution.isNegative) {
      throw ArgumentError.value(
        contribution,
        'contribution',
        'Contribution amount cannot be negative.',
      );
    }
    return copyWith(savedAmount: savedAmount + contribution);
  }

  /// Projects the savings progress that would result from a [contribution]
  /// without modifying this goal.
  SavingsProgress projectContribution(Money contribution) =>
      progress.projectContribution(contribution);

  /// Creates a copy of this goal with replaced values.
  SavingsGoal copyWith({
    String? id,
    String? name,
    Money? targetAmount,
    Money? savedAmount,
    DateTime? targetDate,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == id &&
          other.name == name &&
          other.targetAmount == targetAmount &&
          other.savedAmount == savedAmount &&
          other.targetDate == targetDate);

  @override
  int get hashCode =>
      Object.hash(id, name, targetAmount, savedAmount, targetDate);

  @override
  String toString() =>
      'SavingsGoal(id: $id, name: "$name", saved: $savedAmount, '
      'target: $targetAmount, remaining: $remainingAmount, '
      'progress: ${progress.formatPercentage()}, targetDate: $targetDate)';
}
