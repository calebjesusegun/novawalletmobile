import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/novasave/data/local_novasave_repository.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/application/sync_application.dart';
import 'package:novawallet/sync/data/local_operation_repository.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

void main() {
  group('SyncCoordinator (HC-SYNC, HC-EXACTLY-ONCE-EFFECT, T-SYNC-002)', () {
    late AppDatabase db;
    late PendingOperationsDao pendingOpsDao;
    late LocalOperationRepository opRepo;

    late WalletDao walletDao;
    late TransactionDao txDao;
    late LocalWalletRepository walletRepo;

    late SavingsGoalDao goalDao;
    late LocalNovaSaveRepository goalRepo;

    late InMemoryRemoteLedger remoteLedger;
    late FailureSimulator failureSimulator;
    late FakeRemoteApi remoteApi;

    late InMemoryConnectivityService connectivityService;
    late SyncCoordinator coordinator;

    setUp(() async {
      db = AppDatabase.inMemory();
      pendingOpsDao = PendingOperationsDao(db);
      opRepo = LocalOperationRepository(pendingOpsDao);

      walletDao = WalletDao(db);
      txDao = TransactionDao(db);
      walletRepo = LocalWalletRepository(
        walletDao: walletDao,
        transactionDao: txDao,
      );
      // Initialize local wallet with ₦100,000 (10,000,000 kobo)
      await walletRepo.setWalletSnapshot(
        WalletSnapshot(balance: const Money.fromKobo(10000000)),
      );

      goalDao = SavingsGoalDao(db);
      goalRepo = LocalNovaSaveRepository(savingsGoalDao: goalDao);
      // Initialize a sample savings goal
      await goalRepo.createGoal(
        SavingsGoal(
          id: 'goal-1',
          name: 'Tech Upgrade',
          targetAmount: const Money.fromKobo(5000000), // ₦50,000
          targetDate: DateTime.utc(2027, 1, 1),
          savedAmount: const Money.zero(),
        ),
      );

      remoteLedger = InMemoryRemoteLedger();
      // Initialize remote balance with ₦100,000 (10,000,000 kobo)
      await remoteLedger.setBalance(const Money.fromKobo(10000000));
      failureSimulator = FailureSimulator();
      remoteApi = FakeRemoteApi(
        ledger: remoteLedger,
        failureSimulator: failureSimulator,
      );

      connectivityService = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );

      coordinator = SyncCoordinator(
        operationRepository: opRepo,
        remoteApi: remoteApi,
        connectivityService: connectivityService,
        walletRepository: walletRepo,
        novaSaveRepository: goalRepo,
        autoSubscribeConnectivity: false, // controlled manually in test groups
      );
    });

    tearDown(() async {
      coordinator.dispose();
      connectivityService.dispose();
      await db.close();
    });

    test('processes both Send and Contribution operations in single shared coordinator (SYNC-005, ASM-011)', () async {
      // 1. Enqueue Send Money intent (₦10,000)
      final sendOp = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Kemi Adebayo',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000), // ₦10,000
        ),
      );

      // 2. Enqueue NovaSave Contribution intent (₦5,000)
      final contribOp = await opRepo.enqueueContribution(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: ContributionPayload(
          goalId: 'goal-1',
          goalName: 'Tech Upgrade',
          amount: const Money.fromKobo(500000), // ₦5,000
        ),
      );

      expect(sendOp.status, OperationStatus.pending);
      expect(contribOp.status, OperationStatus.pending);

      // 3. Trigger sync
      final result = await coordinator.synchronize();

      expect(result.totalDiscovered, 2);
      expect(result.totalClaimed, 2);
      expect(result.succeeded, 2);
      expect(result.hasErrors, isFalse);

      // 4. Verify local operations status
      final sendDb = await opRepo.getOperationById(sendOp.id);
      final contribDb = await opRepo.getOperationById(contribOp.id);

      expect(sendDb!.status, OperationStatus.completed);
      expect(sendDb.remoteReference, isNotNull);

      expect(contribDb!.status, OperationStatus.completed);
      expect(contribDb.remoteReference, isNotNull);

      // 5. Verify local confirmed balance: ₦100,000 - ₦10,000 - ₦5,000 = ₦85,000
      final wallet = await walletRepo.getWalletSnapshot();
      expect(wallet!.balance.kobo, 8500000);

      // 6. Verify local transactions saved
      final txs = await walletRepo.getRecentTransactions();
      expect(txs.length, 2);
      expect(
        txs.any(
          (tx) =>
              tx.type == TransactionType.debit &&
              tx.counterparty == 'Kemi Adebayo' &&
              tx.amount.kobo == 1000000,
        ),
        isTrue,
      );
      expect(
        txs.any(
          (tx) =>
              tx.type == TransactionType.debit &&
              tx.counterparty == 'Tech Upgrade' &&
              tx.amount.kobo == 500000,
        ),
        isTrue,
      );

      // 7. Verify goal progress updated
      final goal = await goalRepo.getGoal('goal-1');
      expect(goal!.savedAmount.kobo, 500000);

      // 8. Verify remote balance debited: 10,000,000 - 1,500,000 = 8,500,000
      expect(await remoteLedger.getBalance(), const Money.fromKobo(8500000));
    });

    test(
      'deterministic FIFO processing order (oldest first by createdAt)',
      () async {
        final processedOrder = <String>[];

        // Wrap sendMoney to track execution order
        final monitoredApi = _MonitoredRemoteApi(
          remoteApi,
          onSendMoney: (op) => processedOrder.add(op.id.value),
        );

        final coordinatorWithMonitor = SyncCoordinator(
          operationRepository: opRepo,
          remoteApi: monitoredApi,
          connectivityService: connectivityService,
          walletRepository: walletRepo,
          novaSaveRepository: goalRepo,
          autoSubscribeConnectivity: false,
        );
        addTearDown(coordinatorWithMonitor.dispose);

        final op1 = await opRepo.enqueueSendMoney(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          createdAt: DateTime.utc(2026, 9, 21, 10, 0),
          payload: SendMoneyPayload(
            recipientAccountNumber: '111',
            recipientName: 'First Person',
            bankName: 'Bank 1',
            amount: const Money.fromKobo(100000),
          ),
        );

        final op2 = await opRepo.enqueueSendMoney(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          createdAt: DateTime.utc(2026, 9, 21, 11, 0),
          payload: SendMoneyPayload(
            recipientAccountNumber: '222',
            recipientName: 'Second Person',
            bankName: 'Bank 2',
            amount: const Money.fromKobo(200000),
          ),
        );

        await coordinatorWithMonitor.synchronize();

        expect(processedOrder, [op1.id.value, op2.id.value]);
      },
    );

    test('coalesces concurrent synchronize calls and claims operations atomically (SYNC-010)', () async {
      await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      // Trigger two concurrent synchronize calls simultaneously
      final future1 = coordinator.synchronize();
      final future2 = coordinator.synchronize();

      final results = await Future.wait([future1, future2]);

      // Both futures resolve successfully
      expect(
        results[0].succeeded + results[1].succeeded,
        greaterThanOrEqualTo(1),
      );

      // Financial effect happened exactly once on remote
      expect(await remoteLedger.getBalance(), const Money.fromKobo(9000000));
      // Confirmed local balance debited exactly once
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9000000);
    });

    test(
      'skips remote execution when offline and maintains pending status',
      () async {
        connectivityService.setStatus(ConnectivityStatus.offline);

        final op = await opRepo.enqueueSendMoney(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Amina',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(1000000),
          ),
        );

        final result = await coordinator.synchronize();

        expect(result.totalClaimed, 0);
        expect(result.succeeded, 0);

        // Operation remains pending in local store
        final fromDb = await opRepo.getOperationById(op.id);
        expect(fromDb!.status, OperationStatus.pending);
        expect(fromDb.attemptCount, 0);
      },
    );

    test('reconnect triggers automatic synchronization (SYNC-004, ASM-011)', () async {
      // Start offline with auto-subscribe enabled
      final offlineConn = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
      final autoCoordinator = SyncCoordinator(
        operationRepository: opRepo,
        remoteApi: remoteApi,
        connectivityService: offlineConn,
        walletRepository: walletRepo,
        novaSaveRepository: goalRepo,
        autoSubscribeConnectivity: true,
      );
      addTearDown(autoCoordinator.dispose);
      addTearDown(offlineConn.dispose);

      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.pending,
      );

      // Transition to online
      offlineConn.setStatus(ConnectivityStatus.online);

      // Allow async reconnect stream subscription to trigger and complete sync
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final fromDb = await opRepo.getOperationById(op.id);
      expect(fromDb!.status, OperationStatus.completed);
      expect(fromDb.remoteReference, isNotNull);
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9000000);
    });

    test('recoverable network error retains operation in pending status with SyncError (SYNC-012)', () async {
      failureSimulator.failNext(SimulatedFailureType.transport);

      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      final result = await coordinator.synchronize();

      expect(result.recoverableFailures, 1);
      expect(result.succeeded, 0);
      expect(coordinator.status, SyncStatus.failed);

      final fromDb = await opRepo.getOperationById(op.id);
      expect(fromDb!.status, OperationStatus.pending);
      expect(fromDb.attemptCount, 1);
      expect(fromDb.lastError, isNotNull);
      expect(fromDb.lastError!.isRecoverable, isTrue);

      // Local confirmed wallet balance is NOT debited
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 10000000);
    });

    test('terminal rejection marks operation failed and releases reservation without blocking subsequent queue', () async {
      failureSimulator.failNext(SimulatedFailureType.businessRejection);

      final rejectedOp = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0000000000',
          recipientName: 'Closed Account',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      final validOp = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Valid Account',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );

      final result = await coordinator.synchronize();

      expect(result.terminalFailures, 1);
      expect(result.succeeded, 1);

      // First operation is terminally failed
      final rejectedDb = await opRepo.getOperationById(rejectedOp.id);
      expect(rejectedDb!.status, OperationStatus.failed);
      expect(rejectedDb.lastError!.isRecoverable, isFalse);

      // Second operation succeeded
      final validDb = await opRepo.getOperationById(validOp.id);
      expect(validDb!.status, OperationStatus.completed);

      // Wallet was only debited for the valid operation (₦5,000)
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9500000);
    });

    test('response-lost uncertainty recovers with exact-once effect on retry (SYNC-011, TST-007, HC-EXACTLY-ONCE-EFFECT)', () async {
      failureSimulator.failNext(SimulatedFailureType.responseLost);

      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      // First sync run: remote debits 10,000 and saves idempotency record, but response drops
      final run1 = await coordinator.synchronize();
      expect(run1.recoverableFailures, 1);
      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.pending,
      );

      // Remote balance was debited once
      expect(await remoteLedger.getBalance(), const Money.fromKobo(9000000));
      // Local confirmed balance was NOT yet debited because response dropped before persistence
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 10000000);

      // Second sync run: client replays the exact same operation with the same IdempotencyKey
      final run2 = await coordinator.synchronize();
      expect(run2.succeeded, 1);

      // Remote balance must NOT be debited a second time (HC-EXACTLY-ONCE-EFFECT)
      expect(await remoteLedger.getBalance(), const Money.fromKobo(9000000));

      // Local confirmed balance is now debited once
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9000000);
      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.completed,
      );
    });

    test('retryOperation retries a single operation directly', () async {
      failureSimulator.failNext(SimulatedFailureType.transport);

      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      await coordinator.synchronize();
      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.pending,
      );

      // Direct retry succeeds
      final retryResult = await coordinator.retryOperation(op.id);
      expect(retryResult.isSuccess, isTrue);
      expect(retryResult.status, RetryStatus.success);

      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.completed,
      );
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9000000);
    });

    test('startup recovers interrupted operations and triggers sync when online (ASM-012, SYNC-003, T-SYNC-003)', () async {
      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      // Claim operation to simulate in-flight processing state
      await opRepo.claim(op.id);
      expect(
        (await opRepo.getOperationById(op.id))!.status,
        OperationStatus.processing,
      );

      // Startup lifecycle triggers recovery and sync
      final syncResult = await coordinator.startup(triggerSyncIfOnline: true);
      expect(syncResult, isNotNull);
      expect(syncResult!.succeeded, 1);

      final completedOp = await opRepo.getOperationById(op.id);
      expect(completedOp!.status, OperationStatus.completed);
      expect((await walletRepo.getWalletSnapshot())!.balance.kobo, 9000000);
    });

    group(
      'Atomic Local Settlement & Idempotent Projection Guard (P0 Regression)',
      () {
        test('idempotent projection guard prevents duplicate debit and duplicate contribution when transaction already exists', () async {
          final op = await opRepo.enqueueContribution(
            id: OperationId('op-p0-guard'),
            idempotencyKey: IdempotencyKey('idem-p0-guard'),
            payload: ContributionPayload(
              goalId: 'goal-1',
              goalName: 'Tech Upgrade',
              amount: const Money.fromKobo(1000000), // ₦10,000.00
            ),
          );

          expect(
            (await walletRepo.getWalletSnapshot())!.balance.kobo,
            10000000,
          );
          expect((await goalRepo.getGoal('goal-1'))!.savedAmount.kobo, 0);

          // Simulate crash right before markCompleted
          await walletRepo.setWalletSnapshot(
            WalletSnapshot(
              balance: const Money.fromKobo(9000000),
              lastUpdatedAt: DateTime.utc(2026, 9, 21),
            ),
          );
          await walletRepo.saveTransaction(
            WalletTransaction(
              id: op.id.value,
              type: TransactionType.debit,
              amount: const Money.fromKobo(1000000),
              counterparty: 'Tech Upgrade',
              createdAt: DateTime.utc(2026, 9, 21),
              status: TransactionStatus.completed,
              reference: 'REMOTE-P0-REF',
              narration: 'NovaSave Contribution',
            ),
          );
          await goalRepo.applyContribution(
            'goal-1',
            const Money.fromKobo(1000000),
          );
          expect(
            (await opRepo.getOperationById(op.id))!.status,
            OperationStatus.pending,
          );

          // Reconnect/sync triggered
          final result = await coordinator.synchronize();
          expect(result.succeeded, 1);

          // Operation marked completed
          final completedOp = await opRepo.getOperationById(op.id);
          expect(completedOp!.status, OperationStatus.completed);

          // Wallet balance must NOT be debited twice
          final finalSnapshot = await walletRepo.getWalletSnapshot();
          expect(finalSnapshot!.balance.kobo, 9000000);

          // Goal progress must NOT be incremented twice
          final finalGoal = await goalRepo.getGoal('goal-1');
          expect(finalGoal!.savedAmount.kobo, 1000000);

          // Transaction table must have exactly 1 record
          final txns = await walletRepo.getRecentTransactions();
          expect(txns.length, 1);
        });

        test('projections and status transition occur within database transaction when appDatabase is provided', () async {
          final localCoordinator = SyncCoordinator(
            operationRepository: opRepo,
            remoteApi: remoteApi,
            connectivityService: connectivityService,
            walletRepository: walletRepo,
            novaSaveRepository: goalRepo,
            appDatabase: db,
            autoSubscribeConnectivity: false,
          );
          addTearDown(localCoordinator.dispose);

          final op = await opRepo.enqueueSendMoney(
            id: OperationId('op-p0-tx-test'),
            idempotencyKey: IdempotencyKey('idem-p0-tx-test'),
            payload: SendMoneyPayload(
              recipientAccountNumber: '0123456789',
              recipientName: 'Kemi Adebayo',
              bankName: 'GTBank',
              amount: const Money.fromKobo(2000000), // ₦20,000.00
            ),
          );

          final syncResult = await localCoordinator.synchronize();
          expect(syncResult.succeeded, 1);

          final completedOp = await opRepo.getOperationById(op.id);
          expect(completedOp!.status, OperationStatus.completed);

          final snapshot = await walletRepo.getWalletSnapshot();
          expect(snapshot!.balance.kobo, 8000000);

          final tx = await walletRepo.getTransactionById(op.id.value);
          expect(tx, isNotNull);
          expect(tx!.amount.kobo, 2000000);
        });
      },
    );
  });

  group('Sync Riverpod Wire-up (T-SYNC-002)', () {
    test('syncCoordinatorProvider, syncStatusProvider, and syncStatusStreamProvider function in container', () async {
      final inMemoryDb = AppDatabase.inMemory();
      final inMemoryConn = InMemoryConnectivityService();

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(inMemoryDb),
          connectivityServiceProvider.overrideWithValue(inMemoryConn),
        ],
      );

      addTearDown(() async {
        container.dispose();
        inMemoryConn.dispose();
        await inMemoryDb.close();
      });

      final coordinator = container.read(syncCoordinatorProvider);
      expect(coordinator, isA<SyncCoordinator>());
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });
  });
}

class _MonitoredRemoteApi implements RemoteApi {
  final RemoteApi _delegate;
  final void Function(FinancialOperation) onSendMoney;

  _MonitoredRemoteApi(this._delegate, {required this.onSendMoney});

  @override
  Future<RemoteOperationResult> sendMoney(FinancialOperation operation) {
    onSendMoney(operation);
    return _delegate.sendMoney(operation);
  }

  @override
  Future<RemoteOperationResult> contribute(FinancialOperation operation) =>
      _delegate.contribute(operation);

  @override
  Future<RemoteOperationResult> submitOperation(FinancialOperation operation) =>
      _delegate.submitOperation(operation);

  @override
  Future<WalletSnapshot> fetchWalletSnapshot() =>
      _delegate.fetchWalletSnapshot();

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  }) => _delegate.fetchTransactions(limit: limit, offset: offset);
}
