import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/sync/application/sync_application.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

import 'kernel/sync_kernel_test_harness.dart';

void main() {
  group('T-TST-004 / TST-007: High-Value Sync Failure & Concurrency Matrix', () {
    late SyncKernelTestHarness harness;

    setUp(() async {
      harness = await SyncKernelTestHarness.create(
        initialBalance: const Money.fromKobo(10000000), // ₦100,000.00
        initialConnectivity: ConnectivityStatus.online,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    // =========================================================================
    // 1. REPEATED SAME-KEY DELIVERY (HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT)
    // =========================================================================
    test('Scenario 1: Repeated same-key delivery returns cached result without a second debit (HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT)', () async {
      final opId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(2000000); // ₦20,000.00

      // Enqueue and sync
      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: stableKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: amount,
      );

      final result1 = await harness.triggerSync();
      expect(result1.succeeded, 1);
      expect(result1.recoverableFailures, 0);
      expect(result1.terminalFailures, 0);

      // Remote balance debited once: ₦100,000 - ₦20,000 = ₦80,000
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8000000));
      final txs1 = await harness.getRemoteTransactions();
      expect(txs1, hasLength(1));

      // Directly deliver the exact same operation with the same key to the remote API
      final directReplayOp = FinancialOperation.create(
        id: opId,
        idempotencyKey: stableKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'John Doe',
          bankName: 'NovaBank',
          amount: amount,
        ),
      );

      final replayResult = await harness.remoteApi.sendMoney(directReplayOp);
      expect(replayResult.isDuplicate, isTrue);
      expect(replayResult.remoteReference, txs1.first.id);

      // Assert strictly zero secondary financial effect
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8000000));
      expect(await harness.getRemoteTransactions(), hasLength(1));
    });

    // =========================================================================
    // 2. CONFLICTING SAME-KEY PAYLOAD (SYNC-012, HC-IDEMPOTENCY)
    // =========================================================================
    test('Scenario 2: Repeated key with conflicting payload is rejected with ConflictingIdempotencyKeyException and zero financial mutation (SYNC-012)', () async {
      final originalOpId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const originalAmount = Money.fromKobo(1500000); // ₦15,000.00

      // First submission succeeds
      await harness.enqueueSendMoney(
        id: originalOpId,
        idempotencyKey: stableKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: originalAmount,
      );
      await harness.triggerSync();

      expect(await harness.getRemoteBalance(), const Money.fromKobo(8500000));

      // Second submission attempts to reuse the SAME key with conflicting payload (₦30,000 instead of ₦15,000)
      final conflictingOp = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: stableKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'John Doe',
          bankName: 'NovaBank',
          amount: const Money.fromKobo(3000000), // ₦30,000.00 != ₦15,000.00
        ),
      );

      expect(
        () => harness.remoteApi.sendMoney(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );

      // Remote ledger is completely untouched: balance is STILL ₦85,000.00
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8500000));
      expect(await harness.getRemoteTransactions(), hasLength(1));
    });

    // =========================================================================
    // 3. CONCURRENT SYNC TRIGGERS (SYNC-013, HC-SYNC)
    // =========================================================================
    test('Scenario 3: Concurrent sync triggers are serialized by coordinator mutex without duplicate delivery (SYNC-013, HC-SYNC)', () async {
      final op1 = await harness.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: const Money.fromKobo(1000000), // ₦10,000.00
      );

      final op2 = await harness.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        recipientAccountNumber: '0987654321',
        recipientName: 'Jane Smith',
        bankName: 'FirstBank',
        amount: const Money.fromKobo(1500000), // ₦15,000.00
      );

      // Trigger 5 concurrent sync invocations simultaneously
      final syncFutures = [
        harness.triggerSync(trigger: SyncTrigger.reconnect),
        harness.triggerSync(trigger: SyncTrigger.userRetry),
        harness.triggerSync(trigger: SyncTrigger.manual),
        harness.triggerSync(trigger: SyncTrigger.reconnect),
        harness.triggerSync(trigger: SyncTrigger.startup),
      ];

      final results = await Future.wait(syncFutures);

      // All 5 concurrent callers receive the same coalesced sync result
      expect(results, hasLength(5));
      for (final r in results) {
        expect(r.succeeded, 2);
        expect(r.recoverableFailures, 0);
        expect(r.terminalFailures, 0);
      }

      // Both operations are now marked completed
      final op1After = await harness.getLocalOperationById(op1.id);
      final op2After = await harness.getLocalOperationById(op2.id);
      expect(op1After?.status, OperationStatus.completed);
      expect(op2After?.status, OperationStatus.completed);

      // Remote balance: ₦100,000 - ₦10,000 - ₦15,000 = ₦75,000 (NO duplicate debits!)
      expect(await harness.getRemoteBalance(), const Money.fromKobo(7500000));
      expect(await harness.getRemoteTransactions(), hasLength(2));
    });

    // =========================================================================
    // 4. RESPONSE LOST AFTER REMOTE SUCCESS (SYNC-010, TST-007, HC-EXACTLY-ONCE-EFFECT)
    // =========================================================================
    test('Scenario 4: Response lost after remote execution retains operation in pending queue and settles cleanly on retry without duplicate deduction (SYNC-010, TST-007)', () async {
      final opId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(2500000); // ₦25,000.00

      // Inject simulated response-lost error: remote processes debit and records idempotency key,
      // but transport throws RemoteResponseLostException before client receives response
      harness.failureSimulator.failNext(SimulatedFailureType.responseLost);

      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: stableKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: amount,
      );

      // First sync attempt: fails with recoverable error
      final firstRun = await harness.triggerSync();
      expect(firstRun.succeeded, 0);
      expect(firstRun.recoverableFailures, 1);

      // Operation remains durable in local SQLite with error metadata
      final pendingAfterLost = await harness.getLocalPendingOperations();
      expect(pendingAfterLost, hasLength(1));
      expect(pendingAfterLost.first.id, opId);
      expect(pendingAfterLost.first.status, OperationStatus.pending);
      expect(pendingAfterLost.first.lastError, isNotNull);
      expect(pendingAfterLost.first.lastError!.isRecoverable, isTrue);

      // On remote side, the transfer was accepted and recorded: balance is ₦75,000.00
      expect(await harness.getRemoteBalance(), const Money.fromKobo(7500000));

      // User or system retries synchronization reusing the same stable idempotency key
      final retryRun = await harness.triggerSync(
        trigger: SyncTrigger.userRetry,
      );
      expect(retryRun.succeeded, 1);
      expect(retryRun.recoverableFailures, 0);

      // Operation completed!
      final completedOp = await harness.getLocalOperationById(opId);
      expect(completedOp?.status, OperationStatus.completed);
      expect(completedOp?.remoteReference, isNotNull);

      // Pending queue is now empty
      expect(await harness.getLocalPendingOperations(), isEmpty);

      // CRITICAL HC-EXACTLY-ONCE-EFFECT: Remote balance is STILL ₦75,000.00 (NOT debited twice to ₦50,000.00!)
      expect(await harness.getRemoteBalance(), const Money.fromKobo(7500000));
      expect(await harness.getRemoteTransactions(), hasLength(1));

      // Local wallet balance snapshot matches remote
      await harness.walletRepository.refresh();
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(7500000),
      );
    });

    // =========================================================================
    // 5. APP INTERRUPTION BEFORE LOCAL COMPLETION (SYNC-011, HC-OFFLINE-DURABILITY)
    // =========================================================================
    test('Scenario 5: Process crash before local completion recovers on reboot and reconciles safely (SYNC-011, HC-OFFLINE-DURABILITY)', () async {
      final opId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(1200000); // ₦12,000.00

      // Fail first attempt with responseLost to simulate interruption after remote acceptance
      harness.failureSimulator.failNext(SimulatedFailureType.responseLost);

      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: stableKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: amount,
      );

      await harness.triggerSync();

      // Process killed abruptly while offline!
      await harness.simulateProcessCrashAndRestart(
        restartConnectivity: ConnectivityStatus.offline,
        triggerSyncIfOnline: false,
      );

      // On restart: pending operation survived intact in SQLite
      final recoveredPending = await harness.getLocalPendingOperations();
      expect(recoveredPending, hasLength(1));
      expect(recoveredPending.first.id, opId);
      expect(recoveredPending.first.idempotencyKey, stableKey);

      // Now reconnect and synchronize
      harness.setConnectivity(ConnectivityStatus.online);
      final postRestartSync = await harness.triggerSync(
        trigger: SyncTrigger.reconnect,
      );
      expect(postRestartSync.succeeded, 1);

      // Operation transitioned to completed
      final completedAfterRestart = await harness.getLocalOperationById(opId);
      expect(completedAfterRestart?.status, OperationStatus.completed);

      // Remote balance: debited exactly once (₦100,000 - ₦12,000 = ₦88,000)
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8800000));
      expect(await harness.getRemoteTransactions(), hasLength(1));
    });

    // =========================================================================
    // 6. MANUAL RETRY AFTER TRANSIENT TRANSPORT FAILURE (HC-RETRY, MNY-004)
    // =========================================================================
    test('Scenario 6: Manual retry after transient network failure succeeds and releases reservation (HC-RETRY, MNY-004)', () async {
      final opId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(1800000); // ₦18,000.00

      // Fail once with network transport error
      harness.failureSimulator.failNext(SimulatedFailureType.transport);

      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: stableKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'John Doe',
        bankName: 'NovaBank',
        amount: amount,
      );

      // First attempt fails
      final firstRun = await harness.triggerSync();
      expect(firstRun.recoverableFailures, 1);
      expect(harness.syncCoordinator.status, SyncStatus.failed);

      // Pending operation retained in SQLite with recoverable flag
      final pendingOp = await harness.getLocalOperationById(opId);
      expect(pendingOp?.status, OperationStatus.pending);
      expect(pendingOp?.lastError?.isRecoverable, isTrue);

      // Remote untouched
      expect(await harness.getRemoteBalance(), const Money.fromKobo(10000000));
      expect(await harness.getRemoteTransactions(), isEmpty);

      // User taps Retry
      final retryResult = await harness.triggerSync(
        trigger: SyncTrigger.userRetry,
      );
      expect(retryResult.succeeded, 1);
      expect(harness.syncCoordinator.status, SyncStatus.idle);

      // Operation marked completed
      final opAfterRetry = await harness.getLocalOperationById(opId);
      expect(opAfterRetry?.status, OperationStatus.completed);

      // Remote balance settled
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8200000));
      expect(await harness.getRemoteTransactions(), hasLength(1));
    });

    // =========================================================================
    // 7. TRANSIENT SERVER 500 RETAINING USER INTENT (SYNC-012, HC-OFFLINE-DURABILITY)
    // =========================================================================
    test('Scenario 7: Transient remote 500 server error retains intent in SQLite without advancing goal prematurely (SYNC-012, HC-OFFLINE-DURABILITY)', () async {
      // Setup a savings goal
      final goal = SavingsGoal(
        id: 'goal-vacation',
        name: 'Summer Vacation',
        targetAmount: const Money.fromKobo(20000000), // ₦200,000.00
        targetDate: DateTime.utc(2028, 6, 1),
        savedAmount: const Money.fromKobo(3000000), // ₦30,000.00
      );
      await harness.novaSaveRepository.createGoal(goal);

      final opId = OperationId.generate();
      final stableKey = IdempotencyKey.generate();
      const contribAmount = Money.fromKobo(5000000); // ₦50,000.00

      // Fail once with remote 500
      harness.failureSimulator.failNext(SimulatedFailureType.serverError);

      await harness.enqueueContribution(
        id: opId,
        idempotencyKey: stableKey,
        goalId: goal.id,
        goalName: goal.name,
        amount: contribAmount,
      );

      // Sync triggers and fails
      final firstRun = await harness.triggerSync();
      expect(firstRun.recoverableFailures, 1);

      // Goal saved amount is NOT incremented prematurely!
      final goalBeforeRetry = await harness.getLocalGoal(goal.id);
      expect(goalBeforeRetry?.savedAmount, const Money.fromKobo(3000000));

      // Operation is NOT discarded: remains pending with SERVER_ERROR code
      final opAfterFail = await harness.getLocalOperationById(opId);
      expect(opAfterFail?.status, OperationStatus.pending);
      expect(opAfterFail?.lastError?.code, 'SERVER_ERROR');

      // Subsequent retry succeeds
      final retryRun = await harness.triggerSync(
        trigger: SyncTrigger.userRetry,
      );
      expect(retryRun.succeeded, 1);

      // Goal saved amount now advances to ₦80,000.00
      final goalAfterSuccess = await harness.getLocalGoal(goal.id);
      expect(goalAfterSuccess?.savedAmount, const Money.fromKobo(8000000));

      // Remote balance settled
      expect(await harness.getRemoteBalance(), const Money.fromKobo(5000000));
    });
  });
}
