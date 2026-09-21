import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  late InMemoryRemoteLedger ledger;
  late FailureSimulator failureSimulator;
  late FakeRemoteApi remoteApi;
  late DateTime fixedTime;

  setUp(() {
    fixedTime = DateTime.utc(2026, 9, 21, 14, 0, 0);
    ledger = InMemoryRemoteLedger(
      initialBalance: const Money.fromKobo(10000000), // ₦100,000.00
    );
    failureSimulator = FailureSimulator();
    remoteApi = FakeRemoteApi(
      ledger: ledger,
      clock: () => fixedTime,
      referenceGenerator: (op) => 'REF-${op.id.value}',
      failureSimulator: failureSimulator,
    );
  });

  group(
    'FailureSimulator — Transient Transport Failure (SYNC-012, TST-007)',
    () {
      test('transient transport failure fails pre-execution with zero balance deduction', () async {
        final op = FinancialOperation.send(
          id: OperationId('op-transport-1'),
          idempotencyKey: IdempotencyKey('key-transport-1'),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Kemi Adeosun',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(500000), // ₦5,000.00
          ),
        );

        // Configure transport failure for next attempt
        failureSimulator.failNext(SimulatedFailureType.transport);

        await expectLater(
          remoteApi.sendMoney(op),
          throwsA(
            isA<RemoteTransportException>()
                .having((e) => e.isRecoverable, 'isRecoverable', isTrue)
                .having((e) => e.code, 'code', 'TRANSPORT_ERROR'),
          ),
        );

        // Zero remote side-effects: balance untouched, no transactions
        final snapshot = await remoteApi.fetchWalletSnapshot();
        expect(snapshot.balance, const Money.fromKobo(10000000));
        final txns = await remoteApi.fetchTransactions();
        expect(txns, isEmpty);

        // Subsequent attempt (rule exhausted) succeeds
        final result = await remoteApi.sendMoney(op);
        expect(result.isDuplicate, isFalse);
        expect(result.remoteReference, 'REF-op-transport-1');

        final updatedSnapshot = await remoteApi.fetchWalletSnapshot();
        expect(updatedSnapshot.balance, const Money.fromKobo(9500000));
      });

      test(
        'transient server error is recoverable with zero balance deduction',
        () async {
          final op = FinancialOperation.send(
            id: OperationId('op-server-1'),
            idempotencyKey: IdempotencyKey('key-server-1'),
            payload: SendMoneyPayload(
              recipientAccountNumber: '0123456789',
              recipientName: 'Kemi Adeosun',
              bankName: 'Access Bank',
              amount: const Money.fromKobo(500000),
            ),
          );

          failureSimulator.failNext(
            SimulatedFailureType.serverError,
            message: 'HTTP 503 Service Unavailable',
          );

          await expectLater(
            remoteApi.sendMoney(op),
            throwsA(
              isA<RemoteServerException>()
                  .having((e) => e.isRecoverable, 'isRecoverable', isTrue)
                  .having((e) => e.code, 'code', 'SERVER_ERROR')
                  .having((e) => e.message, 'message', contains('HTTP 503')),
            ),
          );

          final snapshot = await remoteApi.fetchWalletSnapshot();
          expect(snapshot.balance, const Money.fromKobo(10000000));
        },
      );
    },
  );

  group(
    'FailureSimulator — Terminal Business Rejection (SND-013, NSV-015)',
    () {
      test(
        'business rejection is non-recoverable with zero balance deduction',
        () async {
          final op = FinancialOperation.send(
            id: OperationId('op-reject-1'),
            idempotencyKey: IdempotencyKey('key-reject-1'),
            payload: SendMoneyPayload(
              recipientAccountNumber: '9999999999',
              recipientName: 'Suspicious Account',
              bankName: 'FirstBank',
              amount: const Money.fromKobo(1000000),
            ),
          );

          failureSimulator.failNext(
            SimulatedFailureType.businessRejection,
            message: 'Destination account is frozen by regulatory authority.',
            code: 'ACCOUNT_FROZEN',
          );

          await expectLater(
            remoteApi.sendMoney(op),
            throwsA(
              isA<RemoteBusinessRejectionException>()
                  .having((e) => e.isRecoverable, 'isRecoverable', isFalse)
                  .having((e) => e.code, 'code', 'ACCOUNT_FROZEN')
                  .having((e) => e.message, 'message', contains('frozen')),
            ),
          );

          // Balance was not debited
          final snapshot = await remoteApi.fetchWalletSnapshot();
          expect(snapshot.balance, const Money.fromKobo(10000000));
        },
      );
    },
  );

  group('FailureSimulator — Response Lost / Uncertain Outcome (SYNC-011, TST-007, HC-EXACTLY-ONCE-EFFECT)', () {
    test('settles remotely, throws RemoteResponseLostException, and subsequent replay deduplicates without second debit', () async {
      final op = FinancialOperation.send(
        id: OperationId('op-lost-1'),
        idempotencyKey: IdempotencyKey('key-lost-1'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Fola Durojaiye',
          bankName: 'Zenith Bank',
          amount: const Money.fromKobo(2500000), // ₦25,000.00
        ),
      );

      // Configure single-shot response-lost failure
      failureSimulator.failNext(SimulatedFailureType.responseLost);

      // Step 1: Client sends money. Remote settles, but response drops.
      late RemoteResponseLostException caughtException;
      try {
        await remoteApi.sendMoney(op);
        fail('Expected RemoteResponseLostException was not thrown');
      } on RemoteResponseLostException catch (e) {
        caughtException = e;
      }

      expect(caughtException.isRecoverable, isTrue);
      expect(caughtException.code, 'RESPONSE_LOST');
      expect(caughtException.remoteReference, 'REF-op-lost-1');

      // VERIFY: The remote balance WAS deducted once because it settled remotely
      final intermediateSnapshot = await remoteApi.fetchWalletSnapshot();
      expect(
        intermediateSnapshot.balance,
        const Money.fromKobo(7500000),
      ); // ₦75,000.00

      // VERIFY: Remote transaction was recorded
      final intermediateTxns = await remoteApi.fetchTransactions();
      expect(intermediateTxns.length, 1);
      expect(intermediateTxns.first.id, 'REF-op-lost-1');

      // Step 2: Client sync engine replays the exact same operation with the SAME idempotency key
      final replayResult = await remoteApi.sendMoney(op);

      // VERIFY: Replay returns original reference with isDuplicate == true
      expect(replayResult.isDuplicate, isTrue);
      expect(replayResult.remoteReference, 'REF-op-lost-1');
      expect(replayResult.debitAmount, const Money.fromKobo(2500000));

      // CRITICAL HC-EXACTLY-ONCE-EFFECT VERIFICATION: Balance is NOT debited a second time!
      final finalSnapshot = await remoteApi.fetchWalletSnapshot();
      expect(finalSnapshot.balance, const Money.fromKobo(7500000));

      // Transaction log still has exactly 1 entry
      final finalTxns = await remoteApi.fetchTransactions();
      expect(finalTxns.length, 1);
    });

    test('NovaSave contribution response-lost settles and replays with exact-once effect', () async {
      final op = FinancialOperation.contribution(
        id: OperationId('op-contrib-lost'),
        idempotencyKey: IdempotencyKey('key-contrib-lost'),
        payload: ContributionPayload(
          goalId: 'goal-rent',
          goalName: 'Apartment Rent',
          amount: const Money.fromKobo(4000000), // ₦40,000.00
        ),
      );

      failureSimulator.failNext(SimulatedFailureType.responseLost);

      await expectLater(
        remoteApi.contribute(op),
        throwsA(isA<RemoteResponseLostException>()),
      );

      // Remote balance debited once
      final snapshot1 = await remoteApi.fetchWalletSnapshot();
      expect(snapshot1.balance, const Money.fromKobo(6000000));

      // Replay with same key
      final result = await remoteApi.contribute(op);
      expect(result.isDuplicate, isTrue);
      expect(result.remoteReference, 'REF-op-contrib-lost');

      // No second debit
      final snapshot2 = await remoteApi.fetchWalletSnapshot();
      expect(snapshot2.balance, const Money.fromKobo(6000000));
    });
  });

  group('FailureSimulator — Rule Scoping & Multi-attempt Sequences', () {
    test('failForIdempotencyKey targets only matching operation', () async {
      failureSimulator.failForIdempotencyKey(
        'target-key',
        SimulatedFailureType.transport,
      );

      final unaffectedOp = FinancialOperation.send(
        id: OperationId('op-unaffected'),
        idempotencyKey: IdempotencyKey('other-key'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Normal User',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(100000),
        ),
      );

      final targetOp = FinancialOperation.send(
        id: OperationId('op-target'),
        idempotencyKey: IdempotencyKey('target-key'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Target User',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(100000),
        ),
      );

      // Unaffected operation succeeds normally
      final res1 = await remoteApi.sendMoney(unaffectedOp);
      expect(res1.isDuplicate, isFalse);

      // Target operation fails
      await expectLater(
        remoteApi.sendMoney(targetOp),
        throwsA(isA<RemoteTransportException>()),
      );
    });

    test('failNextN fails for exact number of attempts', () async {
      failureSimulator.failNextN(2, SimulatedFailureType.transport);

      final op = FinancialOperation.send(
        id: OperationId('op-retry-n'),
        idempotencyKey: IdempotencyKey('key-retry-n'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'User',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(100000),
        ),
      );

      // Attempt 1: Fails
      await expectLater(
        remoteApi.sendMoney(op),
        throwsA(isA<RemoteTransportException>()),
      );

      // Attempt 2: Fails
      await expectLater(
        remoteApi.sendMoney(op),
        throwsA(isA<RemoteTransportException>()),
      );

      // Attempt 3: Succeeds
      final res = await remoteApi.sendMoney(op);
      expect(res.isDuplicate, isFalse);
    });

    test('reset clears all active rules immediately', () async {
      failureSimulator.failNextN(10, SimulatedFailureType.transport);
      expect(failureSimulator.activeRules.length, 1);

      failureSimulator.reset();
      expect(failureSimulator.activeRules, isEmpty);

      final op = FinancialOperation.send(
        id: OperationId('op-clear'),
        idempotencyKey: IdempotencyKey('key-clear'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'User',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(100000),
        ),
      );

      final res = await remoteApi.sendMoney(op);
      expect(res.isDuplicate, isFalse);
    });
  });

  group('RemoteApiException — Domain SyncError Mapping', () {
    test('toSyncError creates correct recoverable or terminal metadata', () {
      const transportEx = RemoteTransportException();
      final transportError = transportEx.toSyncError();
      expect(transportError.isRecoverable, isTrue);
      expect(transportError.code, 'TRANSPORT_ERROR');

      const serverEx = RemoteServerException();
      final serverError = serverEx.toSyncError();
      expect(serverError.isRecoverable, isTrue);
      expect(serverError.code, 'SERVER_ERROR');

      const lostEx = RemoteResponseLostException(remoteReference: 'REF-123');
      final lostError = lostEx.toSyncError();
      expect(lostError.isRecoverable, isTrue);
      expect(lostError.code, 'RESPONSE_LOST');

      const rejectionEx = RemoteBusinessRejectionException(message: 'Blocked');
      final rejectionError = rejectionEx.toSyncError();
      expect(rejectionError.isRecoverable, isFalse);
      expect(rejectionError.code, 'BUSINESS_REJECTION');

      final conflictEx = ConflictingIdempotencyKeyException(
        idempotencyKey: 'key-1',
      );
      final conflictError = conflictEx.toSyncError();
      expect(conflictError.isRecoverable, isFalse);
      expect(conflictError.code, 'CONFLICTING_KEY');

      final fundsEx = InsufficientRemoteFundsException(
        requestedKobo: 500,
        availableKobo: 200,
      );
      final fundsError = fundsEx.toSyncError();
      expect(fundsError.isRecoverable, isFalse);
      expect(fundsError.code, 'INSUFFICIENT_FUNDS');
    });
  });
}
