import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  late InMemoryRemoteLedger ledger;
  late FakeRemoteApi remoteApi;
  late DateTime fixedTime;

  setUp(() {
    fixedTime = DateTime.utc(2026, 9, 21, 12, 0, 0);
    ledger = InMemoryRemoteLedger(
      initialBalance: const Money.fromKobo(10000000), // ₦100,000.00
    );
    remoteApi = FakeRemoteApi(
      ledger: ledger,
      clock: () => fixedTime,
      referenceGenerator: (op) => 'MOCK-REF-${op.id.value}',
    );
  });

  group(
    'FakeRemoteApi — Send Money Idempotency (ASM-006, SYNC-008, TST-003)',
    () {
      test('first delivery of a new key debits balance and creates transaction record', () async {
        final op = FinancialOperation.send(
          id: OperationId('op-send-1'),
          idempotencyKey: IdempotencyKey('idem-key-1'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Ada Lovelace',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(500000), // ₦5,000.00
            narration: 'Consulting fee',
          ),
        );

        final result = await remoteApi.sendMoney(op);

        expect(result.remoteReference, 'MOCK-REF-op-send-1');
        expect(result.settledAt, fixedTime);
        expect(result.debitAmount, const Money.fromKobo(500000));
        expect(result.isDuplicate, isFalse);

        // Verify remote balance was deducted exactly once
        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(9500000)); // ₦95,000.00

        // Verify transaction was appended
        final txns = await remoteApi.fetchTransactions();
        expect(txns.length, 1);
        expect(txns.first.id, 'MOCK-REF-op-send-1');
        expect(txns.first.amount, const Money.fromKobo(500000));
        expect(txns.first.counterparty, 'Ada Lovelace');
        expect(txns.first.type, TransactionType.debit);
        expect(txns.first.narration, 'Consulting fee');
      });

      test('repeated delivery with same key and same payload returns cached result without second debit', () async {
        final op = FinancialOperation.send(
          id: OperationId('op-send-1'),
          idempotencyKey: IdempotencyKey('idem-key-1'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Ada Lovelace',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(500000), // ₦5,000.00
          ),
        );

        // First delivery
        final firstResult = await remoteApi.sendMoney(op);
        expect(firstResult.isDuplicate, isFalse);

        // Repeated delivery (e.g. retry after network timeout or reconnect)
        final secondResult = await remoteApi.sendMoney(op);
        expect(secondResult.isDuplicate, isTrue);
        expect(secondResult.remoteReference, firstResult.remoteReference);
        expect(secondResult.settledAt, firstResult.settledAt);
        expect(secondResult.debitAmount, firstResult.debitAmount);

        // Verify remote balance was NOT deducted a second time
        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(9500000));

        // Verify only 1 transaction exists
        final txns = await remoteApi.fetchTransactions();
        expect(txns.length, 1);
      });

      test('multiple repeated retries return identical result without any additional debits', () async {
        final op = FinancialOperation.send(
          id: OperationId('op-send-repeat'),
          idempotencyKey: IdempotencyKey('idem-key-repeat'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '9999999999',
            recipientName: 'Chidi Anagonye',
            bankName: 'GTBank',
            amount: const Money.fromKobo(1000000), // ₦10,000.00
          ),
        );

        // 5 consecutive submissions
        for (int i = 0; i < 5; i++) {
          final res = await remoteApi.sendMoney(op);
          expect(res.remoteReference, 'MOCK-REF-op-send-repeat');
          expect(res.debitAmount, const Money.fromKobo(1000000));
          if (i == 0) {
            expect(res.isDuplicate, isFalse);
          } else {
            expect(res.isDuplicate, isTrue);
          }
        }

        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(9000000));
        final txns = await remoteApi.fetchTransactions();
        expect(txns.length, 1);
      });
    },
  );

  group('FakeRemoteApi — Payload Conflict Detection (SYNC-009)', () {
    test('rejects repeated idempotency key when amount differs', () async {
      final key = IdempotencyKey('conflict-key-1');

      final initialOp = FinancialOperation.send(
        id: OperationId('op-send-orig'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );
      await remoteApi.sendMoney(initialOp);

      final conflictingOp = FinancialOperation.send(
        id: OperationId('op-send-conflict'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(600000), // Different amount!
        ),
      );

      expect(
        () => remoteApi.sendMoney(conflictingOp),
        throwsA(
          isA<ConflictingIdempotencyKeyException>().having(
            (e) => e.idempotencyKey,
            'idempotencyKey',
            'conflict-key-1',
          ),
        ),
      );

      // Verify balance was not touched by conflicting attempt
      final snapshot = await remoteApi.fetchWalletSnapshot();
      expect(snapshot.balance, const Money.fromKobo(9500000));
    });

    test('rejects repeated key when recipient differs', () async {
      final key = IdempotencyKey('conflict-key-2');

      final initialOp = FinancialOperation.send(
        id: OperationId('op-send-orig'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );
      await remoteApi.sendMoney(initialOp);

      final conflictingOp = FinancialOperation.send(
        id: OperationId('op-send-conflict'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '9876543210', // Different account!
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );

      expect(
        () => remoteApi.sendMoney(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });

    test('rejects repeated key when bank name differs', () async {
      final key = IdempotencyKey('conflict-key-3');

      final initialOp = FinancialOperation.send(
        id: OperationId('op-send-orig'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );
      await remoteApi.sendMoney(initialOp);

      final conflictingOp = FinancialOperation.send(
        id: OperationId('op-send-conflict'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Zenith Bank', // Different bank!
          amount: const Money.fromKobo(500000),
        ),
      );

      expect(
        () => remoteApi.sendMoney(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });

    test('rejects repeated key when narration differs', () async {
      final key = IdempotencyKey('conflict-key-4');

      final initialOp = FinancialOperation.send(
        id: OperationId('op-send-orig'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
          narration: 'Invoice 1',
        ),
      );
      await remoteApi.sendMoney(initialOp);

      final conflictingOp = FinancialOperation.send(
        id: OperationId('op-send-conflict'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
          narration: 'Invoice 2', // Different narration!
        ),
      );

      expect(
        () => remoteApi.sendMoney(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });

    test('rejects repeated key across mismatched operation types', () async {
      final key = IdempotencyKey('cross-type-key');

      final sendOp = FinancialOperation.send(
        id: OperationId('op-send'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(500000),
        ),
      );
      await remoteApi.sendMoney(sendOp);

      final contributionOp = FinancialOperation.contribution(
        id: OperationId('op-contrib'),
        idempotencyKey: key,
        payload: ContributionPayload(
          goalId: 'goal-1',
          goalName: 'Tech Setup',
          amount: const Money.fromKobo(500000),
        ),
      );

      expect(
        () => remoteApi.contribute(contributionOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });
  });

  group('FakeRemoteApi — NovaSave Contribution Idempotency', () {
    test(
      'first contribution debits balance and creates transaction record',
      () async {
        final op = FinancialOperation.contribution(
          id: OperationId('op-contrib-1'),
          idempotencyKey: IdempotencyKey('contrib-key-1'),
          payload: ContributionPayload(
            goalId: 'goal-macbook',
            goalName: 'MacBook Pro M3',
            amount: const Money.fromKobo(2000000), // ₦20,000.00
          ),
        );

        final result = await remoteApi.contribute(op);

        expect(result.remoteReference, 'MOCK-REF-op-contrib-1');
        expect(result.settledAt, fixedTime);
        expect(result.debitAmount, const Money.fromKobo(2000000));
        expect(result.isDuplicate, isFalse);

        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(8000000)); // ₦80,000.00

        final txns = await remoteApi.fetchTransactions();
        expect(txns.length, 1);
        expect(txns.first.counterparty, 'NovaSave: MacBook Pro M3');
        expect(txns.first.narration, 'Contribution to MacBook Pro M3');
      },
    );

    test('repeated contribution with same key returns cached result without second debit', () async {
      final op = FinancialOperation.contribution(
        id: OperationId('op-contrib-1'),
        idempotencyKey: IdempotencyKey('contrib-key-1'),
        payload: ContributionPayload(
          goalId: 'goal-macbook',
          goalName: 'MacBook Pro M3',
          amount: const Money.fromKobo(2000000),
        ),
      );

      final first = await remoteApi.contribute(op);
      final second = await remoteApi.contribute(op);

      expect(first.isDuplicate, isFalse);
      expect(second.isDuplicate, isTrue);
      expect(second.remoteReference, first.remoteReference);

      final snapshot = await remoteApi.fetchWalletSnapshot();
      expect(snapshot.balance, const Money.fromKobo(8000000));
      final txns = await remoteApi.fetchTransactions();
      expect(txns.length, 1);
    });

    test('rejects conflicting contribution payload with different goalId or amount', () async {
      final key = IdempotencyKey('contrib-conflict-key');

      final origOp = FinancialOperation.contribution(
        id: OperationId('op-c1'),
        idempotencyKey: key,
        payload: ContributionPayload(
          goalId: 'goal-1',
          goalName: 'Emergency Fund',
          amount: const Money.fromKobo(1000000),
        ),
      );
      await remoteApi.contribute(origOp);

      final conflictingOp = FinancialOperation.contribution(
        id: OperationId('op-c2'),
        idempotencyKey: key,
        payload: ContributionPayload(
          goalId: 'goal-2', // Different goal!
          goalName: 'Vacation',
          amount: const Money.fromKobo(1000000),
        ),
      );

      expect(
        () => remoteApi.contribute(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });
  });

  group('FakeRemoteApi — Validation & Balance Bounds', () {
    test('throws InsufficientRemoteFundsException when debit exceeds remote balance', () async {
      final op = FinancialOperation.send(
        id: OperationId('op-big-send'),
        idempotencyKey: IdempotencyKey('big-key'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(
            20000000,
          ), // ₦200,000.00 > ₦100,000.00 balance
        ),
      );

      expect(
        () => remoteApi.sendMoney(op),
        throwsA(
          isA<InsufficientRemoteFundsException>()
              .having((e) => e.requestedKobo, 'requestedKobo', 20000000)
              .having((e) => e.availableKobo, 'availableKobo', 10000000),
        ),
      );

      final snapshot = await remoteApi.fetchWalletSnapshot();
      expect(snapshot.balance, const Money.fromKobo(10000000));
    });

    test('throws InvalidRemoteOperationException when calling sendMoney with contribution operation', () async {
      final op = FinancialOperation.contribution(
        id: OperationId('op-wrong-type'),
        idempotencyKey: IdempotencyKey('wrong-type-key'),
        payload: ContributionPayload(
          goalId: 'goal-1',
          goalName: 'Goal',
          amount: const Money.fromKobo(100000),
        ),
      );

      expect(
        () => remoteApi.sendMoney(op),
        throwsA(isA<InvalidRemoteOperationException>()),
      );
    });

    test('throws InvalidRemoteOperationException when calling contribute with send operation', () async {
      final op = FinancialOperation.send(
        id: OperationId('op-wrong-type-2'),
        idempotencyKey: IdempotencyKey('wrong-type-key-2'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Ada Lovelace',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(100000),
        ),
      );

      expect(
        () => remoteApi.contribute(op),
        throwsA(isA<InvalidRemoteOperationException>()),
      );
    });
  });

  group('FakeRemoteApi — Polymorphic Dispatcher & Pagination', () {
    test(
      'submitOperation routes both send and contribution correctly',
      () async {
        final sendOp = FinancialOperation.send(
          id: OperationId('op-poly-send'),
          idempotencyKey: IdempotencyKey('poly-send-key'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Ada Lovelace',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(100000),
          ),
        );

        final contribOp = FinancialOperation.contribution(
          id: OperationId('op-poly-contrib'),
          idempotencyKey: IdempotencyKey('poly-contrib-key'),
          payload: ContributionPayload(
            goalId: 'goal-1',
            goalName: 'Tech',
            amount: const Money.fromKobo(200000),
          ),
        );

        final sendRes = await remoteApi.submitOperation(sendOp);
        expect(sendRes.debitAmount, const Money.fromKobo(100000));

        final contribRes = await remoteApi.submitOperation(contribOp);
        expect(contribRes.debitAmount, const Money.fromKobo(200000));

        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(9700000));
      },
    );

    test('fetchTransactions respects limit and offset pagination', () async {
      for (int i = 1; i <= 5; i++) {
        final op = FinancialOperation.send(
          id: OperationId('op-seq-$i'),
          idempotencyKey: IdempotencyKey('seq-key-$i'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '012345678$i',
            recipientName: 'Recipient $i',
            bankName: 'Access Bank',
            amount: Money.fromKobo(100000 * i),
          ),
        );
        await remoteApi.sendMoney(op);
      }

      final page1 = await remoteApi.fetchTransactions(limit: 2, offset: 0);
      expect(page1.length, 2);
      expect(page1[0].counterparty, 'Recipient 5');
      expect(page1[1].counterparty, 'Recipient 4');

      final page2 = await remoteApi.fetchTransactions(limit: 2, offset: 2);
      expect(page2.length, 2);
      expect(page2[0].counterparty, 'Recipient 3');
      expect(page2[1].counterparty, 'Recipient 2');

      final page3 = await remoteApi.fetchTransactions(limit: 2, offset: 4);
      expect(page3.length, 1);
      expect(page3[0].counterparty, 'Recipient 1');

      final pageEmpty = await remoteApi.fetchTransactions(limit: 2, offset: 10);
      expect(pageEmpty, isEmpty);
    });
  });
}
