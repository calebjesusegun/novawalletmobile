import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/novasave_repository.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Concrete implementation of [NovaSaveRepository] backed by [SavingsGoalDao].
class LocalNovaSaveRepository implements NovaSaveRepository {
  final SavingsGoalDao savingsGoalDao;

  LocalNovaSaveRepository({required this.savingsGoalDao});

  @override
  Future<List<SavingsGoal>> getGoals() => savingsGoalDao.getAllGoals();

  @override
  Stream<List<SavingsGoal>> watchGoals() => savingsGoalDao.watchAllGoals();

  @override
  Future<void> createGoal(SavingsGoal goal) => savingsGoalDao.insertGoal(goal);

  @override
  Future<SavingsGoal?> getGoal(String id) => savingsGoalDao.getGoalById(id);

  @override
  Future<void> updateGoal(SavingsGoal goal) => savingsGoalDao.updateGoal(goal);

  @override
  Future<SavingsGoal> applyContribution(String goalId, Money contribution) =>
      savingsGoalDao.applyContribution(goalId, contribution);

  @override
  Future<void> deleteGoal(String id) => savingsGoalDao.deleteGoal(id);
}
