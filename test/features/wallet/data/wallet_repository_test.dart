import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_backend_providers.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

class ThrowingRemoteApi implements RemoteApi {
  final Object error;

  ThrowingRemoteApi(this.error);

  @override
  Future<WalletSnapshot> fetchWalletSnapshot() => throw error;

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  }) => throw error;

  @override
  Future<RemoteOperationResult> contribute(FinancialOperation operation) =>
      throw UnimplementedError();

  @override
  Future<RemoteOperationResult> sendMoney(FinancialOperation operation) =>
      throw UnimplementedError();

  @override
  Future<RemoteOperationResult> submitOperation(FinancialOperation operation) =>
      throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late WalletDao walletDao;
  late TransactionDao transactionDao;
  late InMemoryRemoteLedger remoteLedger;
  late RemoteApi fakeRemote;
  late LocalWalletRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    walletDao = WalletDao(db);
    transactionDao = TransactionDao(db);
    remoteLedger = InMemoryRemoteLedger(
      initialBalance: const Money.fromKobo(20000000), // ₦200,000.00
    );
    fakeRemote = FakeRemoteApi(
      ledger: remoteLedger,
      failureSimulator: FailureSimulator(),
    );
    repository = LocalWalletRepository(
      walletDao: walletDao,
      transactionDao: transactionDao,
      remoteApi: fakeRemote,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalWalletRepository Refresh (T-WAL-001, WAL-001, WAL-002)', () {
    test('refresh fetches remote snapshot and transactions and populates local database', () async {
      // Initially local database is empty
      final initialLocalSnapshot = await repository.getWalletSnapshot();
      expect(initialLocalSnapshot, isNull);
      final initialLocalTx = await repository.getRecentTransactions();
      expect(initialLocalTx, isEmpty);

      // Populate remote ledger with a confirmed transaction
      final remoteTx = WalletTransaction(
        id: 'tx-remote-1',
        type: TransactionType.debit,
        amount: const Money.fromKobo(2500000), // ₦25,000.00
        counterparty: 'Adeleke Adele',
        createdAt: DateTime.utc(2026, 9, 21, 10, 0),
        status: TransactionStatus.completed,
        reference: 'REM-12345',
      );
      await remoteLedger.addTransaction(remoteTx);

      // Perform repository refresh
      await repository.refresh();

      // Local cache now has remote snapshot (₦200,000.00)
      final localSnapshot = await repository.getWalletSnapshot();
      expect(localSnapshot, isNotNull);
      expect(localSnapshot!.balance, equals(const Money.fromKobo(20000000)));

      // Local cache now has remote transaction
      final localTransactions = await repository.getRecentTransactions();
      expect(localTransactions.length, equals(1));
      expect(localTransactions.first.id, equals('tx-remote-1'));
      expect(
        localTransactions.first.amount,
        equals(const Money.fromKobo(2500000)),
      );
      expect(localTransactions.first.counterparty, equals('Adeleke Adele'));
    });

    test(
      'multiple consecutive refreshes are idempotent (no duplicates)',
      () async {
        final remoteTx = WalletTransaction(
          id: 'tx-remote-1',
          type: TransactionType.debit,
          amount: const Money.fromKobo(500000),
          counterparty: 'Merchant',
          createdAt: DateTime.utc(2026, 9, 21, 10, 0),
          status: TransactionStatus.completed,
        );
        await remoteLedger.addTransaction(remoteTx);

        // Refresh twice
        await repository.refresh();
        await repository.refresh();

        final localTransactions = await repository.getRecentTransactions();
        expect(localTransactions.length, equals(1));
        expect(localTransactions.first.id, equals('tx-remote-1'));
      },
    );

    test('refresh with no remoteApi configured is a safe no-op', () async {
      final repoWithoutRemote = LocalWalletRepository(
        walletDao: walletDao,
        transactionDao: transactionDao,
      );

      await expectLater(repoWithoutRemote.refresh(), completes);
    });

    test(
      'failure during remote refresh does not corrupt existing local data',
      () async {
        // Seed local database with initial snapshot
        final localSnapshot = WalletSnapshot(
          balance: const Money.fromKobo(5000000),
          lastUpdatedAt: DateTime.utc(2026, 9, 20),
        );
        await repository.setWalletSnapshot(localSnapshot);

        final failingRepo = LocalWalletRepository(
          walletDao: walletDao,
          transactionDao: transactionDao,
          remoteApi: ThrowingRemoteApi(
            const RemoteTransportException(message: 'Connection timed out'),
          ),
        );

        // Refresh throws
        expect(failingRepo.refresh, throwsA(isA<RemoteTransportException>()));

        // Existing local cached data remains intact
        final preserved = await repository.getWalletSnapshot();
        expect(preserved, isNotNull);
        expect(preserved!.balance, equals(const Money.fromKobo(5000000)));
      },
    );
  });

  group('Wallet Providers & Projection Integration', () {
    test(
      'walletProjectionProvider reactively builds valid projection',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            walletDaoProvider.overrideWithValue(walletDao),
            transactionDaoProvider.overrideWithValue(transactionDao),
            remoteApiProvider.overrideWithValue(fakeRemote),
          ],
        );
        addTearDown(container.dispose);

        // Seed local cache
        await walletDao.setWalletSnapshot(
          WalletSnapshot(
            balance: const Money.fromKobo(12545000), // ₦125,450.00
            lastUpdatedAt: DateTime.utc(2026, 9, 21, 12, 0),
          ),
        );
        await transactionDao.insertTransaction(
          WalletTransaction(
            id: 'tx-seed-1',
            type: TransactionType.debit,
            amount: const Money.fromKobo(1000000),
            counterparty: 'Ada Lovelace',
            createdAt: DateTime.utc(2026, 9, 21, 11, 0),
          ),
        );

        // Allow streams to emit initial data
        await container.read(walletSnapshotStreamProvider.future);
        await container.read(walletRecentTransactionsStreamProvider.future);
        await container.read(activeOperationsStreamProvider.future);

        final projectionAsync = container.read(walletProjectionProvider);
        expect(projectionAsync.hasValue, isTrue);

        final projection = projectionAsync.value!;
        expect(
          projection.confirmedBalance,
          equals(const Money.fromKobo(12545000)),
        );
        expect(
          projection.spendableBalance,
          equals(const Money.fromKobo(12545000)),
        );
        expect(projection.activities.length, equals(1));
        expect(projection.activities.first.title, equals('Ada Lovelace'));
      },
    );
  });
}
