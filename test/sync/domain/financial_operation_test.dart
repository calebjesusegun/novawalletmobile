import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  final testOpId = OperationId('op-test-001');
  final testKey = IdempotencyKey('key-test-001');

  SendMoneyPayload createSendPayload({int kobo = 1000000}) {
    return SendMoneyPayload(
      recipientAccountNumber: '0123456789',
      recipientName: 'Alice Green',
      bankName: 'NovaBank',
      amount: Money.fromKobo(kobo),
      narration: 'Transfer for Alice',
    );
  }

  ContributionPayload createContributionPayload({int kobo = 500000}) {
    return ContributionPayload(
      goalId: 'goal-42',
      goalName: 'Tech Gear',
      amount: Money.fromKobo(kobo),
    );
  }

  group('FinancialOperation Creation & Invariants', () {
    test('creates Send Money operation in initial pending state', () {
      final op = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      );

      expect(op.id, testOpId);
      expect(op.idempotencyKey, testKey);
      expect(op.type, OperationType.send);
      expect(op.status, OperationStatus.pending);
      expect(op.attemptCount, 0);
      expect(op.lastAttemptAt, isNull);
      expect(op.lastError, isNull);
      expect(op.remoteReference, isNull);
      expect(op.completedAt, isNull);

      expect(op.isPending, isTrue);
      expect(op.isProcessing, isFalse);
      expect(op.isCompleted, isFalse);
      expect(op.isFailed, isFalse);
      expect(op.isTerminal, isFalse);
      expect(op.isEligibleForSync, isTrue);
      expect(op.hasRecoverableError, isFalse);
    });

    test('creates Contribution operation in initial pending state', () {
      final op = FinancialOperation.contribution(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createContributionPayload(),
      );

      expect(op.type, OperationType.contribution);
      expect(op.status, OperationStatus.pending);
      expect(op.isEligibleForSync, isTrue);
    });

    test('PendingOperation typedef is identical to FinancialOperation', () {
      final PendingOperation op = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      );

      expect(op, isA<FinancialOperation>());
      expect(op.status, OperationStatus.pending);
    });
  });

  group(
    'Operation Lifecycle & State Transitions (HC-SYNC & HC-IDEMPOTENCY)',
    () {
      test('transitions from pending to processing upon sync claim', () {
        final initial = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        );

        final attemptTime = DateTime(2026, 9, 21, 10, 0);
        final claimed = initial.markProcessing(attemptTime: attemptTime);

        expect(claimed.status, OperationStatus.processing);
        expect(claimed.isProcessing, isTrue);
        expect(claimed.attemptCount, 1);
        expect(claimed.lastAttemptAt, attemptTime);
        expect(claimed.id, testOpId); // ID remains stable
        expect(claimed.idempotencyKey, testKey); // Key remains stable
      });

      test(
        'transitions from processing to completed upon remote settlement',
        () {
          final processing = FinancialOperation.send(
            id: testOpId,
            idempotencyKey: testKey,
            payload: createSendPayload(),
          ).markProcessing();

          final completionTime = DateTime(2026, 9, 21, 10, 5);
          final completed = processing.markCompleted(
            remoteReference: 'TXN-SETTLED-999',
            completedAt: completionTime,
          );

          expect(completed.status, OperationStatus.completed);
          expect(completed.isCompleted, isTrue);
          expect(completed.isTerminal, isTrue);
          expect(completed.remoteReference, 'TXN-SETTLED-999');
          expect(completed.completedAt, completionTime);
          expect(completed.lastError, isNull);
        },
      );

      test('recoverable error transitions back to pending and records error metadata', () {
        final processing = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing();

        final errorTime = DateTime(2026, 9, 21, 10, 10);
        final syncError = SyncError.recoverable(
          message: 'Connection timed out while sending transfer',
          code: 'NETWORK_TIMEOUT',
          timestamp: errorTime,
        );

        final returnedToPending = processing.markRecoverableError(
          error: syncError,
          attemptTime: errorTime,
        );

        // HC-SYNC & HC-OFFLINE-DURABILITY: Recoverable sync failure keeps operation queued and retryable!
        expect(returnedToPending.status, OperationStatus.pending);
        expect(returnedToPending.isPending, isTrue);
        expect(returnedToPending.isTerminal, isFalse);
        expect(returnedToPending.isEligibleForSync, isTrue);
        expect(returnedToPending.hasRecoverableError, isTrue);
        expect(returnedToPending.lastError, syncError);
        expect(returnedToPending.lastAttemptAt, errorTime);
        expect(returnedToPending.attemptCount, 1);

        // Stable identities are strictly preserved across retry recovery
        expect(returnedToPending.id, testOpId);
        expect(returnedToPending.idempotencyKey, testKey);
      });

      test('terminal error transitions to failed state', () {
        final processing = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing();

        final terminalError = SyncError.terminal(
          message: 'Recipient account has been frozen or closed',
          code: 'ACCOUNT_CLOSED',
        );

        final failed = processing.markTerminalFailure(error: terminalError);

        expect(failed.status, OperationStatus.failed);
        expect(failed.isFailed, isTrue);
        expect(failed.isTerminal, isTrue);
        expect(failed.lastError, terminalError);
      });

      test('re-claiming uncertain in-flight operation on restart succeeds and increments attempt', () {
        // Operation was left in processing state when app terminated
        final inFlight = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing();

        expect(inFlight.attemptCount, 1);

        // Re-claim on restart
        final reClaimed = inFlight.markProcessing();
        expect(reClaimed.status, OperationStatus.processing);
        expect(reClaimed.attemptCount, 2);
        expect(reClaimed.idempotencyKey, testKey);
      });
    },
  );

  group('Invalid State Transitions Protection', () {
    test('cannot complete directly from pending state', () {
      final pending = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      );

      expect(
        () => pending.markCompleted(remoteReference: 'REF-123'),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('cannot complete with empty remote reference', () {
      final processing = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      ).markProcessing();

      expect(
        () => processing.markCompleted(remoteReference: '   '),
        throwsArgumentError,
      );
    });

    test(
      'cannot mark completed operation as processing (no double-execution)',
      () {
        final completed = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing().markCompleted(remoteReference: 'REF-123');

        expect(
          completed.markProcessing,
          throwsA(isA<InvalidOperationTransitionException>()),
        );
      },
    );

    test('cannot mark completed operation as failed', () {
      final completed = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      ).markProcessing().markCompleted(remoteReference: 'REF-123');

      expect(
        () => completed.markTerminalFailure(
          error: SyncError.terminal(message: 'Fatal error'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('cannot mark failed operation as processing', () {
      final failed =
          FinancialOperation.send(
            id: testOpId,
            idempotencyKey: testKey,
            payload: createSendPayload(),
          ).markProcessing().markTerminalFailure(
            error: SyncError.terminal(message: 'Rejected'),
          );

      expect(
        failed.markProcessing,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('cannot apply terminal error to markRecoverableError', () {
      final processing = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      ).markProcessing();

      final nonRecoverable = SyncError.terminal(message: 'Account not found');

      expect(
        () => processing.markRecoverableError(error: nonRecoverable),
        throwsArgumentError,
      );
    });
  });

  group('SyncError Models & Serialization', () {
    test('creates recoverable and terminal errors correctly', () {
      final recoverable = SyncError.recoverable(
        message: 'Timeout',
        code: 'TIMEOUT',
      );
      expect(recoverable.isRecoverable, isTrue);
      expect(recoverable.code, 'TIMEOUT');

      final terminal = SyncError.terminal(
        message: 'Invalid BVN',
        code: 'INVALID_BVN',
      );
      expect(terminal.isRecoverable, isFalse);
    });

    test('serializes and deserializes SyncError to and from map', () {
      final timestamp = DateTime(2026, 9, 21, 12, 30);
      final error = SyncError(
        message: 'HTTP 503 Service Unavailable',
        code: 'SERVICE_UNAVAILABLE',
        isRecoverable: true,
        timestamp: timestamp,
      );

      final map = error.toMap();
      final deserialized = SyncError.fromMap(map);

      expect(deserialized, error);
      expect(deserialized.hashCode, error.hashCode);
    });
  });

  group('FinancialOperation Value Equality & CopyWith', () {
    test('implements value equality and hashCode', () {
      final now = DateTime(2026, 9, 21, 8, 0);
      final op1 = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
      );
      final op2 = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
      );

      expect(op1, op2);
      expect(op1.hashCode, op2.hashCode);
    });

    test('copyWith produces updated instance without mutating original', () {
      final op = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
      );

      final updated = op.copyWith(status: OperationStatus.processing);
      expect(op.status, OperationStatus.pending);
      expect(updated.status, OperationStatus.processing);
    });
  });
}
