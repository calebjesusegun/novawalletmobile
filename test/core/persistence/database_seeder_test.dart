import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/core/persistence/database_seeder.dart';

void main() {
  group('DatabaseSeeder', () {
    late AppDatabase db;
    late DatabaseSeeder seeder;

    setUp(() {
      db = AppDatabase.inMemory();
      seeder = DatabaseSeeder(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'seeds canonical initial data when database is completely empty',
      () async {
        // Initially empty
        final initialWallet = await (db.select(
          db.walletCache,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(initialWallet, isNull);

        final initialGoals = await db.select(db.savingsGoalsTable).get();
        expect(initialGoals, isEmpty);

        final initialTxs = await db.select(db.transactionsTable).get();
        expect(initialTxs, isEmpty);

        // Run seeder
        await seeder.seedIfEmpty();

        // Verified: Wallet cache has ₦125,450.00
        final seededWallet = await (db.select(
          db.walletCache,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(seededWallet, isNotNull);
        expect(seededWallet!.balanceKobo, BigInt.from(12545000));

        // Verified: Remote wallet state has matching ₦125,450.00
        final seededRemoteWallet = await (db.select(
          db.remoteWalletStateTable,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(seededRemoteWallet, isNotNull);
        expect(seededRemoteWallet!.balanceKobo, BigInt.from(12545000));

        // Verified: Emergency Fund goal seeded
        final seededGoals = await db.select(db.savingsGoalsTable).get();
        expect(seededGoals.length, 1);
        final goal = seededGoals.first;
        expect(goal.name, 'Emergency Fund');
        expect(goal.targetAmountKobo, BigInt.from(50000000)); // ₦500,000.00
        expect(
          goal.savedAmountKobo,
          BigInt.from(15000000),
        ); // ₦150,000.00 (30%)

        // Verified: Sample transactions seeded
        final seededTxs = await db.select(db.transactionsTable).get();
        expect(seededTxs.length, 2);
        expect(
          seededTxs.map((t) => t.counterparty),
          containsAll(['Ada Lovelace', 'Chidi Anagonye']),
        );

        final seededRemoteTxs = await db
            .select(db.remoteTransactionsTable)
            .get();
        expect(seededRemoteTxs.length, 2);
      },
    );

    test(
      'is idempotent and preserves existing user data without overwriting',
      () async {
        // First seed
        await seeder.seedIfEmpty();

        // User modifies balance after spending
        await (db.update(db.walletCache)..where((t) => t.id.equals(1))).write(
          WalletCacheCompanion(
            balanceKobo: Value(BigInt.from(9000000)), // ₦90,000.00
            lastUpdatedAt: Value(
              BigInt.from(DateTime.now().millisecondsSinceEpoch),
            ),
          ),
        );

        // Run seeder again (e.g. app reopened)
        await seeder.seedIfEmpty();

        // Verified: User's updated balance was NOT reset
        final wallet = await (db.select(
          db.walletCache,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(wallet!.balanceKobo, BigInt.from(9000000));

        // Goals and transactions are not duplicated
        final goals = await db.select(db.savingsGoalsTable).get();
        expect(goals.length, 1);

        final txs = await db.select(db.transactionsTable).get();
        expect(txs.length, 2);
      },
    );
  });
}
