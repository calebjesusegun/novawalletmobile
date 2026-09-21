import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Abstract contract for savings goals persistence and retrieval.
///
/// Implements repository boundary hiding Drift persistence details per docs/ARCHITECTURE.md §15.
abstract class NovaSaveRepository {
  /// Retrieves all persisted savings goals.
  Future<List<SavingsGoal>> getGoals();

  /// Watches all persisted savings goals reactively.
  Stream<List<SavingsGoal>> watchGoals();

  /// Creates and persists a new savings goal.
  Future<void> createGoal(SavingsGoal goal);

  /// Retrieves a specific goal by ID.
  Future<SavingsGoal?> getGoal(String id);

  /// Updates an existing savings goal.
  Future<void> updateGoal(SavingsGoal goal);

  /// Records a contribution against a goal, updating its saved amount.
  Future<SavingsGoal> applyContribution(String goalId, Money contribution);

  /// Deletes a goal by ID.
  Future<void> deleteGoal(String id);
}
