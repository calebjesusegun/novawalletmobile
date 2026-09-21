import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/domain/savings_progress.dart';

void main() {
  group('SavingsGoal Domain Entity', () {
    final futureDate = DateTime(2026, 12, 30);

    test('creates valid goal with zero initial saved amount by default', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        targetDate: futureDate,
      );

      expect(goal.id, 'goal-001');
      expect(goal.name, 'Emergency Fund');
      expect(goal.targetAmount, Money.fromNaira(500000));
      expect(goal.savedAmount, const Money.zero());
      expect(goal.targetDate, futureDate);

      // Derived properties
      expect(goal.percentage, 0);
      expect(goal.basisPoints, 0);
      expect(goal.remainingAmount, Money.fromNaira(500000));
      expect(goal.excessAmount, const Money.zero());
      expect(goal.isGoalReached, isFalse);
      expect(goal.isOverTarget, isFalse);
      expect(goal.progress.toProgressFraction(), 0.0);
    });

    test('Given ₦150,000 saved toward ₦500,000, progress is 30% and remaining is ₦350,000', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      expect(goal.percentage, 30);
      expect(goal.basisPoints, 3000);
      expect(goal.remainingAmount, Money.fromNaira(350000));
      expect(goal.progress.toProgressFraction(), 0.3);
      expect(goal.isGoalReached, isFalse);
    });

    test('withContribution updates saved amount and resolves progress from 30% to 40%', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      final updatedGoal = goal.withContribution(Money.fromNaira(50000));

      expect(updatedGoal.savedAmount, Money.fromNaira(200000));
      expect(updatedGoal.percentage, 40);
      expect(updatedGoal.basisPoints, 4000);
      expect(updatedGoal.remainingAmount, Money.fromNaira(300000));
      expect(updatedGoal.progress.toProgressFraction(), 0.4);
    });

    test('projectContribution projects progress without modifying goal', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      final projectedProgress = goal.projectContribution(
        Money.fromNaira(50000),
      );

      expect(projectedProgress, isA<SavingsProgress>());
      expect(projectedProgress.percentage, 40);
      expect(projectedProgress.savedAmount, Money.fromNaira(200000));

      // Original goal is untouched
      expect(goal.percentage, 30);
      expect(goal.savedAmount, Money.fromNaira(150000));
    });

    test('validations reject invalid goal data', () {
      // Empty id
      expect(
        () => SavingsGoal(
          id: '   ',
          name: 'Emergency Fund',
          targetAmount: Money.fromNaira(500000),
          targetDate: futureDate,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Goal id cannot be empty'),
          ),
        ),
      );

      // Empty name
      expect(
        () => SavingsGoal(
          id: 'goal-001',
          name: '',
          targetAmount: Money.fromNaira(500000),
          targetDate: futureDate,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Goal name cannot be empty'),
          ),
        ),
      );

      // Non-positive target amount
      expect(
        () => SavingsGoal(
          id: 'goal-001',
          name: 'Emergency Fund',
          targetAmount: const Money.zero(),
          targetDate: futureDate,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Target amount must be strictly greater than zero'),
          ),
        ),
      );

      // Negative saved amount
      expect(
        () => SavingsGoal(
          id: 'goal-001',
          name: 'Emergency Fund',
          targetAmount: Money.fromNaira(500000),
          savedAmount: Money.fromNaira(-5000),
          targetDate: futureDate,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Saved amount cannot be negative'),
          ),
        ),
      );

      // Negative contribution
      final validGoal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        targetDate: futureDate,
      );
      expect(
        () => validGoal.withContribution(Money.fromNaira(-1000)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Contribution amount cannot be negative'),
          ),
        ),
      );
    });

    test('copyWith updates properties accurately', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      final modified = goal.copyWith(name: 'House Savings');
      expect(modified.id, goal.id);
      expect(modified.name, 'House Savings');
      expect(modified.targetAmount, goal.targetAmount);
      expect(modified.savedAmount, goal.savedAmount);
      expect(modified.targetDate, goal.targetDate);
    });

    test('equality and hashCode', () {
      final goal1 = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );
      final goal2 = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );
      final goal3 = SavingsGoal(
        id: 'goal-002',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      expect(goal1, equals(goal2));
      expect(goal1.hashCode, equals(goal2.hashCode));
      expect(goal1, isNot(equals(goal3)));
    });

    test('toString includes relevant goal summary', () {
      final goal = SavingsGoal(
        id: 'goal-001',
        name: 'Emergency Fund',
        targetAmount: Money.fromNaira(500000),
        savedAmount: Money.fromNaira(150000),
        targetDate: futureDate,
      );

      final str = goal.toString();
      expect(str, contains('goal-001'));
      expect(str, contains('Emergency Fund'));
      expect(str, contains('₦150,000.00'));
      expect(str, contains('₦500,000.00'));
      expect(str, contains('30%'));
      expect(str, contains('₦350,000.00'));
    });
  });
}
