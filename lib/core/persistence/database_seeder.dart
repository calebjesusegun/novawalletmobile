import 'package:drift/drift.dart';
import 'package:novawallet/core/persistence/app_database.dart';

/// Seeds canonical initial demonstration data on fresh application launch.
///
/// Implements:
/// - Baseline wallet balance of ₦125,450.00 (12,545,000 kobo) matching design exports (UI-WAL-01, AD-01).
/// - Initial sample transactions (Ada Lovelace, Chidi Anagonye) for immediate demonstration.
/// - Canonical Emergency Fund savings goal (₦150,000 / ₦500,000) matching NovaSave designs (UI-NSV-01, UI-NSV-08).
/// - Synchronization of local cache and fake-remote ledger so both start consistently.
class DatabaseSeeder {
  final AppDatabase db;

  const DatabaseSeeder(this.db);

  /// Seeds demo data only if the respective local tables are currently empty.
  /// If data already exists, existing user records are strictly preserved.
  Future<void> seedIfEmpty() async {
    final now = DateTime.now().toUtc();
    final nowMs = BigInt.from(now.millisecondsSinceEpoch);

    // 1. Seed Wallet balance if absent
    final existingWallet = await (db.select(
      db.walletCache,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    if (existingWallet == null) {
      await db
          .into(db.walletCache)
          .insertOnConflictUpdate(
            WalletCacheCompanion.insert(
              id: const Value(1),
              balanceKobo: BigInt.from(12545000), // ₦125,450.00
              lastUpdatedAt: nowMs,
            ),
          );

      await db
          .into(db.remoteWalletStateTable)
          .insertOnConflictUpdate(
            RemoteWalletStateTableCompanion.insert(
              id: const Value(1),
              balanceKobo: BigInt.from(12545000),
              lastUpdatedAt: nowMs,
            ),
          );
    }

    // 2. Seed Sample Goals if absent
    final existingGoals = await db.select(db.savingsGoalsTable).get();
    if (existingGoals.isEmpty) {
      await db
          .into(db.savingsGoalsTable)
          .insert(
            SavingsGoalsTableCompanion.insert(
              id: 'goal-emergency-fund-1',
              name: 'Emergency Fund',
              targetAmountKobo: BigInt.from(50000000), // ₦500,000.00
              savedAmountKobo: BigInt.from(15000000), // ₦150,000.00 (30%)
              targetDate: BigInt.from(
                DateTime.utc(2026, 12, 30).millisecondsSinceEpoch,
              ),
              createdAt: BigInt.from(
                DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
              ),
            ),
          );
    }

    // 3. Seed Sample Transactions if absent
    final existingTxs = await db.select(db.transactionsTable).get();
    if (existingTxs.isEmpty) {
      final sampleTxs = [
        TransactionsTableCompanion.insert(
          id: 'tx-seed-1',
          transactionType: 'debit',
          amountKobo: BigInt.from(1000000), // ₦10,000.00
          counterparty: 'Ada Lovelace',
          createdAt: BigInt.from(
            now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
          ),
          status: const Value('completed'),
          reference: const Value('TX-REF-ADA-001'),
          narration: const Value('Project collaboration payment'),
        ),
        TransactionsTableCompanion.insert(
          id: 'tx-seed-2',
          transactionType: 'debit',
          amountKobo: BigInt.from(500000), // ₦5,000.00
          counterparty: 'Chidi Anagonye',
          createdAt: BigInt.from(
            now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          ),
          status: const Value('completed'),
          reference: const Value('TX-REF-CHI-002'),
          narration: const Value('Dinner settlement'),
        ),
      ];

      for (final tx in sampleTxs) {
        await db.into(db.transactionsTable).insert(tx);
        await db
            .into(db.remoteTransactionsTable)
            .insert(
              RemoteTransactionsTableCompanion.insert(
                id: tx.id.value,
                transactionType: tx.transactionType.value,
                amountKobo: tx.amountKobo.value,
                counterparty: tx.counterparty.value,
                createdAt: tx.createdAt.value,
                status: tx.status,
                reference: tx.reference,
                narration: tx.narration,
              ),
            );
      }
    }
  }
}
