import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  group('PendingOperations Drift Persistence (T-DB-001 & HC-OFFLINE-DURABILITY)', () {
    late AppDatabase db;
    late PendingOperationsDao dao;

    setUp(() {
      db = AppDatabase.inMemory();
      dao = PendingOperationsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Insert and load pending Send Money operation preserves exact values',
      () async {
        final id = OperationId.generate();
        final idempotencyKey = IdempotencyKey.generate();
        final amount = Money.fromNaira(15000); // 1,500,000 kobo
        final now = DateTime.now().toUtc();

        final operation = FinancialOperation.send(
          id: id,
          idempotencyKey: idempotencyKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Musa Bello',
            bankName: 'FirstBank',
            amount: amount,
            narration: 'Groceries',
          ),
          createdAt: now,
        );

        await dao.insertOperation(operation);

        final loaded = await dao.getOperationById(id);
        expect(loaded, isNotNull);
        expect(loaded!.id, equals(id));
        expect(loaded.type, equals(OperationType.send));
        expect(loaded.idempotencyKey, equals(idempotencyKey));
        expect(loaded.status, equals(OperationStatus.pending));
        expect(loaded.attemptCount, equals(0));
        expect(
          loaded.createdAt.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
        expect(loaded.lastAttemptAt, isNull);
        expect(loaded.lastError, isNull);
        expect(loaded.remoteReference, isNull);
        expect(loaded.completedAt, isNull);

        // Verify payload and exact integer kobo
        final payload = loaded.payload as SendMoneyPayload;
        expect(payload.amount.kobo, equals(1500000));
        expect(payload.recipientAccountNumber, equals('0123456789'));
        expect(payload.recipientName, equals('Musa Bello'));
        expect(payload.bankName, equals('FirstBank'));
        expect(payload.narration, equals('Groceries'));
        expect(payload.schemaVersion, equals(1));
      },
    );

    test(
      'Insert and load pending Contribution operation preserves exact values',
      () async {
        final id = OperationId.generate();
        final idempotencyKey = IdempotencyKey.generate();
        final amount = Money.fromNaira(50000); // 5,000,000 kobo
        final now = DateTime.now().toUtc();

        final operation = FinancialOperation.contribution(
          id: id,
          idempotencyKey: idempotencyKey,
          payload: ContributionPayload(
            goalId: 'goal-uuid-1234',
            goalName: 'Emergency Fund',
            amount: amount,
          ),
          createdAt: now,
        );

        await dao.insertOperation(operation);

        final loadedByKey = await dao.getOperationByIdempotencyKey(
          idempotencyKey,
        );
        expect(loadedByKey, isNotNull);
        expect(loadedByKey!.id, equals(id));
        expect(loadedByKey.type, equals(OperationType.contribution));
        expect(loadedByKey.idempotencyKey, equals(idempotencyKey));
        expect(loadedByKey.status, equals(OperationStatus.pending));

        final payload = loadedByKey.payload as ContributionPayload;
        expect(payload.amount.kobo, equals(5000000));
        expect(payload.goalId, equals('goal-uuid-1234'));
        expect(payload.goalName, equals('Emergency Fund'));
      },
    );

    test('Enforces uniqueness of idempotencyKey', () async {
      final id1 = OperationId.generate();
      final id2 = OperationId.generate();
      final sharedKey = IdempotencyKey.generate();

      final op1 = FinancialOperation.send(
        id: id1,
        idempotencyKey: sharedKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111111111',
          recipientName: 'Alice',
          bankName: 'Bank A',
          amount: Money.fromNaira(1000),
        ),
      );

      final op2 = FinancialOperation.send(
        id: id2,
        idempotencyKey: sharedKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '2222222222',
          recipientName: 'Bob',
          bankName: 'Bank B',
          amount: Money.fromNaira(2000),
        ),
      );

      await dao.insertOperation(op1);
      // Inserting second operation with same idempotency key must throw
      expect(() => dao.insertOperation(op2), throwsException);
    });

    test(
      'Atomic claimOperation succeeds once and increments attempt count',
      () async {
        final id = OperationId.generate();
        final op = FinancialOperation.send(
          id: id,
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1234567890',
            recipientName: 'John',
            bankName: 'GTBank',
            amount: Money.fromNaira(5000),
          ),
        );

        await dao.insertOperation(op);

        final claimTime = DateTime.utc(2026, 9, 21, 12, 0, 0);
        final claimed1 = await dao.claimOperation(id, at: claimTime);
        expect(claimed1, isTrue);

        // Second claim attempt must fail because status is now 'processing'
        final claimed2 = await dao.claimOperation(id, at: claimTime);
        expect(claimed2, isFalse);

        final afterClaim = await dao.getOperationById(id);
        expect(afterClaim!.status, equals(OperationStatus.processing));
        expect(afterClaim.attemptCount, equals(1));
        expect(afterClaim.lastAttemptAt, equals(claimTime));
      },
    );

    test(
      'Updates operation through full lifecycle states with recoverable error',
      () async {
        final id = OperationId.generate();
        var op = FinancialOperation.send(
          id: id,
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1234567890',
            recipientName: 'John',
            bankName: 'Access Bank',
            amount: Money.fromNaira(5000),
          ),
          createdAt: DateTime.utc(2026, 9, 21, 9, 59, 0),
        );

        await dao.insertOperation(op);

        // 1. Transition to processing
        op = op.markProcessing(at: DateTime.utc(2026, 9, 21, 10, 0, 0));
        await dao.updateOperation(op);

        var persisted = await dao.getOperationById(id);
        expect(persisted!.status, equals(OperationStatus.processing));
        expect(persisted.attemptCount, equals(1));

        // 2. Recoverable error transition (e.g. network timeout)
        final error = SyncError.recoverable(
          message: 'Connection timed out',
          code: 'NETWORK_TIMEOUT',
          timestamp: DateTime.utc(2026, 9, 21, 10, 0, 5),
        );
        op = op.markRecoverableError(error: error);
        await dao.updateOperation(op);

        persisted = await dao.getOperationById(id);
        expect(persisted!.status, equals(OperationStatus.pending));
        expect(persisted.attemptCount, equals(1));
        expect(persisted.lastError, isNotNull);
        expect(persisted.lastError!.message, equals('Connection timed out'));
        expect(persisted.lastError!.code, equals('NETWORK_TIMEOUT'));
        expect(persisted.lastError!.isRecoverable, isTrue);

        // 3. Retry -> processing -> completed
        op = op.markProcessing(at: DateTime.utc(2026, 9, 21, 10, 5, 0));
        expect(op.lastError, isNull); // cleared on new attempt
        await dao.updateOperation(op);

        op = op.markCompleted(
          remoteReference: 'REMOTE-REF-998877',
          at: DateTime.utc(2026, 9, 21, 10, 5, 2),
        );
        await dao.updateOperation(op);

        persisted = await dao.getOperationById(id);
        expect(persisted!.status, equals(OperationStatus.completed));
        expect(persisted.remoteReference, equals('REMOTE-REF-998877'));
        expect(
          persisted.completedAt,
          equals(DateTime.utc(2026, 9, 21, 10, 5, 2)),
        );
        expect(persisted.isTerminal, isTrue);
      },
    );

    test(
      'getPendingOperations and getActiveOperations return correct subsets',
      () async {
        final op1 = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1',
            recipientName: 'User 1',
            bankName: 'Bank 1',
            amount: Money.fromNaira(100),
          ),
          createdAt: DateTime.utc(2026, 9, 21, 1, 0, 0),
        );

        var op2 = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '2',
            recipientName: 'User 2',
            bankName: 'Bank 2',
            amount: Money.fromNaira(200),
          ),
          createdAt: DateTime.utc(2026, 9, 21, 2, 0, 0),
        );
        op2 = op2.markProcessing();

        var op3 = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '3',
            recipientName: 'User 3',
            bankName: 'Bank 3',
            amount: Money.fromNaira(300),
          ),
          createdAt: DateTime.utc(2026, 9, 21, 3, 0, 0),
        );
        op3 = op3.markProcessing().markCompleted(remoteReference: 'REF-3');

        await dao.insertOperation(op1);
        await dao.insertOperation(op2);
        await dao.insertOperation(op3);

        final pending = await dao.getPendingOperations();
        expect(pending.length, equals(1));
        expect(pending.first.id, equals(op1.id));

        final active = await dao.getActiveOperations();
        expect(active.length, equals(2));
        expect(active.map((o) => o.id), containsAll([op1.id, op2.id]));

        final all = await dao.getAllOperations();
        expect(all.length, equals(3));
      },
    );

    test(
      'recoverInterruptedOperations resets processing operations to pending',
      () async {
        var op1 = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1',
            recipientName: 'User 1',
            bankName: 'Bank 1',
            amount: Money.fromNaira(100),
          ),
        );
        op1 = op1.markProcessing();

        final op2 = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '2',
            recipientName: 'User 2',
            bankName: 'Bank 2',
            amount: Money.fromNaira(200),
          ),
        );

        await dao.insertOperation(op1);
        await dao.insertOperation(op2);

        final recoveredCount = await dao.recoverInterruptedOperations();
        expect(recoveredCount, equals(1));

        final recoveredOp1 = await dao.getOperationById(op1.id);
        expect(recoveredOp1!.status, equals(OperationStatus.pending));
        expect(recoveredOp1.attemptCount, equals(1)); // preserved attempt count
        expect(
          recoveredOp1.idempotencyKey,
          equals(op1.idempotencyKey),
        ); // preserved stable key
      },
    );
  });

  group('Restart Simulation across connection cycles (HC-OFFLINE-DURABILITY & SYNC-003)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('novawallet_test_');
      dbFile = File('${tempDir.path}/restart_test.sqlite');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'Persisted operations survive database close and file reopen',
      () async {
        final opId = OperationId.generate();
        final key = IdempotencyKey.generate();
        final amount = Money.fromNaira(25000);
        final createdTime = DateTime.utc(2026, 9, 21, 14, 30, 0);

        // 1. First connection: write pending operation and close DB
        {
          final db1 = AppDatabase.forFile(dbFile);
          final dao1 = PendingOperationsDao(db1);

          final op = FinancialOperation.send(
            id: opId,
            idempotencyKey: key,
            payload: SendMoneyPayload(
              recipientAccountNumber: '0987654321',
              recipientName: 'Chioma Adebayo',
              bankName: 'Zenith Bank',
              amount: amount,
              narration: 'Project payment',
            ),
            createdAt: createdTime,
          );

          await dao1.insertOperation(op);
          await db1.close();
        }

        // 2. Second connection: reopen the exact same database file and verify recovery
        {
          final db2 = AppDatabase.forFile(dbFile);
          final dao2 = PendingOperationsDao(db2);

          final loaded = await dao2.getOperationById(opId);
          expect(loaded, isNotNull);
          expect(loaded!.id, equals(opId));
          expect(loaded.idempotencyKey, equals(key));
          expect(loaded.status, equals(OperationStatus.pending));
          expect(loaded.createdAt, equals(createdTime));

          final payload = loaded.payload as SendMoneyPayload;
          expect(payload.amount.kobo, equals(2500000));
          expect(payload.recipientAccountNumber, equals('0987654321'));
          expect(payload.recipientName, equals('Chioma Adebayo'));
          expect(payload.bankName, equals('Zenith Bank'));
          expect(payload.narration, equals('Project payment'));

          // Progress the operation on this second connection
          final updatedOp = loaded.markProcessing().markCompleted(
            remoteReference: 'ZENITH-TX-5544',
          );
          await dao2.updateOperation(updatedOp);
          await db2.close();
        }

        // 3. Third connection: verify that completed status and remote reference persisted
        {
          final db3 = AppDatabase.forFile(dbFile);
          final dao3 = PendingOperationsDao(db3);

          final reloaded = await dao3.getOperationById(opId);
          expect(reloaded, isNotNull);
          expect(reloaded!.status, equals(OperationStatus.completed));
          expect(reloaded.remoteReference, equals('ZENITH-TX-5544'));
          expect(reloaded.attemptCount, equals(1));

          await db3.close();
        }
      },
    );
  });
}
