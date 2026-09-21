import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/features/novasave/data/local_novasave_repository.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/sync/application/sync_application.dart';
import 'package:novawallet/sync/data/local_operation_repository.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  group('Restart Recovery (ASM-012, ASM-013, SYNC-003, SYNC-011, SND-016, NSV-019, T-SYNC-003)', () {
    late Directory tempDir;
    late File dbFile;
    late InMemoryRemoteLedger remoteLedger;
    late FailureSimulator failureSimulator;
    late FakeRemoteApi remoteApi;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync(
        'novawallet_restart_recovery_test_',
      );
      dbFile = File('${tempDir.path}/app_storage.db');

      remoteLedger = InMemoryRemoteLedger();
      // Initial remote balance: ₦100,000 (10,000,000 kobo)
      await remoteLedger.setBalance(const Money.fromKobo(10000000));
      failureSimulator = FailureSimulator();
      remoteApi = FakeRemoteApi(
        ledger: remoteLedger,
        failureSimulator: failureSimulator,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('queued operations survive process termination and resume sync after restart (ASM-012, SYNC-003, SND-016, NSV-019)', () async {
      final sendOpId = OperationId.generate();
      final sendIdKey = IdempotencyKey.generate();
      final contribOpId = OperationId.generate();
      final contribIdKey = IdempotencyKey.generate();

      // ==========================================
      // PROCESS LIFECYCLE 1: User is offline, enqueues Send & Contribution, then closes app
      // ==========================================
      {
        final db1 = AppDatabase.forFile(dbFile);
        final opRepo1 = LocalOperationRepository(PendingOperationsDao(db1));
        final walletRepo1 = LocalWalletRepository(
          walletDao: WalletDao(db1),
          transactionDao: TransactionDao(db1),
        );
        final goalRepo1 = LocalNovaSaveRepository(
          savingsGoalDao: SavingsGoalDao(db1),
        );
        final conn1 = InMemoryConnectivityService(
          initialStatus: ConnectivityStatus.offline,
        );
        final coordinator1 = SyncCoordinator(
          operationRepository: opRepo1,
          remoteApi: remoteApi,
          connectivityService: conn1,
          walletRepository: walletRepo1,
          novaSaveRepository: goalRepo1,
          autoSubscribeConnectivity: false,
        );

        // Initialize local wallet balance ₦100,000 and savings goal
        await walletRepo1.setWalletSnapshot(
          WalletSnapshot(balance: const Money.fromKobo(10000000)),
        );
        await goalRepo1.createGoal(
          SavingsGoal(
            id: 'goal-emergency',
            name: 'Emergency Fund',
            targetAmount: const Money.fromKobo(5000000), // ₦50,000
            targetDate: DateTime.utc(2027, 6, 1),
            savedAmount: const Money.zero(),
          ),
        );

        // Enqueue Send Money (₦12,000 = 1,200,000 kobo)
        await opRepo1.enqueueSendMoney(
          id: sendOpId,
          idempotencyKey: sendIdKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Kemi Adebayo',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(1200000),
          ),
        );

        // Enqueue NovaSave Contribution (₦8,000 = 800,000 kobo)
        await opRepo1.enqueueContribution(
          id: contribOpId,
          idempotencyKey: contribIdKey,
          payload: ContributionPayload(
            goalId: 'goal-emergency',
            goalName: 'Emergency Fund',
            amount: const Money.fromKobo(800000),
          ),
        );

        // Verify operations are pending in database before termination
        expect(
          (await opRepo1.getPendingOperations()).length,
          2,
          reason: 'Both operations should be saved durably',
        );

        // Simulate app termination / process death
        coordinator1.dispose();
        conn1.dispose();
        await db1.close();
      }

      // ==========================================
      // PROCESS LIFECYCLE 2: App starts up fresh, reopens database, recovers and syncs
      // ==========================================
      {
        final db2 = AppDatabase.forFile(dbFile);
        final opRepo2 = LocalOperationRepository(PendingOperationsDao(db2));
        final walletRepo2 = LocalWalletRepository(
          walletDao: WalletDao(db2),
          transactionDao: TransactionDao(db2),
        );
        final goalRepo2 = LocalNovaSaveRepository(
          savingsGoalDao: SavingsGoalDao(db2),
        );
        final conn2 = InMemoryConnectivityService(
          initialStatus: ConnectivityStatus.online,
        );
        final coordinator2 = SyncCoordinator(
          operationRepository: opRepo2,
          remoteApi: remoteApi,
          connectivityService: conn2,
          walletRepository: walletRepo2,
          novaSaveRepository: goalRepo2,
          autoSubscribeConnectivity: false,
        );

        // 1. Verify that pending operations survived restart with exact identities and amounts
        final restoredOps = await opRepo2.getPendingOperations();
        expect(restoredOps.length, 2);

        final restoredSend = await opRepo2.getOperationById(sendOpId);
        expect(restoredSend, isNotNull);
        expect(restoredSend!.status, OperationStatus.pending);
        expect(restoredSend.idempotencyKey, sendIdKey);
        expect(restoredSend.payload.amount.kobo, 1200000);

        final restoredContrib = await opRepo2.getOperationById(contribOpId);
        expect(restoredContrib, isNotNull);
        expect(restoredContrib!.status, OperationStatus.pending);
        expect(restoredContrib.idempotencyKey, contribIdKey);
        expect(restoredContrib.payload.amount.kobo, 800000);

        // 2. Run startup recovery and sync
        final syncResult = await coordinator2.startup(
          triggerSyncIfOnline: true,
        );
        expect(syncResult, isNotNull);
        expect(syncResult!.totalDiscovered, 2);
        expect(syncResult.succeeded, 2);

        // 3. Verify operations are marked completed
        final completedSend = await opRepo2.getOperationById(sendOpId);
        expect(completedSend!.status, OperationStatus.completed);
        expect(completedSend.remoteReference, isNotNull);

        final completedContrib = await opRepo2.getOperationById(contribOpId);
        expect(completedContrib!.status, OperationStatus.completed);
        expect(completedContrib.remoteReference, isNotNull);

        // 4. Verify local wallet confirmed balance: ₦100,000 - ₦12,000 - ₦8,000 = ₦80,000 (8,000,000 kobo)
        final wallet = await walletRepo2.getWalletSnapshot();
        expect(wallet!.balance.kobo, 8000000);

        // 5. Verify local transactions ledger
        final txs = await walletRepo2.getRecentTransactions();
        expect(txs.length, 2);
        expect(
          txs.any(
            (tx) =>
                tx.type == TransactionType.debit &&
                tx.counterparty == 'Kemi Adebayo' &&
                tx.amount.kobo == 1200000,
          ),
          isTrue,
        );
        expect(
          txs.any(
            (tx) =>
                tx.type == TransactionType.debit &&
                tx.counterparty == 'Emergency Fund' &&
                tx.amount.kobo == 800000,
          ),
          isTrue,
        );

        // 6. Verify savings goal progress updated
        final goal = await goalRepo2.getGoal('goal-emergency');
        expect(goal!.savedAmount.kobo, 800000);

        // 7. Verify remote balance debited exactly once
        expect(await remoteLedger.getBalance(), const Money.fromKobo(8000000));

        coordinator2.dispose();
        conn2.dispose();
        await db2.close();
      }
    });

    test('interrupted processing state is safely recovered to pending on startup (ASM-012, ASM-013, SYNC-003)', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();

      // ==========================================
      // PROCESS LIFECYCLE 1: Operation gets claimed (status = processing), then app crashes
      // ==========================================
      {
        final db1 = AppDatabase.forFile(dbFile);
        final opRepo1 = LocalOperationRepository(PendingOperationsDao(db1));

        await opRepo1.enqueueSendMoney(
          id: opId,
          idempotencyKey: idKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0987654321',
            recipientName: 'Abiola Johnson',
            bankName: 'UBA',
            amount: const Money.fromKobo(500000), // ₦5,000
          ),
        );

        // Atomic claim sets status to processing and attemptCount to 1
        final claimed = await opRepo1.claim(opId);
        expect(claimed, isTrue);

        final processingOp = await opRepo1.getOperationById(opId);
        expect(processingOp!.status, OperationStatus.processing);
        expect(processingOp.attemptCount, 1);

        // CRASH! App process dies abruptly while operation was in-flight
        await db1.close();
      }

      // ==========================================
      // PROCESS LIFECYCLE 2: App restarts fresh, invokes startup() recovery
      // ==========================================
      {
        final db2 = AppDatabase.forFile(dbFile);
        final opRepo2 = LocalOperationRepository(PendingOperationsDao(db2));
        final walletRepo2 = LocalWalletRepository(
          walletDao: WalletDao(db2),
          transactionDao: TransactionDao(db2),
        );
        await walletRepo2.setWalletSnapshot(
          WalletSnapshot(balance: const Money.fromKobo(10000000)),
        );
        final goalRepo2 = LocalNovaSaveRepository(
          savingsGoalDao: SavingsGoalDao(db2),
        );
        final conn2 = InMemoryConnectivityService(
          initialStatus: ConnectivityStatus.online,
        );
        final coordinator2 = SyncCoordinator(
          operationRepository: opRepo2,
          remoteApi: remoteApi,
          connectivityService: conn2,
          walletRepository: walletRepo2,
          novaSaveRepository: goalRepo2,
          autoSubscribeConnectivity: false,
        );

        // Before recovery, the row is stuck in processing in database
        final stuckOp = await opRepo2.getOperationById(opId);
        expect(stuckOp!.status, OperationStatus.processing);

        // Run startup recovery
        final recoveredCount = await coordinator2.recoverInterrupted();
        expect(recoveredCount, 1);

        // Verify stuck operation is reset back to pending with preserved attemptCount and key
        final recoveredOp = await opRepo2.getOperationById(opId);
        expect(recoveredOp!.status, OperationStatus.pending);
        expect(recoveredOp.attemptCount, 1);
        expect(recoveredOp.idempotencyKey, idKey);

        // Now synchronize and verify it completes cleanly
        final syncResult = await coordinator2.synchronize();
        expect(syncResult.succeeded, 1);

        final completedOp = await opRepo2.getOperationById(opId);
        expect(completedOp!.status, OperationStatus.completed);
        expect(completedOp.attemptCount, 2); // second attempt succeeded
        expect(completedOp.remoteReference, isNotNull);

        coordinator2.dispose();
        conn2.dispose();
        await db2.close();
      }
    });

    test('app interruption after remote success but before local completion guarantees exactly-once effect on recovery replay (SYNC-011, HC-EXACTLY-ONCE-EFFECT)', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();

      // ==========================================
      // PROCESS LIFECYCLE 1:
      // Remote API executes Send Money and debits remote balance,
      // but app process is killed BEFORE local markCompleted / wallet update is committed.
      // ==========================================
      {
        final db1 = AppDatabase.forFile(dbFile);
        final opRepo1 = LocalOperationRepository(PendingOperationsDao(db1));
        final walletRepo1 = LocalWalletRepository(
          walletDao: WalletDao(db1),
          transactionDao: TransactionDao(db1),
        );
        await walletRepo1.setWalletSnapshot(
          WalletSnapshot(balance: const Money.fromKobo(10000000)), // ₦100,000
        );

        final op = await opRepo1.enqueueSendMoney(
          id: opId,
          idempotencyKey: idKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Amina',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(2000000), // ₦20,000
          ),
        );

        // Claim operation
        await opRepo1.claim(opId);

        // Remote call succeeds and debits remote balance: 10,000,000 -> 8,000,000
        final remoteResult = await remoteApi.sendMoney(op);
        expect(remoteResult.remoteReference, isNotEmpty);
        expect(await remoteLedger.getBalance(), const Money.fromKobo(8000000));

        // SIMULATE CRASH: Process is killed here!
        // Local markCompleted was never called, local wallet snapshot was not debited!
        await db1.close();
      }

      // Verify remote balance was debited once
      expect(await remoteLedger.getBalance(), const Money.fromKobo(8000000));

      // ==========================================
      // PROCESS LIFECYCLE 2:
      // App restarts, recovers stuck processing operation, and replays sync.
      // Remote API must deduplicate by idempotency key (HC-EXACTLY-ONCE-EFFECT).
      // ==========================================
      {
        final db2 = AppDatabase.forFile(dbFile);
        final opRepo2 = LocalOperationRepository(PendingOperationsDao(db2));
        final walletRepo2 = LocalWalletRepository(
          walletDao: WalletDao(db2),
          transactionDao: TransactionDao(db2),
        );
        final goalRepo2 = LocalNovaSaveRepository(
          savingsGoalDao: SavingsGoalDao(db2),
        );
        final conn2 = InMemoryConnectivityService(
          initialStatus: ConnectivityStatus.online,
        );
        final coordinator2 = SyncCoordinator(
          operationRepository: opRepo2,
          remoteApi: remoteApi,
          connectivityService: conn2,
          walletRepository: walletRepo2,
          novaSaveRepository: goalRepo2,
          autoSubscribeConnectivity: false,
        );

        // Startup recovery resets the operation from processing -> pending
        final syncResult = await coordinator2.startup(
          triggerSyncIfOnline: true,
        );
        expect(syncResult, isNotNull);
        expect(syncResult!.succeeded, 1);

        // CRUCIAL INVARIANT: Remote balance MUST NOT be debited a second time!
        // 8,000,000 kobo (₦80,000), NOT 6,000,000 kobo (₦60,000)
        expect(
          await remoteLedger.getBalance(),
          const Money.fromKobo(8000000),
          reason: 'Remote balance must remain exactly 8,000,000 kobo (deduplicated by idempotency key)',
        );

        // Local wallet is now properly debited
        final wallet = await walletRepo2.getWalletSnapshot();
        expect(wallet!.balance.kobo, 8000000);

        // Local operation is marked completed
        final completedOp = await opRepo2.getOperationById(opId);
        expect(completedOp!.status, OperationStatus.completed);

        // Transaction ledger contains confirmed transaction
        final txs = await walletRepo2.getRecentTransactions();
        expect(txs.length, 1);
        expect(txs.first.amount.kobo, 2000000);

        coordinator2.dispose();
        conn2.dispose();
        await db2.close();
      }
    });

    test('mixed queue state restart leaves completed and failed immutable while processing pending in FIFO order', () async {
      final completedOpId = OperationId.generate();
      final failedOpId = OperationId.generate();
      final pendingOpId = OperationId.generate();
      final processingOpId = OperationId.generate();

      // ==========================================
      // PROCESS LIFECYCLE 1: Prepare database with 4 distinct operations
      // ==========================================
      {
        final db1 = AppDatabase.forFile(dbFile);
        final opRepo1 = LocalOperationRepository(PendingOperationsDao(db1));

        // 1. Completed op
        await opRepo1.enqueueSendMoney(
          id: completedOpId,
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '111',
            recipientName: 'Completed User',
            bankName: 'Bank A',
            amount: const Money.fromKobo(100000),
          ),
        );
        await opRepo1.claim(completedOpId);
        await opRepo1.markCompleted(
          completedOpId,
          remoteReference: 'REF-COMPLETED-1',
        );

        // 2. Terminally failed op
        await opRepo1.enqueueSendMoney(
          id: failedOpId,
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '222',
            recipientName: 'Failed User',
            bankName: 'Bank B',
            amount: const Money.fromKobo(200000),
          ),
        );
        await opRepo1.claim(failedOpId);
        await opRepo1.markFailed(
          failedOpId,
          error: SyncError.terminal(message: 'Invalid account number'),
        );

        // 3. Pending op
        await opRepo1.enqueueSendMoney(
          id: pendingOpId,
          idempotencyKey: IdempotencyKey.generate(),
          createdAt: DateTime.utc(2026, 9, 21, 12, 0),
          payload: SendMoneyPayload(
            recipientAccountNumber: '333',
            recipientName: 'Pending User',
            bankName: 'Bank C',
            amount: const Money.fromKobo(300000),
          ),
        );

        // 4. Processing op (interrupted)
        await opRepo1.enqueueSendMoney(
          id: processingOpId,
          idempotencyKey: IdempotencyKey.generate(),
          createdAt: DateTime.utc(2026, 9, 21, 11, 0), // older than pendingOpId
          payload: SendMoneyPayload(
            recipientAccountNumber: '444',
            recipientName: 'Processing User',
            bankName: 'Bank D',
            amount: const Money.fromKobo(400000),
          ),
        );
        await opRepo1.claim(processingOpId);

        await db1.close();
      }

      // ==========================================
      // PROCESS LIFECYCLE 2: Restart, run startup recovery, verify immutability & FIFO sync
      // ==========================================
      {
        final db2 = AppDatabase.forFile(dbFile);
        final opRepo2 = LocalOperationRepository(PendingOperationsDao(db2));
        final walletRepo2 = LocalWalletRepository(
          walletDao: WalletDao(db2),
          transactionDao: TransactionDao(db2),
        );
        await walletRepo2.setWalletSnapshot(
          WalletSnapshot(balance: const Money.fromKobo(10000000)),
        );
        final goalRepo2 = LocalNovaSaveRepository(
          savingsGoalDao: SavingsGoalDao(db2),
        );
        final conn2 = InMemoryConnectivityService(
          initialStatus: ConnectivityStatus.online,
        );
        final coordinator2 = SyncCoordinator(
          operationRepository: opRepo2,
          remoteApi: remoteApi,
          connectivityService: conn2,
          walletRepository: walletRepo2,
          novaSaveRepository: goalRepo2,
          autoSubscribeConnectivity: false,
        );

        // Run startup recovery
        final recoveredCount = await coordinator2.recoverInterrupted();
        expect(recoveredCount, 1, reason: 'Only processingOpId is recovered');

        // Completed op is completely untouched
        final completedAfter = await opRepo2.getOperationById(completedOpId);
        expect(completedAfter!.status, OperationStatus.completed);
        expect(completedAfter.remoteReference, 'REF-COMPLETED-1');

        // Failed op is completely untouched
        final failedAfter = await opRepo2.getOperationById(failedOpId);
        expect(failedAfter!.status, OperationStatus.failed);
        expect(failedAfter.lastError!.message, 'Invalid account number');

        // Processing op was recovered to pending
        final recoveredAfter = await opRepo2.getOperationById(processingOpId);
        expect(recoveredAfter!.status, OperationStatus.pending);

        // Pending op remains pending
        final pendingAfter = await opRepo2.getOperationById(pendingOpId);
        expect(pendingAfter!.status, OperationStatus.pending);

        // Synchronize: both recovered and pending operations sync in FIFO order
        // processingOpId (11:00 UTC) runs before pendingOpId (12:00 UTC)
        final syncResult = await coordinator2.synchronize();
        expect(syncResult.succeeded, 2);

        expect(
          (await opRepo2.getOperationById(processingOpId))!.status,
          OperationStatus.completed,
        );
        expect(
          (await opRepo2.getOperationById(pendingOpId))!.status,
          OperationStatus.completed,
        );

        coordinator2.dispose();
        conn2.dispose();
        await db2.close();
      }
    });
  });
}
