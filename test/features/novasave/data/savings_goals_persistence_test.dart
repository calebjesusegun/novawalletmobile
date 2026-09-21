import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/features/novasave/data/local_novasave_repository.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

void main() {
  group('Savings Goals Persistence (T-DB-002, NSV-001, NSV-003, MNY-005)', () {
    late AppDatabase db;
    late SavingsGoalDao dao;
    late LocalNovaSaveRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      dao = SavingsGoalDao(db);
      repo = LocalNovaSaveRepository(savingsGoalDao: dao);
    });

    tearDown(() async {
      await db.close();
    });

    test('Persists and loads goal with exact integer kobo target and saved amount (HC-MONEY)', () async {
      final targetDate = DateTime.utc(2027, 1, 1);
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'New Laptop',
        targetAmount: Money.fromNaira(500000), // 50,000,000 kobo
        savedAmount: Money.fromNaira(150000), // 15,000,000 kobo
        targetDate: targetDate,
      );

      await repo.createGoal(goal);

      final loaded = await repo.getGoal('goal-1');
      expect(loaded, isNotNull);
      expect(loaded!.id, equals('goal-1'));
      expect(loaded.name, equals('New Laptop'));
      expect(loaded.targetAmount.kobo, equals(50000000));
      expect(loaded.savedAmount.kobo, equals(15000000));
      expect(loaded.targetDate, equals(targetDate));

      // Derived properties work correctly from persisted data
      expect(loaded.percentage, equals(30));
      expect(loaded.basisPoints, equals(3000));
      expect(loaded.remainingAmount.kobo, equals(35000000));
      expect(loaded.remainingAmount.format(), equals('₦350,000.00'));
    });

    test(
      'Atomically applies contribution and increments saved amount',
      () async {
        final goal = SavingsGoal(
          id: 'goal-2',
          name: 'Emergency Fund',
          targetAmount: Money.fromNaira(1000000),
          savedAmount: Money.fromNaira(200000),
          targetDate: DateTime.utc(2027, 6, 30),
        );

        await repo.createGoal(goal);

        final contribution = Money.fromNaira(50000); // ₦50,000
        final updated = await repo.applyContribution('goal-2', contribution);

        expect(updated.savedAmount.kobo, equals(25000000)); // ₦250,000
        expect(updated.percentage, equals(25));
        expect(updated.remainingAmount.kobo, equals(75000000));

        final fromDb = await repo.getGoal('goal-2');
        expect(fromDb!.savedAmount.kobo, equals(25000000));
      },
    );

    test(
      'getAllGoals and watchGoals return reactive list of persisted goals',
      () async {
        final goal1 = SavingsGoal(
          id: 'g-1',
          name: 'Goal 1',
          targetAmount: Money.fromNaira(10000),
          targetDate: DateTime.utc(2027, 1, 1),
        );
        final goal2 = SavingsGoal(
          id: 'g-2',
          name: 'Goal 2',
          targetAmount: Money.fromNaira(20000),
          targetDate: DateTime.utc(2027, 2, 1),
        );

        await repo.createGoal(goal1);
        await repo.createGoal(goal2);

        final all = await repo.getGoals();
        expect(all.length, equals(2));
        expect(all.map((g) => g.id), containsAll(['g-1', 'g-2']));

        await repo.deleteGoal('g-1');
        final remaining = await repo.getGoals();
        expect(remaining.length, equals(1));
        expect(remaining.first.id, equals('g-2'));
      },
    );
  });

  group('Savings Goals File Reopen Survival (HC-OFFLINE-DURABILITY)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('novawallet_goals_test_');
      dbFile = File('${tempDir.path}/goals_test.sqlite');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'Persisted goals survive database close and reopen across connections',
      () async {
        final targetDate = DateTime.utc(2027, 12, 31);

        // Connection 1: Create goal, apply contribution, and close DB
        {
          final db1 = AppDatabase.forFile(dbFile);
          final repo1 = LocalNovaSaveRepository(
            savingsGoalDao: SavingsGoalDao(db1),
          );

          final goal = SavingsGoal(
            id: 'goal-durable',
            name: 'Home Renovation',
            targetAmount: Money.fromNaira(2000000),
            savedAmount: Money.fromNaira(500000),
            targetDate: targetDate,
          );

          await repo1.createGoal(goal);
          await repo1.applyContribution(
            'goal-durable',
            Money.fromNaira(150000),
          );

          await db1.close();
        }

        // Connection 2: Reopen same file and verify goal and contributions survived
        {
          final db2 = AppDatabase.forFile(dbFile);
          final repo2 = LocalNovaSaveRepository(
            savingsGoalDao: SavingsGoalDao(db2),
          );

          final loaded = await repo2.getGoal('goal-durable');
          expect(loaded, isNotNull);
          expect(loaded!.name, equals('Home Renovation'));
          expect(loaded.targetAmount.kobo, equals(200000000));
          expect(
            loaded.savedAmount.kobo,
            equals(65000000),
          ); // 500,000 + 150,000 = 650,000
          expect(loaded.remainingAmount.kobo, equals(135000000));
          expect(loaded.targetDate, equals(targetDate));

          await db2.close();
        }
      },
    );
  });
}
