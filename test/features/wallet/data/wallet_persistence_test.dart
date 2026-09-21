import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';

void main() {
  group(
    'Wallet & Transaction Persistence (T-DB-002, WAL-001, WAL-002, MNY-004)',
    () {
      late AppDatabase db;
      late WalletDao walletDao;
      late TransactionDao txDao;
      late LocalWalletRepository repo;

      setUp(() {
        db = AppDatabase.inMemory();
        walletDao = WalletDao(db);
        txDao = TransactionDao(db);
        repo = LocalWalletRepository(
          walletDao: walletDao,
          transactionDao: txDao,
        );
      });

      tearDown(() async {
        await db.close();
      });

      test('Persists and retrieves wallet snapshot with exact integer kobo (HC-MONEY)', () async {
        final initial = await repo.getWalletSnapshot();
        expect(initial, isNull);

        final snapshot = WalletSnapshot(
          balance: Money.fromNaira(125450), // 12,545,000 kobo
          lastUpdatedAt: DateTime.utc(2026, 9, 21, 15, 0, 0),
        );

        await repo.setWalletSnapshot(snapshot);

        final loaded = await repo.getWalletSnapshot();
        expect(loaded, isNotNull);
        expect(loaded!.balance.kobo, equals(12545000));
        expect(loaded.balance.format(), equals('₦125,450.00'));
        expect(
          loaded.lastUpdatedAt,
          equals(DateTime.utc(2026, 9, 21, 15, 0, 0)),
        );
      });

      test('Updating wallet snapshot overwrites singleton row', () async {
        await repo.setWalletSnapshot(
          WalletSnapshot(balance: Money.fromNaira(10000)),
        );
        expect((await repo.getWalletSnapshot())!.balance.kobo, equals(1000000));

        await repo.setWalletSnapshot(
          WalletSnapshot(balance: Money.fromNaira(7500)),
        );
        expect((await repo.getWalletSnapshot())!.balance.kobo, equals(750000));
      });

      test('Streams reactive wallet snapshot updates', () async {
        final stream = repo.watchWalletSnapshot();

        final expectation = expectLater(
          stream,
          emitsInOrder([
            isNull,
            predicate<WalletSnapshot?>(
              (s) => s != null && s.balance.kobo == 500000,
            ),
            predicate<WalletSnapshot?>(
              (s) => s != null && s.balance.kobo == 250000,
            ),
          ]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repo.setWalletSnapshot(
          WalletSnapshot(balance: Money.fromNaira(5000)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repo.setWalletSnapshot(
          WalletSnapshot(balance: Money.fromNaira(2500)),
        );

        await expectation;
      });

      test(
        'Persists and retrieves transactions preserving order and fields',
        () async {
          final tx1 = WalletTransaction(
            id: 'tx-1',
            type: TransactionType.debit,
            amount: Money.fromNaira(5000),
            counterparty: 'Adeola Adeleke',
            createdAt: DateTime.utc(2026, 9, 21, 10, 0, 0),
            status: TransactionStatus.completed,
            reference: 'REF-TX-001',
            narration: 'Lunch repayment',
          );

          final tx2 = WalletTransaction(
            id: 'tx-2',
            type: TransactionType.credit,
            amount: Money.fromNaira(20000),
            counterparty: 'Salary Deposit',
            createdAt: DateTime.utc(2026, 9, 21, 11, 0, 0),
            status: TransactionStatus.completed,
          );

          await repo.saveTransactions([tx1, tx2]);

          final loaded1 = await repo.getTransactionById('tx-1');
          expect(loaded1, isNotNull);
          expect(loaded1!.type, equals(TransactionType.debit));
          expect(loaded1.amount.kobo, equals(500000));
          expect(loaded1.counterparty, equals('Adeola Adeleke'));
          expect(loaded1.reference, equals('REF-TX-001'));
          expect(loaded1.narration, equals('Lunch repayment'));

          // Recent transactions ordered by newest first (descending createdAt)
          final recent = await repo.getRecentTransactions();
          expect(recent.length, equals(2));
          expect(recent[0].id, equals('tx-2'));
          expect(recent[1].id, equals('tx-1'));
        },
      );

      test(
        'Supports pagination and lazy loading limits (HC-PERFORMANCE)',
        () async {
          final transactions = List.generate(
            15,
            (i) => WalletTransaction(
              id: 'tx-$i',
              type: TransactionType.debit,
              amount: Money.fromNaira(100 + i),
              counterparty: 'User $i',
              createdAt: DateTime.utc(2026, 9, 21, 1, i, 0),
            ),
          );

          await repo.saveTransactions(transactions);

          // Fetch first page of 5 items
          final page1 = await repo.getRecentTransactions(limit: 5, offset: 0);
          expect(page1.length, equals(5));
          expect(page1.first.id, equals('tx-14')); // Newest first

          // Fetch second page of 5 items
          final page2 = await repo.getRecentTransactions(limit: 5, offset: 5);
          expect(page2.length, equals(5));
          expect(page2.first.id, equals('tx-9'));
        },
      );
    },
  );

  group(
    'Wallet & Transaction File Reopen Survival (HC-OFFLINE-DURABILITY)',
    () {
      late Directory tempDir;
      late File dbFile;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp(
          'novawallet_wallet_test_',
        );
        dbFile = File('${tempDir.path}/wallet_test.sqlite');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test(
        'Cached wallet and transactions survive connection reopen',
        () async {
          // 1. Connection 1: Save balance and transactions, then close
          {
            final db1 = AppDatabase.forFile(dbFile);
            final repo1 = LocalWalletRepository(
              walletDao: WalletDao(db1),
              transactionDao: TransactionDao(db1),
            );

            await repo1.setWalletSnapshot(
              WalletSnapshot(
                balance: Money.fromNaira(88000),
                lastUpdatedAt: DateTime.utc(2026, 9, 21, 12, 0, 0),
              ),
            );

            await repo1.saveTransaction(
              WalletTransaction(
                id: 'durable-tx-1',
                type: TransactionType.debit,
                amount: Money.fromNaira(12000),
                counterparty: 'Bisi Johnson',
                createdAt: DateTime.utc(2026, 9, 21, 12, 1, 0),
              ),
            );

            await db1.close();
          }

          // 2. Connection 2: Reopen file and verify all cached records survive
          {
            final db2 = AppDatabase.forFile(dbFile);
            final repo2 = LocalWalletRepository(
              walletDao: WalletDao(db2),
              transactionDao: TransactionDao(db2),
            );

            final snapshot = await repo2.getWalletSnapshot();
            expect(snapshot, isNotNull);
            expect(snapshot!.balance.kobo, equals(8800000));
            expect(snapshot.balance.format(), equals('₦88,000.00'));

            final txs = await repo2.getRecentTransactions();
            expect(txs.length, equals(1));
            expect(txs.first.id, equals('durable-tx-1'));
            expect(txs.first.amount.kobo, equals(1200000));
            expect(txs.first.counterparty, equals('Bisi Johnson'));

            await db2.close();
          }
        },
      );
    },
  );
}
