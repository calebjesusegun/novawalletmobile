import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/spendable_balance_policy.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  const policy = SpendableBalancePolicy();

  FinancialOperation createSendOp({required String id, required int kobo}) {
    return FinancialOperation.send(
      id: OperationId('op-$id'),
      idempotencyKey: IdempotencyKey('key-$id'),
      payload: SendMoneyPayload(
        recipientAccountNumber: '0123456789',
        recipientName: 'Recipient $id',
        bankName: 'NovaBank',
        amount: Money.fromKobo(kobo),
      ),
    );
  }

  FinancialOperation createContributionOp({
    required String id,
    required int kobo,
  }) {
    return FinancialOperation.contribution(
      id: OperationId('op-c-$id'),
      idempotencyKey: IdempotencyKey('key-c-$id'),
      payload: ContributionPayload(
        goalId: 'goal-$id',
        goalName: 'Goal $id',
        amount: Money.fromKobo(kobo),
      ),
    );
  }

  group('SpendableBalancePolicy (MNY-006 & HC-MONEY)', () {
    const confirmedBalance = Money.fromKobo(10000000); // ₦100,000.00

    test('when no operations are queued, spendable balance equals confirmed balance', () {
      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [],
      );

      expect(spendable, confirmedBalance);
      expect(spendable.kobo, 10000000);
      expect(policy.calculateReservedAmount([]), const Money.zero());
    });

    test(
      'deducts a single pending Send Money operation from spendable balance',
      () {
        final op = createSendOp(id: '1', kobo: 3000000); // ₦30,000.00
        final spendable = policy.calculateSpendableBalance(
          confirmedBalance: confirmedBalance,
          operations: [op],
        );

        // ₦100,000.00 - ₦30,000.00 = ₦70,000.00
        expect(spendable, const Money.fromKobo(7000000));
        expect(
          policy.calculateReservedAmount([op]),
          const Money.fromKobo(3000000),
        );
      },
    );

    test(
      'deducts multiple pending operations across Send Money and NovaSave',
      () {
        final sendOp = createSendOp(id: '1', kobo: 2500000); // ₦25,000.00
        final contribOp = createContributionOp(
          id: '2',
          kobo: 1500000,
        ); // ₦15,000.00

        final spendable = policy.calculateSpendableBalance(
          confirmedBalance: confirmedBalance,
          operations: [sendOp, contribOp],
        );

        // ₦100,000.00 - (₦25,000.00 + ₦15,000.00) = ₦60,000.00
        expect(spendable, const Money.fromKobo(6000000));
        expect(
          policy.calculateReservedAmount([sendOp, contribOp]),
          const Money.fromKobo(4000000),
        );
      },
    );

    test('in-flight processing operations are counted as reserved', () {
      final processingOp = createSendOp(
        id: '1',
        kobo: 4000000,
      ).markProcessing();

      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [processingOp],
      );

      // ₦100,000.00 - ₦40,000.00 = ₦60,000.00
      expect(spendable, const Money.fromKobo(6000000));
    });

    test('operations with recoverable sync errors stay pending and retain reservation', () {
      final opWithRecoverableError = createSendOp(id: '1', kobo: 3500000)
          .markProcessing()
          .markRecoverableError(
            error: SyncError.recoverable(message: 'Connection dropped'),
          );

      expect(opWithRecoverableError.isPending, isTrue);

      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [opWithRecoverableError],
      );

      // ₦100,000.00 - ₦35,000.00 = ₦65,000.00
      expect(spendable, const Money.fromKobo(6500000));
    });

    test('completed operations do not deduct from spendable balance', () {
      final completedOp = createSendOp(
        id: '1',
        kobo: 5000000,
      ).markProcessing().markCompleted(remoteReference: 'SETTLED-123');

      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [completedOp],
      );

      // Completed operations do not double-deduct from confirmed balance
      expect(spendable, confirmedBalance);
    });

    test('failed operations release their reservation immediately', () {
      final failedOp = createSendOp(id: '1', kobo: 5000000)
          .markProcessing()
          .markTerminalFailure(
            error: SyncError.terminal(message: 'Invalid account'),
          );

      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [failedOp],
      );

      // Failed operations release reservation
      expect(spendable, confirmedBalance);
    });

    test('clamps spendable balance to zero when pending operations exceed confirmed balance', () {
      final hugeOp = createSendOp(
        id: '1',
        kobo: 15000000,
      ); // ₦150,000.00 > ₦100,000.00

      final spendable = policy.calculateSpendableBalance(
        confirmedBalance: confirmedBalance,
        operations: [hugeOp],
      );

      expect(spendable, const Money.zero());
      expect(spendable.isZero, isTrue);
      expect(spendable.isNegative, isFalse);
    });
  });

  group('SpendableBalancePolicy canSpend Validation', () {
    const confirmedBalance = Money.fromKobo(5000000); // ₦50,000.00
    final queuedOp = createSendOp(
      id: '1',
      kobo: 2000000,
    ); // ₦20,000.00 queued -> ₦30,000.00 spendable

    test('returns true for amounts within spendable balance', () {
      expect(
        policy.canSpend(
          amount: const Money.fromKobo(1500000), // ₦15,000.00 <= ₦30,000.00
          confirmedBalance: confirmedBalance,
          operations: [queuedOp],
        ),
        isTrue,
      );
    });

    test('returns true for amount exactly equal to spendable balance', () {
      expect(
        policy.canSpend(
          amount: const Money.fromKobo(3000000), // ₦30,000.00 == ₦30,000.00
          confirmedBalance: confirmedBalance,
          operations: [queuedOp],
        ),
        isTrue,
      );
    });

    test('returns false for amounts exceeding spendable balance', () {
      expect(
        policy.canSpend(
          amount: const Money.fromKobo(3000001), // 1 kobo over
          confirmedBalance: confirmedBalance,
          operations: [queuedOp],
        ),
        isFalse,
      );

      expect(
        policy.canSpend(
          amount: const Money.fromKobo(5000000), // would exceed after queued
          confirmedBalance: confirmedBalance,
          operations: [queuedOp],
        ),
        isFalse,
      );
    });

    test('returns false for zero or negative amounts', () {
      expect(
        policy.canSpend(
          amount: const Money.zero(),
          confirmedBalance: confirmedBalance,
          operations: [],
        ),
        isFalse,
      );

      expect(
        policy.canSpend(
          amount: const Money.fromKobo(-1000),
          confirmedBalance: confirmedBalance,
          operations: [],
        ),
        isFalse,
      );
    });
  });
}
