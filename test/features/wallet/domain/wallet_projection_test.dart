import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  group('WalletActivityItem', () {
    test('creates from confirmed WalletTransaction', () {
      final tx = WalletTransaction(
        id: 'tx-100',
        type: TransactionType.debit,
        amount: const Money.fromKobo(500000), // ₦5,000.00
        counterparty: 'Jane Doe',
        createdAt: DateTime.utc(2026, 9, 21, 10, 0),
        status: TransactionStatus.completed,
        reference: 'REF-12345',
        narration: 'Lunch repayment',
      );

      final item = WalletActivityItem.fromTransaction(tx);

      expect(item.id, equals('tx-100'));
      expect(item.title, equals('Jane Doe'));
      expect(item.subtitle, equals('Transfer'));
      expect(item.amount, equals(const Money.fromKobo(500000)));
      expect(item.type, equals(TransactionType.debit));
      expect(item.status, equals(TransactionStatus.completed));
      expect(item.isPendingSync, isFalse);
      expect(item.reference, equals('REF-12345'));
      expect(item.narration, equals('Lunch repayment'));
      expect(item.operationId, isNull);
    });

    test('creates from credit WalletTransaction with Deposit subtitle', () {
      final tx = WalletTransaction(
        id: 'tx-101',
        type: TransactionType.credit,
        amount: const Money.fromKobo(10000000), // ₦100,000.00
        counterparty: 'Top Up',
        createdAt: DateTime.utc(2026, 9, 21, 9, 0),
        status: TransactionStatus.completed,
      );

      final item = WalletActivityItem.fromTransaction(tx);

      expect(item.title, equals('Top Up'));
      expect(item.subtitle, equals('Deposit'));
      expect(item.type, equals(TransactionType.credit));
    });

    test('creates from pending SendMoney FinancialOperation', () {
      final op = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Alice Smith',
          bankName: 'FirstBank',
          amount: const Money.fromKobo(1000000), // ₦10,000.00
        ),
        createdAt: DateTime.utc(2026, 9, 21, 12, 0),
      );

      final item = WalletActivityItem.fromOperation(op);

      expect(item.id, equals(op.id.value));
      expect(item.title, equals('Alice Smith'));
      expect(item.subtitle, equals('Transfer'));
      expect(item.amount, equals(const Money.fromKobo(1000000)));
      expect(item.type, equals(TransactionType.debit));
      expect(item.status, equals(TransactionStatus.pending));
      expect(item.isPendingSync, isTrue);
      expect(item.operationId, equals(op.id));
    });

    test('creates from processing Contribution FinancialOperation', () {
      final op = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: ContributionPayload(
          goalId: 'goal-macbook',
          goalName: 'MacBook Pro Fund',
          amount: const Money.fromKobo(5000000), // ₦50,000.00
        ),
        createdAt: DateTime.utc(2026, 9, 21, 12, 30),
      ).markProcessing();

      final item = WalletActivityItem.fromOperation(op);

      expect(item.title, equals('MacBook Pro Fund'));
      expect(item.subtitle, equals('NovaSave'));
      expect(item.status, equals(TransactionStatus.processing));
      expect(item.isPendingSync, isTrue);
    });
  });

  group('WalletProjection', () {
    final t0 = DateTime.utc(2026, 9, 21, 8, 0);
    final t1 = DateTime.utc(2026, 9, 21, 9, 0);
    final t2 = DateTime.utc(2026, 9, 21, 10, 0);
    final t3 = DateTime.utc(2026, 9, 21, 11, 0);

    final confirmedTx1 = WalletTransaction(
      id: 'tx-1',
      type: TransactionType.credit,
      amount: const Money.fromKobo(12545000), // ₦125,450.00
      counterparty: 'Opening Balance',
      createdAt: t0,
    );

    final confirmedTx2 = WalletTransaction(
      id: 'tx-2',
      type: TransactionType.debit,
      amount: const Money.fromKobo(500000), // ₦5,000.00
      counterparty: 'Bob Builder',
      createdAt: t1,
    );

    test(
      'builds default empty projection when no snapshot or activities exist',
      () {
        final projection = WalletProjection.build();

        expect(projection.confirmedBalance, equals(const Money.zero()));
        expect(projection.spendableBalance, equals(const Money.zero()));
        expect(projection.pendingDebitTotal, equals(const Money.zero()));
        expect(projection.activities, isEmpty);
        expect(projection.hasPendingTransactions, isFalse);
        expect(projection.pendingCount, equals(0));
      },
    );

    test('builds projection with confirmed snapshot and transactions only', () {
      final snapshot = WalletSnapshot(
        balance: const Money.fromKobo(12045000), // ₦120,450.00
        lastUpdatedAt: t1,
      );

      final projection = WalletProjection.build(
        snapshot: snapshot,
        confirmedTransactions: [confirmedTx1, confirmedTx2],
      );

      expect(
        projection.confirmedBalance,
        equals(const Money.fromKobo(12045000)),
      );
      expect(
        projection.spendableBalance,
        equals(const Money.fromKobo(12045000)),
      );
      expect(projection.pendingDebitTotal, equals(const Money.zero()));
      expect(projection.hasPendingTransactions, isFalse);
      expect(projection.pendingCount, equals(0));
      expect(projection.activities.length, equals(2));

      // Activities sorted newest first: tx-2 (t1) before tx-1 (t0)
      expect(projection.activities[0].id, equals('tx-2'));
      expect(projection.activities[1].id, equals('tx-1'));
    });

    test('HC-MONEY & MNY-004: Preserves confirmed headline balance and reserves spendable balance when offline transfer is pending', () {
      final snapshot = WalletSnapshot(
        balance: const Money.fromKobo(12545000), // ₦125,450.00
        lastUpdatedAt: t1,
      );

      final pendingOp = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'John Doe',
          bankName: 'GTBank',
          amount: const Money.fromKobo(1000000), // ₦10,000.00
        ),
        createdAt: t2,
      );

      final projection = WalletProjection.build(
        snapshot: snapshot,
        confirmedTransactions: [confirmedTx1],
        operations: [pendingOp],
      );

      // Headline balance MUST remain un-debited before remote confirmation (AGENTS.md)
      expect(
        projection.confirmedBalance,
        equals(const Money.fromKobo(12545000)),
      );

      // Spendable balance MUST reserve the ₦10,000.00 immediately (MNY-004)
      expect(
        projection.spendableBalance,
        equals(const Money.fromKobo(11545000)),
      ); // ₦115,450.00
      expect(
        projection.pendingDebitTotal,
        equals(const Money.fromKobo(1000000)),
      );
      expect(projection.hasPendingTransactions, isTrue);
      expect(projection.pendingCount, equals(1));

      // Pending transfer appears at the top of recent activities (UI-WAL-03)
      expect(projection.activities.length, equals(2));
      expect(projection.activities[0].id, equals(pendingOp.id.value));
      expect(
        projection.activities[0].status,
        equals(TransactionStatus.pending),
      );
      expect(projection.activities[0].isPendingSync, isTrue);
      expect(projection.activities[0].title, equals('John Doe'));

      // Confirmed transaction is next
      expect(projection.activities[1].id, equals('tx-1'));
    });

    test('reconnect processing operation reflects processing status badge', () {
      final snapshot = WalletSnapshot(
        balance: const Money.fromKobo(12545000),
        lastUpdatedAt: t1,
      );

      final processingOp = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'John Doe',
          bankName: 'GTBank',
          amount: const Money.fromKobo(1000000),
        ),
        createdAt: t2,
      ).markProcessing();

      final projection = WalletProjection.build(
        snapshot: snapshot,
        confirmedTransactions: [confirmedTx1],
        operations: [processingOp],
      );

      expect(projection.hasPendingTransactions, isTrue);
      expect(projection.pendingCount, equals(1));
      expect(
        projection.activities[0].status,
        equals(TransactionStatus.processing),
      );
    });

    test('completed operations do not duplicate confirmed transactions in activity projection', () {
      final snapshot = WalletSnapshot(
        balance: const Money.fromKobo(11545000), // ₦115,450.00
        lastUpdatedAt: t3,
      );

      // Operation completed remotely
      final op = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'John Doe',
          bankName: 'GTBank',
          amount: const Money.fromKobo(1000000),
        ),
        createdAt: t2,
      ).markProcessing().markCompleted(remoteReference: 'REM-999', at: t3);

      // Confirmed transaction already inserted in local database by SyncCoordinator
      final confirmedSendTx = WalletTransaction(
        id: op.id.value,
        type: TransactionType.debit,
        amount: const Money.fromKobo(1000000),
        counterparty: 'John Doe',
        createdAt: t2,
        status: TransactionStatus.completed,
        reference: 'REM-999',
      );

      final projection = WalletProjection.build(
        snapshot: snapshot,
        confirmedTransactions: [confirmedSendTx, confirmedTx1],
        operations: [op], // Queue row still has completed op before cleanup
      );

      // Spendable balance equals confirmed balance since op is completed
      expect(
        projection.confirmedBalance,
        equals(const Money.fromKobo(11545000)),
      );
      expect(
        projection.spendableBalance,
        equals(const Money.fromKobo(11545000)),
      );
      expect(projection.pendingDebitTotal, equals(const Money.zero()));
      expect(projection.hasPendingTransactions, isFalse);
      expect(projection.pendingCount, equals(0));

      // Activities count MUST be 2, NOT 3 (zero duplication)
      expect(projection.activities.length, equals(2));
      expect(projection.activities[0].id, equals(op.id.value));
      expect(
        projection.activities[0].status,
        equals(TransactionStatus.completed),
      );
      expect(projection.activities[0].isPendingSync, isFalse);
    });

    test(
      'spendable balance fails closed to zero when reservations exceed balance',
      () {
        final snapshot = WalletSnapshot(
          balance: const Money.fromKobo(500000), // ₦5,000.00
          lastUpdatedAt: t1,
        );

        final largeOp = FinancialOperation.create(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Big Spender',
            bankName: 'Bank',
            amount: const Money.fromKobo(1000000), // ₦10,000.00
          ),
          createdAt: t2,
        );

        final projection = WalletProjection.build(
          snapshot: snapshot,
          operations: [largeOp],
        );

        expect(
          projection.confirmedBalance,
          equals(const Money.fromKobo(500000)),
        );
        expect(projection.spendableBalance, equals(const Money.zero()));
        expect(
          projection.pendingDebitTotal,
          equals(const Money.fromKobo(1000000)),
        );
      },
    );
  });
}
