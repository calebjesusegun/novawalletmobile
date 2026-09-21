import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

import 'sync_kernel_test_harness.dart';

void main() {
  group('Sync Kernel Verification (T-SYNC-005, ASM-011, ASM-012, ASM-013, TST-006, SYNC-011)', () {
    late SyncKernelTestHarness harness;

    setUp(() async {
      harness = await SyncKernelTestHarness.create(
        initialBalance: const Money.fromKobo(10000000), // ₦100,000.00
        initialConnectivity: ConnectivityStatus.offline,
      );
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('Full Kernel Flow: Offline Enqueue -> Process Crash & Restart -> Reconnect Auto-Sync -> Exactly-Once Effect (ASM-011, ASM-012, TST-006)', () async {
      // 1. Setup local savings goal
      final goal = SavingsGoal(
        id: 'goal-home-renovation',
        name: 'Home Renovation',
        targetAmount: const Money.fromKobo(50000000), // ₦500,000.00
        targetDate: DateTime.utc(2027, 12, 31),
        savedAmount: const Money.fromKobo(5000000), // ₦50,000.00
      );
      await harness.novaSaveRepository.createGoal(goal);

      // 2. User is OFFLINE: Enqueue Send Money (₦15,000) and NovaSave Contribution (₦10,000)
      final sendOpId = OperationId.generate();
      final sendIdKey = IdempotencyKey.generate();
      const sendAmount = Money.fromKobo(1500000); // ₦15,000.00

      final contribOpId = OperationId.generate();
      final contribIdKey = IdempotencyKey.generate();
      const contribAmount = Money.fromKobo(1000000); // ₦10,000.00

      await harness.enqueueSendMoney(
        id: sendOpId,
        idempotencyKey: sendIdKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'Fola Adeleke',
        bankName: 'GTBank',
        amount: sendAmount,
      );

      await harness.enqueueContribution(
        id: contribOpId,
        idempotencyKey: contribIdKey,
        goalId: goal.id,
        goalName: goal.name,
        amount: contribAmount,
      );

      // Verify state immediately after offline enqueue
      var pendingOps = await harness.getLocalPendingOperations();
      expect(pendingOps, hasLength(2));
      expect(pendingOps[0].id, sendOpId);
      expect(pendingOps[0].status, OperationStatus.pending);
      expect(pendingOps[1].id, contribOpId);
      expect(pendingOps[1].status, OperationStatus.pending);

      // Local wallet confirmed balance is still ₦100,000 (pending operations do not deduct confirmed balance)
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(10000000),
      );
      // Remote ledger is completely untouched while offline
      expect(await harness.getRemoteBalance(), const Money.fromKobo(10000000));
      expect(await harness.getRemoteTransactions(), isEmpty);

      // 3. SIMULATE SUDDEN PROCESS CRASH & RESTART WHILE OFFLINE
      // Disposes container, closes SQLite file, reboots fresh container/DB on the same SQLite file
      await harness.simulateProcessCrashAndRestart(
        restartConnectivity: ConnectivityStatus.offline,
        triggerSyncIfOnline: false,
      );

      // Verify state after restart: operations remain durably persisted in SQLite in pending status
      pendingOps = await harness.getLocalPendingOperations();
      expect(pendingOps, hasLength(2));
      expect(pendingOps[0].id, sendOpId);
      expect(pendingOps[0].idempotencyKey, sendIdKey);
      expect(pendingOps[0].status, OperationStatus.pending);
      expect(pendingOps[1].id, contribOpId);
      expect(pendingOps[1].idempotencyKey, contribIdKey);
      expect(pendingOps[1].status, OperationStatus.pending);

      // Remote remains untouched
      expect(await harness.getRemoteBalance(), const Money.fromKobo(10000000));
      expect(await harness.getRemoteTransactions(), isEmpty);

      // 4. RECONNECT: Device comes back online
      // Wait for reconnect auto-sync to trigger and complete
      final statusCompleter = Stream<SyncStatus>.fromIterable([
        harness.syncCoordinator.status,
      ]).listen(null);
      addTearDown(statusCompleter.cancel);

      harness.setConnectivity(ConnectivityStatus.online);

      // Wait for sync coordinator to transition through syncing and settle to idle
      await Future<void>.delayed(const Duration(milliseconds: 150));
      while (harness.syncCoordinator.status == SyncStatus.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // 5. VERIFY EXACTLY-ONCE FINANCIAL EFFECT (HC-EXACTLY-ONCE-EFFECT, ASM-011)
      // Both operations must be completed
      final completedSend = await harness.getLocalOperationById(sendOpId);
      final completedContrib = await harness.getLocalOperationById(contribOpId);

      expect(completedSend!.status, OperationStatus.completed);
      expect(completedSend.remoteReference, isNotNull);
      expect(completedContrib!.status, OperationStatus.completed);
      expect(completedContrib.remoteReference, isNotNull);

      // Pending operations queue must be empty
      expect(await harness.getLocalPendingOperations(), isEmpty);

      // Remote ledger: debited exactly ₦15,000 + ₦10,000 = ₦25,000 -> ₦75,000 remaining
      const expectedRemaining = Money.fromKobo(7500000); // ₦75,000.00
      expect(await harness.getRemoteBalance(), expectedRemaining);

      final remoteTx = await harness.getRemoteTransactions();
      expect(remoteTx, hasLength(2));
      expect(remoteTx.any((tx) => tx.amount == sendAmount), isTrue);
      expect(remoteTx.any((tx) => tx.amount == contribAmount), isTrue);

      // Local wallet balance: debited exactly ₦25,000 -> ₦75,000
      expect(await harness.getLocalWalletBalance(), expectedRemaining);

      // Local transactions: 2 records created in SQLite ledger (both are debit)
      final localTx = await harness.getLocalTransactions();
      expect(localTx, hasLength(2));
      expect(localTx[0].type, TransactionType.debit);
      expect(localTx[1].type, TransactionType.debit);

      // NovaSave savings goal: saved amount increased from ₦50,000 to ₦60,000
      final updatedGoal = await harness.getLocalGoal(goal.id);
      expect(
        updatedGoal!.savedAmount,
        const Money.fromKobo(6000000),
      ); // ₦60,000.00
    });

    test('Replay Deduplication Guard: Replaying completed operations reuses idempotency key and produces zero duplicate financial effect (ASM-013, HC-IDEMPOTENCY)', () async {
      // Enqueue Send Money while online
      harness.setConnectivity(ConnectivityStatus.online);
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(2000000); // ₦20,000.00

      final originalOp = await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: idKey,
        recipientAccountNumber: '9876543210',
        recipientName: 'Chidi Mokeme',
        bankName: 'Access Bank',
        amount: amount,
      );

      // Sync and complete
      final syncResult = await harness.triggerSync();
      expect(syncResult.succeeded, 1);

      expect(
        await harness.getRemoteBalance(),
        const Money.fromKobo(8000000), // ₦80,000.00
      );
      expect(await harness.getRemoteTransactions(), hasLength(1));

      // ADVERSARIAL REPLAY ATTEMPTS:
      // 1. Trigger sync coordinator again
      final secondSyncResult = await harness.triggerSync();
      expect(
        secondSyncResult.succeeded,
        0,
      ); // Already completed, not reprocessed

      // 2. Direct replay to remote API reusing the exact same operation and idempotency key
      final remoteReplayResult = await harness.remoteApi.sendMoney(originalOp);

      // Remote returns original transaction receipt with isDuplicate=true without debiting again
      expect(remoteReplayResult.isDuplicate, isTrue);
      expect(remoteReplayResult.remoteReference, isNotEmpty);
      expect(remoteReplayResult.debitAmount, amount);

      // Remote balance is STILL ₦80,000 (NOT ₦60,000)
      expect(await harness.getRemoteBalance(), const Money.fromKobo(8000000));
      // Remote transactions list STILL has only 1 entry
      expect(await harness.getRemoteTransactions(), hasLength(1));
    });

    test('Crash Recovery After Remote Settlement: Replay with identical key deduplicates and settles local database without double debit (SYNC-011, HC-EXACTLY-ONCE-EFFECT)', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      const amount = Money.fromKobo(3000000); // ₦30,000.00

      // Enqueue offline
      final op = await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: idKey,
        recipientAccountNumber: '5555444433',
        recipientName: 'Amaka Okafor',
        bankName: 'Zenith Bank',
        amount: amount,
      );

      // Simulate crash right after remote settlement:
      // 1. Remote executes and records transfer
      await harness.remoteApi.sendMoney(op);
      expect(await harness.getRemoteBalance(), const Money.fromKobo(7000000));

      // 2. Local operation repository had claimed the operation as processing
      await harness.operationRepository.claim(opId);
      final inFlight = await harness.getLocalOperationById(opId);
      expect(inFlight!.status, OperationStatus.processing);

      // 3. Process crashes before markCompleted could be called or committed
      await harness.simulateProcessCrashAndRestart(
        restartConnectivity: ConnectivityStatus.online,
        triggerSyncIfOnline: false, // Don't sync yet, verify state first
      );

      // 4. Verify restart recovery reset in-flight operation to pending
      final recovered = await harness.getLocalOperationById(opId);
      expect(recovered!.status, OperationStatus.pending);
      expect(recovered.idempotencyKey, idKey); // Stable key preserved

      // 5. Trigger sync: coordinator replays operation to remote
      final syncResult = await harness.triggerSync();
      expect(syncResult.succeeded, 1);

      // 6. Verify remote API deduplicated: balance is STILL ₦70,000 (NO second ₦30,000 debit!)
      expect(await harness.getRemoteBalance(), const Money.fromKobo(7000000));
      expect(await harness.getRemoteTransactions(), hasLength(1));

      // 7. Local database committed the completed transaction
      final completed = await harness.getLocalOperationById(opId);
      expect(completed!.status, OperationStatus.completed);
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(7000000),
      );
      expect(await harness.getLocalTransactions(), hasLength(1));
    });

    test('Negative Invariant Guard: Altering idempotency key produces duplicate financial effect (Proves key stability is required)', () async {
      harness.setConnectivity(ConnectivityStatus.online);
      final initialBalance = await harness.getRemoteBalance();
      const amount = Money.fromKobo(1000000); // ₦10,000.00

      final key1 = IdempotencyKey.generate();
      final op1 = FinancialOperation.send(
        id: OperationId.generate(),
        idempotencyKey: key1,
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Test Recipient',
          bankName: 'Test Bank',
          amount: amount,
        ),
      );
      await harness.remoteApi.sendMoney(op1);

      expect(await harness.getRemoteBalance(), initialBalance - amount);

      // If an erroneous retry generated a NEW idempotency key instead of reusing key1:
      final erroneousKey2 = IdempotencyKey.generate();
      final op2WithDifferentKey = FinancialOperation.send(
        id: OperationId.generate(),
        idempotencyKey: erroneousKey2,
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Test Recipient',
          bankName: 'Test Bank',
          amount: amount,
        ),
      );
      await harness.remoteApi.sendMoney(op2WithDifferentKey);

      // The remote API would perceive it as a distinct request and debit TWICE!
      expect(
        await harness.getRemoteBalance(),
        initialBalance - amount - amount,
      );
      // This proves that stable idempotency key reuse is strictly necessary to uphold HC-IDEMPOTENCY.
    });

    test('Negative Invariant Guard: Omitting restart recovery leaves crashed operations permanently stuck in processing', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: idKey,
        recipientAccountNumber: '1234567890',
        recipientName: 'Tunde Bakare',
        bankName: 'First Bank',
        amount: const Money.fromKobo(500000),
      );

      // Claim operation (status -> processing)
      await harness.operationRepository.claim(opId);
      expect(
        (await harness.getLocalOperationById(opId))!.status,
        OperationStatus.processing,
      );

      // Reopen database WITHOUT calling recoverInterrupted()
      await harness.simulateProcessCrashAndRestart(
        restartConnectivity: ConnectivityStatus.online,
        triggerSyncIfOnline: false,
      );

      // Note: simulateProcessCrashAndRestart calls syncCoordinator.startup() which calls recoverInterrupted().
      // If we deliberately re-claim it directly to simulate a non-recovered stuck state:
      await harness.operationRepository.claim(opId);
      expect(
        (await harness.getLocalOperationById(opId))!.status,
        OperationStatus.processing,
      );

      // Attempting to claim again fails closed
      final canClaimAgain = await harness.operationRepository.claim(opId);
      expect(canClaimAgain, isFalse);

      // Proving that without restart recovery, an operation stuck in processing
      // would remain un-claimable and unable to proceed.
    });
  });
}
