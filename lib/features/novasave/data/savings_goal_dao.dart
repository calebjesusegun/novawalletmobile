import 'package:drift/drift.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Clean mapping between Drift [SavingsGoalEntry] and domain [SavingsGoal].
class SavingsGoalMapper {
  const SavingsGoalMapper._();

  static SavingsGoalsTableCompanion toCompanion(SavingsGoal goal) {
    return SavingsGoalsTableCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      targetAmountKobo: Value(BigInt.from(goal.targetAmount.kobo)),
      savedAmountKobo: Value(BigInt.from(goal.savedAmount.kobo)),
      targetDate: Value(BigInt.from(goal.targetDate.millisecondsSinceEpoch)),
      createdAt: Value(
        BigInt.from(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  static SavingsGoal toDomain(SavingsGoalEntry row) {
    return SavingsGoal(
      id: row.id,
      name: row.name,
      targetAmount: Money.fromKobo(row.targetAmountKobo.toInt()),
      savedAmount: Money.fromKobo(row.savedAmountKobo.toInt()),
      targetDate: DateTime.fromMillisecondsSinceEpoch(
        row.targetDate.toInt(),
        isUtc: true,
      ),
    );
  }
}

/// Data Access Object for local savings goals.
///
/// Implements goal persistence per docs/ARCHITECTURE.md §13.2, NSV-001, and NSV-003.
/// Under HC-MONEY: All targets and saved amounts are exact integer kobo (Money).
class SavingsGoalDao {
  final AppDatabase db;

  SavingsGoalDao(this.db);

  /// Inserts a newly created savings goal into local persistence.
  Future<void> insertGoal(SavingsGoal goal) async {
    await db
        .into(db.savingsGoalsTable)
        .insert(SavingsGoalMapper.toCompanion(goal));
  }

  /// Updates an existing goal's details or saved amount.
  Future<void> updateGoal(SavingsGoal goal) async {
    await (db.update(
      db.savingsGoalsTable,
    )..where((tbl) => tbl.id.equals(goal.id))).write(
      SavingsGoalsTableCompanion(
        name: Value(goal.name),
        targetAmountKobo: Value(BigInt.from(goal.targetAmount.kobo)),
        savedAmountKobo: Value(BigInt.from(goal.savedAmount.kobo)),
        targetDate: Value(BigInt.from(goal.targetDate.millisecondsSinceEpoch)),
      ),
    );
  }

  /// Applies a contribution to an existing goal atomically.
  ///
  /// Increments the saved amount by [contribution] in exact integer kobo.
  Future<SavingsGoal> applyContribution(
    String goalId,
    Money contribution,
  ) async {
    contribution.ensurePositive();

    return db.transaction(() async {
      final existing = await getGoalById(goalId);
      if (existing == null) {
        throw StateError('Savings goal with id $goalId not found.');
      }

      final updated = existing.withContribution(contribution);
      await updateGoal(updated);
      return updated;
    });
  }

  /// Retrieves a goal by its unique ID.
  Future<SavingsGoal?> getGoalById(String id) async {
    final row = await (db.select(
      db.savingsGoalsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? SavingsGoalMapper.toDomain(row) : null;
  }

  /// Retrieves all savings goals, ordered by creation date ascending.
  Future<List<SavingsGoal>> getAllGoals() async {
    final query = db.select(db.savingsGoalsTable)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(SavingsGoalMapper.toDomain).toList();
  }

  /// Watches all savings goals as a Stream for reactive UI updates.
  Stream<List<SavingsGoal>> watchAllGoals() {
    final query = db.select(db.savingsGoalsTable)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map(
      (rows) => rows.map(SavingsGoalMapper.toDomain).toList(),
    );
  }

  /// Deletes a goal by ID.
  Future<int> deleteGoal(String id) async {
    return (db.delete(
      db.savingsGoalsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }
}
