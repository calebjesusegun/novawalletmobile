import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/features/novasave/data/local_novasave_repository.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/novasave_repository.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Provider for [SavingsGoalDao].
final savingsGoalDaoProvider = Provider<SavingsGoalDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SavingsGoalDao(db);
});

/// Provider for [NovaSaveRepository].
final novaSaveRepositoryProvider = Provider<NovaSaveRepository>((ref) {
  return LocalNovaSaveRepository(
    savingsGoalDao: ref.watch(savingsGoalDaoProvider),
  );
});

/// Stream provider watching the reactive list of all savings goals.
final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(novaSaveRepositoryProvider);
  return repo.watchGoals();
});
