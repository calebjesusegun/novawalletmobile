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
      expect(op.reservesFunds, isTrue);
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
      expect(op.reservesFunds, isTrue);
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

        final attemptTime = DateTime.utc(2026, 9, 21, 10, 0);
        final claimed = initial.markProcessing(at: attemptTime);

        expect(claimed.status, OperationStatus.processing);
        expect(claimed.isProcessing, isTrue);
        expect(claimed.attemptCount, 1);
        expect(claimed.lastAttemptAt, attemptTime);
        expect(claimed.id, testOpId); // ID remains stable
        expect(claimed.idempotencyKey, testKey); // Key remains stable
        expect(claimed.reservesFunds, isTrue);
      });

      test('recovering interrupted operation returns to pending with preserved attempts and key', () {
        final processing = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing();

        expect(processing.attemptCount, 1);
        expect(processing.status, OperationStatus.processing);

        // App crashes or restarts while processing -> recover interrupted
        final recovered = processing.recoverInterrupted();

        expect(recovered.status, OperationStatus.pending);
        expect(recovered.isPending, isTrue);
        expect(recovered.attemptCount, 1); // Preserves attempt count
        expect(recovered.idempotencyKey, testKey); // Preserves stable key
        expect(recovered.id, testOpId);
        expect(recovered.isEligibleForSync, isTrue);
      });

      test(
        'transitions from processing to completed upon remote settlement',
        () {
          final processing = FinancialOperation.send(
            id: testOpId,
            idempotencyKey: testKey,
            payload: createSendPayload(),
          ).markProcessing();

          final completionTime = DateTime.utc(2026, 9, 21, 10, 5);
          final completed = processing.markCompleted(
            remoteReference: '  TXN-SETTLED-999  ',
            at: completionTime,
          );

          expect(completed.status, OperationStatus.completed);
          expect(completed.isCompleted, isTrue);
          expect(completed.isTerminal, isTrue);
          expect(completed.remoteReference, 'TXN-SETTLED-999'); // Trimmed
          expect(completed.completedAt, completionTime);
          expect(completed.lastError, isNull);
          expect(completed.reservesFunds, isFalse);
        },
      );

      test('recoverable error transitions back to pending and records error metadata', () {
        final processing = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        ).markProcessing();

        final errorTime = DateTime.utc(2026, 9, 21, 10, 10);
        final syncError = SyncError.recoverable(
          message: 'Connection timed out while sending transfer',
          code: 'NETWORK_TIMEOUT',
          timestamp: errorTime,
        );

        final returnedToPending = processing.markRecoverableError(
          error: syncError,
          at: errorTime,
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
        expect(returnedToPending.reservesFunds, isTrue);

        // Stable identities are strictly preserved across retry recovery
        expect(returnedToPending.id, testOpId);
        expect(returnedToPending.idempotencyKey, testKey);
      });

      test(
        'terminal error transitions to failed state and releases reservation',
        () {
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
          expect(failed.reservesFunds, isFalse);
        },
      );

      test('identity preservation across complete lifecycle', () {
        // 1. Created
        final op1 = FinancialOperation.send(
          id: testOpId,
          idempotencyKey: testKey,
          payload: createSendPayload(),
        );
        expect(op1.id, testOpId);
        expect(op1.idempotencyKey, testKey);

        // 2. Claimed (attempt 1)
        final op2 = op1.markProcessing();
        expect(op2.id, testOpId);
        expect(op2.idempotencyKey, testKey);

        // 3. Interrupted & recovered
        final op3 = op2.recoverInterrupted();
        expect(op3.id, testOpId);
        expect(op3.idempotencyKey, testKey);

        // 4. Claimed (attempt 2)
        final op4 = op3.markProcessing();
        expect(op4.id, testOpId);
        expect(op4.idempotencyKey, testKey);

        // 5. Transient error (returns to pending)
        final op5 = op4.markRecoverableError(
          error: SyncError.recoverable(message: 'Timeout'),
        );
        expect(op5.id, testOpId);
        expect(op5.idempotencyKey, testKey);

        // 6. Claimed (attempt 3)
        final op6 = op5.markProcessing();
        expect(op6.id, testOpId);
        expect(op6.idempotencyKey, testKey);

        // 7. Settled
        final op7 = op6.markCompleted(remoteReference: 'REF-FINAL');
        expect(op7.id, testOpId);
        expect(op7.idempotencyKey, testKey);
      });
    },
  );

  group('Strict State Transition Matrix (P1 & P2 Guards)', () {
    final pendingOp = FinancialOperation.send(
      id: testOpId,
      idempotencyKey: testKey,
      payload: createSendPayload(),
    );
    final processingOp = pendingOp.markProcessing();
    final completedOp = processingOp.markCompleted(remoteReference: 'REF-1');
    final failedOp = processingOp.markTerminalFailure(
      error: SyncError.terminal(message: 'Fatal'),
    );

    test('Pending state transitions', () {
      // Allowed: markProcessing
      expect(pendingOp.markProcessing, returnsNormally);

      // Forbidden from pending:
      expect(
        pendingOp.recoverInterrupted,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => pendingOp.markCompleted(remoteReference: 'REF'),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => pendingOp.markRecoverableError(
          error: SyncError.recoverable(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => pendingOp.markTerminalFailure(
          error: SyncError.terminal(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('Processing state transitions', () {
      // Forbidden from processing: double markProcessing (concurrent duplicate claim)
      expect(
        processingOp.markProcessing,
        throwsA(isA<InvalidOperationTransitionException>()),
      );

      // Allowed from processing:
      expect(processingOp.recoverInterrupted, returnsNormally);
      expect(
        () => processingOp.markCompleted(remoteReference: 'REF'),
        returnsNormally,
      );
      expect(
        () => processingOp.markRecoverableError(
          error: SyncError.recoverable(message: 'err'),
        ),
        returnsNormally,
      );
      expect(
        () => processingOp.markTerminalFailure(
          error: SyncError.terminal(message: 'err'),
        ),
        returnsNormally,
      );
    });

    test('Completed state rejects all transitions (terminal state)', () {
      expect(
        completedOp.markProcessing,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        completedOp.recoverInterrupted,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => completedOp.markCompleted(remoteReference: 'REF-2'),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => completedOp.markRecoverableError(
          error: SyncError.recoverable(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => completedOp.markTerminalFailure(
          error: SyncError.terminal(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('Failed state rejects all transitions (terminal state)', () {
      expect(
        failedOp.markProcessing,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        failedOp.recoverInterrupted,
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => failedOp.markCompleted(remoteReference: 'REF'),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => failedOp.markRecoverableError(
          error: SyncError.recoverable(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
      expect(
        () => failedOp.markTerminalFailure(
          error: SyncError.terminal(message: 'err'),
        ),
        throwsA(isA<InvalidOperationTransitionException>()),
      );
    });

    test('Transition argument validations', () {
      // Empty/whitespace remoteReference
      expect(
        () => processingOp.markCompleted(remoteReference: ''),
        throwsArgumentError,
      );
      expect(
        () => processingOp.markCompleted(remoteReference: '   '),
        throwsArgumentError,
      );

      // Terminal error passed to markRecoverableError
      expect(
        () => processingOp.markRecoverableError(
          error: SyncError.terminal(message: 'Terminal'),
        ),
        throwsArgumentError,
      );

      // Recoverable error passed to markTerminalFailure (prevents accidental terminal failure)
      expect(
        () => processingOp.markTerminalFailure(
          error: SyncError.recoverable(message: 'Recoverable'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('FinancialOperation.restore Rehydration Snapshot Validations', () {
    final now = DateTime.utc(2026, 9, 21, 8, 0);

    test('restores valid snapshots across all states', () {
      // Pending
      final restoredPending = FinancialOperation.restore(
        id: testOpId,
        type: OperationType.send,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
        status: OperationStatus.pending,
        attemptCount: 0,
      );
      expect(restoredPending.isPending, isTrue);

      // Processing
      final restoredProcessing = FinancialOperation.restore(
        id: testOpId,
        type: OperationType.send,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
        status: OperationStatus.processing,
        attemptCount: 1,
        lastAttemptAt: now,
      );
      expect(restoredProcessing.isProcessing, isTrue);

      // Completed
      final restoredCompleted = FinancialOperation.restore(
        id: testOpId,
        type: OperationType.send,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
        status: OperationStatus.completed,
        attemptCount: 1,
        lastAttemptAt: now,
        remoteReference: 'REF-OK',
        completedAt: now.add(const Duration(minutes: 1)),
      );
      expect(restoredCompleted.isCompleted, isTrue);

      // Failed
      final restoredFailed = FinancialOperation.restore(
        id: testOpId,
        type: OperationType.send,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: now,
        status: OperationStatus.failed,
        attemptCount: 1,
        lastAttemptAt: now,
        lastError: SyncError.terminal(message: 'Rejected by bank'),
      );
      expect(restoredFailed.isFailed, isTrue);
    });

    test('rejects negative attemptCount', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.pending,
          attemptCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects mismatched payload and operation type', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.contribution,
          idempotencyKey: testKey,
          payload: createSendPayload(), // type is send
          createdAt: now,
          status: OperationStatus.pending,
          attemptCount: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects pending operation carrying completion metadata', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.pending,
          attemptCount: 0,
          remoteReference: 'REF-ILLEGAL',
        ),
        throwsArgumentError,
      );

      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.pending,
          attemptCount: 0,
          completedAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects pending operation carrying terminal error', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.pending,
          attemptCount: 0,
          lastError: SyncError.terminal(message: 'Terminal failure'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects processing operation with attemptCount == 0 or carrying remoteReference', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.processing,
          attemptCount: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.processing,
          attemptCount: 1,
          remoteReference: 'REF-ILLEGAL',
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects completed operation missing remoteReference or completedAt',
      () {
        expect(
          () => FinancialOperation.restore(
            id: testOpId,
            type: OperationType.send,
            idempotencyKey: testKey,
            payload: createSendPayload(),
            createdAt: now,
            status: OperationStatus.completed,
            attemptCount: 1,
            remoteReference: null,
            completedAt: now,
          ),
          throwsArgumentError,
        );

        expect(
          () => FinancialOperation.restore(
            id: testOpId,
            type: OperationType.send,
            idempotencyKey: testKey,
            payload: createSendPayload(),
            createdAt: now,
            status: OperationStatus.completed,
            attemptCount: 1,
            remoteReference: 'REF-OK',
            completedAt: null,
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects completed operation with completedAt before createdAt', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.completed,
          attemptCount: 1,
          remoteReference: 'REF-OK',
          completedAt: now.subtract(const Duration(minutes: 5)),
        ),
        throwsArgumentError,
      );
    });

    test('rejects completed operation carrying an error', () {
      expect(
        () => FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testKey,
          payload: createSendPayload(),
          createdAt: now,
          status: OperationStatus.completed,
          attemptCount: 1,
          remoteReference: 'REF-OK',
          completedAt: now,
          lastError: SyncError.terminal(message: 'Error'),
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects failed operation missing error or carrying recoverable error',
      () {
        // Missing error
        expect(
          () => FinancialOperation.restore(
            id: testOpId,
            type: OperationType.send,
            idempotencyKey: testKey,
            payload: createSendPayload(),
            createdAt: now,
            status: OperationStatus.failed,
            attemptCount: 1,
            lastError: null,
          ),
          throwsArgumentError,
        );

        // Carrying recoverable error (must be terminal error)
        expect(
          () => FinancialOperation.restore(
            id: testOpId,
            type: OperationType.send,
            idempotencyKey: testKey,
            payload: createSendPayload(),
            createdAt: now,
            status: OperationStatus.failed,
            attemptCount: 1,
            lastError: SyncError.recoverable(message: 'Transient timeout'),
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('FinancialOperation Value Equality & Timestamp Normalization', () {
    test('implements value equality and hashCode across UTC and equivalent local timestamps', () {
      final utcTime = DateTime.utc(2026, 9, 21, 8, 0);
      final localTime = utcTime.toLocal();

      final op1 = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: utcTime,
      );
      final op2 = FinancialOperation.send(
        id: testOpId,
        idempotencyKey: testKey,
        payload: createSendPayload(),
        createdAt: localTime,
      );

      expect(op1, op2);
      expect(op1.hashCode, op2.hashCode);
    });
  });
}
