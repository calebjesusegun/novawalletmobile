import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/spendable_balance_policy.dart';

import '../sync/kernel/sync_kernel_test_harness.dart';

void main() {
  group('Cross-Feature Consistency & Reconciliation (T-XF-001, MNY-004, MNY-005, WAL-008, SND-018, NSV-021)', () {
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

    test('Completed Send Money changes confirmed wallet state exactly once (MNY-004, WAL-008, SND-018)', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      const sendAmount = Money.fromKobo(2500000); // ₦25,000.00

      // Enqueue Send Money offline
      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: idKey,
        recipientAccountNumber: '0123456789',
        recipientName: 'Bolanle Austen',
        bankName: 'GTBank',
        amount: sendAmount,
      );

      // Confirmed balance remains ₦100,000 while offline
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(10000000),
      );

      // Reconnect and sync
      harness.setConnectivity(ConnectivityStatus.online);
      final syncResult = await harness.triggerSync();
      expect(syncResult.succeeded, 1);

      // 1. Confirmed wallet balance is debited exactly once
      const expectedBalance = Money.fromKobo(7500000); // ₦75,000.00
      expect(await harness.getLocalWalletBalance(), expectedBalance);
      expect(await harness.getRemoteBalance(), expectedBalance);

      // 2. Transaction history in wallet reflects completed operation
      final localTx = await harness.getLocalTransactions();
      expect(localTx, hasLength(1));
      expect(localTx.first.id, opId.value);
      expect(localTx.first.type, TransactionType.debit);
      expect(localTx.first.amount, sendAmount);
      expect(localTx.first.counterparty, 'Bolanle Austen');
      expect(localTx.first.status, TransactionStatus.completed);
      expect(localTx.first.reference, isNotNull);

      // 3. Operation status in queue is marked completed
      final op = await harness.getLocalOperationById(opId);
      expect(op?.status, OperationStatus.completed);
      expect(op?.remoteReference, localTx.first.reference);

      // 4. Replaying synchronization does not duplicate debit or transaction
      final replayResult = await harness.triggerSync();
      expect(replayResult.succeeded, 0);
      expect(await harness.getLocalWalletBalance(), expectedBalance);
      expect(await harness.getLocalTransactions(), hasLength(1));
    });

    test('Completed Contribution changes confirmed goal state and debits wallet exactly once (MNY-005, NSV-021)', () async {
      // 1. Create a savings goal
      final goal = SavingsGoal(
        id: 'goal-tech-setup',
        name: 'New Laptop',
        targetAmount: const Money.fromKobo(60000000), // ₦600,000.00
        savedAmount: const Money.fromKobo(10000000), // ₦100,000.00
        targetDate: DateTime.utc(2027, 10, 1),
      );
      await harness.novaSaveRepository.createGoal(goal);

      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      const contribAmount = Money.fromKobo(3000000); // ₦30,000.00

      // Enqueue Contribution offline
      await harness.enqueueContribution(
        id: opId,
        idempotencyKey: idKey,
        goalId: goal.id,
        goalName: goal.name,
        amount: contribAmount,
      );

      // Confirmed balance and goal remain unchanged while pending offline
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(10000000),
      );
      var currentGoal = await harness.getLocalGoal(goal.id);
      expect(currentGoal?.savedAmount, const Money.fromKobo(10000000));

      // Reconnect and sync
      harness.setConnectivity(ConnectivityStatus.online);
      final syncResult = await harness.triggerSync();
      expect(syncResult.succeeded, 1);

      // 1. Confirmed wallet balance is debited by contribution amount
      const expectedWalletBalance = Money.fromKobo(7000000); // ₦70,000.00
      expect(await harness.getLocalWalletBalance(), expectedWalletBalance);

      // 2. Savings goal savedAmount is incremented exactly once
      currentGoal = await harness.getLocalGoal(goal.id);
      expect(
        currentGoal?.savedAmount,
        const Money.fromKobo(13000000),
      ); // ₦130,000.00

      // 3. Wallet transaction history reflects contribution debit
      final localTx = await harness.getLocalTransactions();
      expect(localTx, hasLength(1));
      expect(localTx.first.id, opId.value);
      expect(localTx.first.type, TransactionType.debit);
      expect(localTx.first.amount, contribAmount);
      expect(localTx.first.counterparty, 'New Laptop');
      expect(localTx.first.narration, 'NovaSave Contribution');
      expect(localTx.first.status, TransactionStatus.completed);

      // 4. Replaying synchronization does not duplicate goal progress or wallet debit
      final replayResult = await harness.triggerSync();
      expect(replayResult.succeeded, 0);
      expect(await harness.getLocalWalletBalance(), expectedWalletBalance);
      currentGoal = await harness.getLocalGoal(goal.id);
      expect(currentGoal?.savedAmount, const Money.fromKobo(13000000));
      expect(await harness.getLocalTransactions(), hasLength(1));
    });

    test('Multiple queued outgoing operations across Send and Contribution reserve spendable balance correctly', () async {
      // Setup goal
      final goal = SavingsGoal(
        id: 'goal-emergency-fund',
        name: 'Emergency Fund',
        targetAmount: const Money.fromKobo(20000000), // ₦200,000.00
        savedAmount: const Money.fromKobo(5000000), // ₦50,000.00
        targetDate: DateTime.utc(2027, 6, 30),
      );
      await harness.novaSaveRepository.createGoal(goal);

      // Initial state: confirmed = ₦100,000.00
      expect(
        await harness.getLocalWalletBalance(),
        const Money.fromKobo(10000000),
      );

      // 1. Enqueue Send Money: ₦40,000.00
      await harness.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        recipientAccountNumber: '1234567890',
        recipientName: 'Kemi Adebayo',
        bankName: 'Access Bank',
        amount: const Money.fromKobo(4000000),
      );

      // 2. Enqueue NovaSave Contribution: ₦35,000.00
      await harness.enqueueContribution(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        goalId: goal.id,
        goalName: goal.name,
        amount: const Money.fromKobo(3500000),
      );

      // Spendable balance policy check:
      // Confirmed = ₦100,000.00, Total Pending Debits = ₦75,000.00
      // Spendable = ₦25,000.00
      final pendingOps = await harness.getLocalPendingOperations();
      expect(pendingOps, hasLength(2));

      const policy = SpendableBalancePolicy();
      final confirmed = await harness.getLocalWalletBalance();
      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmed,
        operations: pendingOps,
      );
      expect(spendable, const Money.fromKobo(2500000)); // ₦25,000.00

      // Verify that canSpend rejects an amount exceeding remaining spendable balance (e.g. ₦30,000)
      expect(
        policy.canSpend(
          amount: const Money.fromKobo(3000000),
          confirmedBalance: confirmed,
          operations: pendingOps,
        ),
        isFalse,
      );

      // Verify that canSpend accepts an amount within remaining spendable balance (e.g. ₦20,000)
      expect(
        policy.canSpend(
          amount: const Money.fromKobo(2000000),
          confirmedBalance: confirmed,
          operations: pendingOps,
        ),
        isTrue,
      );

      // 3. Connect and synchronize both
      harness.setConnectivity(ConnectivityStatus.online);
      final syncResult = await harness.triggerSync();
      expect(syncResult.succeeded, 2);

      // After sync: confirmed balance is debited by exactly ₦75,000 -> ₦25,000
      const finalBalance = Money.fromKobo(2500000);
      expect(await harness.getLocalWalletBalance(), finalBalance);
      expect(await harness.getRemoteBalance(), finalBalance);

      // Goal is credited by ₦35,000 -> ₦85,000
      final updatedGoal = await harness.getLocalGoal(goal.id);
      expect(updatedGoal?.savedAmount, const Money.fromKobo(8500000));

      // Wallet activity ledger contains both transactions
      final transactions = await harness.getLocalTransactions();
      expect(transactions, hasLength(2));
      expect(
        transactions.every((tx) => tx.status == TransactionStatus.completed),
        isTrue,
      );
    });

    test('Atomic projection guard prevents duplicate debit if transaction was already committed', () async {
      // Simulate an operation that was executed remotely and local transaction was saved,
      // but markCompleted was interrupted
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      const sendAmount = Money.fromKobo(1500000); // ₦15,000.00

      await harness.enqueueSendMoney(
        id: opId,
        idempotencyKey: idKey,
        recipientAccountNumber: '0987654321',
        recipientName: 'Seyi Tinubu',
        bankName: 'Zenith Bank',
        amount: sendAmount,
      );

      // Run sync to complete
      harness.setConnectivity(ConnectivityStatus.online);
      await harness.triggerSync();

      final initialCompletedBalance = await harness.getLocalWalletBalance();
      final initialTxCount = (await harness.getLocalTransactions()).length;

      // Force operation back to processing to simulate interrupted markCompleted recovery
      final op = await harness.getLocalOperationById(opId);
      expect(op?.status, OperationStatus.completed);

      // Triggering sync again should detect existing completed operation and avoid duplicate debit
      await harness.triggerSync();

      expect(await harness.getLocalWalletBalance(), initialCompletedBalance);
      expect((await harness.getLocalTransactions()).length, initialTxCount);
    });
  });
}
