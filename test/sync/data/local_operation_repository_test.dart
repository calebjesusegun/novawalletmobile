import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/sync/data/local_operation_repository.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  group('LocalOperationRepository Durable Enqueue (T-SYNC-001 & HC-OFFLINE-DURABILITY)', () {
    late AppDatabase db;
    late PendingOperationsDao dao;
    late LocalOperationRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      dao = PendingOperationsDao(db);
      repo = LocalOperationRepository(dao);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'durably enqueues a Send Money intent (ASM-009, SND-015, SYNC-002)',
      () async {
        final opId = OperationId.generate();
        final idKey = IdempotencyKey.generate();
        final payload = SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina Bello',
          bankName: 'Access Bank',
          amount: Money.fromNaira(5000), // 500,000 kobo
        );

        final persisted = await repo.enqueueSendMoney(
          id: opId,
          idempotencyKey: idKey,
          payload: payload,
        );

        expect(persisted.id, opId);
        expect(persisted.idempotencyKey, idKey);
        expect(persisted.type, OperationType.send);
        expect(persisted.status, OperationStatus.pending);
        expect(persisted.attemptCount, 0);
        expect(persisted.payload, payload);

        // Verify read-back from persistent store
        final fromDb = await repo.getOperationById(opId);
        expect(fromDb, isNotNull);
        expect(fromDb!.id, opId);
        expect(fromDb.idempotencyKey, idKey);
        expect((fromDb.payload as SendMoneyPayload).amount.kobo, 500000);
      },
    );

    test('durably enqueues a NovaSave Contribution intent (ASM-009, NSV-017, SYNC-002)', () async {
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      final payload = ContributionPayload(
        goalId: 'goal-macbook-pro-2026',
        goalName: 'New MacBook Pro',
        amount: Money.fromNaira(25000), // 2,500,000 kobo
      );

      final persisted = await repo.enqueueContribution(
        id: opId,
        idempotencyKey: idKey,
        payload: payload,
      );

      expect(persisted.id, opId);
      expect(persisted.idempotencyKey, idKey);
      expect(persisted.type, OperationType.contribution);
      expect(persisted.status, OperationStatus.pending);
      expect(persisted.attemptCount, 0);

      final fromDb = await repo.getOperationById(opId);
      expect(fromDb, isNotNull);
      expect(
        (fromDb!.payload as ContributionPayload).goalName,
        'New MacBook Pro',
      );
      expect((fromDb.payload as ContributionPayload).amount.kobo, 2500000);
    });

    test(
      'caller receives "saved" confirmation only after persistence succeeds',
      () async {
        final op = FinancialOperation.send(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1111222233',
            recipientName: 'Babatunde Raji',
            bankName: 'GTBank',
            amount: Money.fromNaira(1500),
          ),
        );

        final returned = await repo.enqueue(op);
        expect(returned.id, op.id);

        final inStorage = await repo.getOperationById(op.id);
        expect(inStorage, isNotNull);
        expect(inStorage!.id, returned.id);
      },
    );

    test('failed persistence never produces false saved acknowledgment on duplicate id', () async {
      final opId = OperationId.generate();
      final op1 = FinancialOperation.send(
        id: opId,
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Babatunde Raji',
          bankName: 'GTBank',
          amount: Money.fromNaira(1500),
        ),
      );

      await repo.enqueue(op1);

      // Attempting to enqueue second operation with duplicate OperationId MUST throw
      final op2WithSameId = FinancialOperation.send(
        id: opId,
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '9999888877',
          recipientName: 'Chidi Mokeme',
          bankName: 'UBA',
          amount: Money.fromNaira(2000),
        ),
      );

      await expectLater(
        () => repo.enqueue(op2WithSameId),
        throwsA(isA<Exception>()),
      );
    });

    test('failed persistence never produces false saved acknowledgment on duplicate idempotency key', () async {
      final idKey = IdempotencyKey.generate();
      final op1 = FinancialOperation.send(
        id: OperationId.generate(),
        idempotencyKey: idKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Babatunde Raji',
          bankName: 'GTBank',
          amount: Money.fromNaira(1500),
        ),
      );

      await repo.enqueue(op1);

      // Attempting to enqueue another operation with identical IdempotencyKey MUST throw
      final op2WithSameKey = FinancialOperation.send(
        id: OperationId.generate(),
        idempotencyKey: idKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Babatunde Raji',
          bankName: 'GTBank',
          amount: Money.fromNaira(1500),
        ),
      );

      await expectLater(
        () => repo.enqueue(op2WithSameKey),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects enqueuing operation that is not in pending status', () async {
      final claimedOp = FinancialOperation.send(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '1111222233',
          recipientName: 'Babatunde Raji',
          bankName: 'GTBank',
          amount: Money.fromNaira(1500),
        ),
      ).markProcessing();

      expect(() => repo.enqueue(claimedOp), throwsA(isA<StateError>()));
    });

    test(
      'supports atomic lifecycle state transitions via repository methods',
      () async {
        final opId = OperationId.generate();
        final idKey = IdempotencyKey.generate();
        await repo.enqueueSendMoney(
          id: opId,
          idempotencyKey: idKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '1234567890',
            recipientName: 'Tunde Bakare',
            bankName: 'First Bank',
            amount: Money.fromNaira(3000),
          ),
        );

        // Claim operation
        final claimed = await repo.claim(opId);
        expect(claimed, isTrue);

        final processingOp = await repo.getOperationById(opId);
        expect(processingOp!.status, OperationStatus.processing);
        expect(processingOp.attemptCount, 1);

        // Mark recoverable error -> reverts to pending
        final error = SyncError.recoverable(message: 'Network timed out');
        final erroredOp = await repo.markPendingWithError(opId, error: error);
        expect(erroredOp.status, OperationStatus.pending);
        expect(erroredOp.lastError, error);

        // Re-claim and complete
        final reClaimed = await repo.claim(opId);
        expect(reClaimed, isTrue);

        final completedOp = await repo.markCompleted(
          opId,
          remoteReference: 'REMOTE-REF-9988',
        );
        expect(completedOp.status, OperationStatus.completed);
        expect(completedOp.remoteReference, 'REMOTE-REF-9988');

        // Verify in persistent storage
        final fromDb = await repo.getOperationById(opId);
        expect(fromDb!.status, OperationStatus.completed);
        expect(fromDb.remoteReference, 'REMOTE-REF-9988');
      },
    );

    test(
      'recoverInterrupted resets in-flight processing operations to pending',
      () async {
        final opId = OperationId.generate();
        await repo.enqueueSendMoney(
          id: opId,
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1234567890',
            recipientName: 'Tunde Bakare',
            bankName: 'First Bank',
            amount: Money.fromNaira(3000),
          ),
        );

        await repo.claim(opId);
        expect(
          (await repo.getOperationById(opId))!.status,
          OperationStatus.processing,
        );

        final recoveredCount = await repo.recoverInterrupted();
        expect(recoveredCount, 1);

        final recoveredOp = await repo.getOperationById(opId);
        expect(recoveredOp!.status, OperationStatus.pending);
        expect(recoveredOp.attemptCount, 1); // preserved attempt count
      },
    );
  });

  group('Restart Simulation across connection cycles (ASM-012, SYNC-003, HC-OFFLINE-DURABILITY)', () {
    test('enqueued operations retain stable identities and payload across database reopen', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'novawallet_enqueue_restart_test_',
      );
      final dbFile = File('${tempDir.path}/queue_restart.db');
      final opId = OperationId.generate();
      final idKey = IdempotencyKey.generate();
      final payload = SendMoneyPayload(
        recipientAccountNumber: '0987654321',
        recipientName: 'Folake Solanke',
        bankName: 'Zenith Bank',
        amount: Money.fromNaira(45000), // 4,500,000 kobo
      );

      // Connection cycle 1: Enqueue intent while offline
      {
        final db1 = AppDatabase.forFile(dbFile);
        final repo1 = LocalOperationRepository(PendingOperationsDao(db1));

        final enqueued = await repo1.enqueueSendMoney(
          id: opId,
          idempotencyKey: idKey,
          payload: payload,
        );
        expect(enqueued.status, OperationStatus.pending);

        await db1.close();
      }

      // Connection cycle 2: Restart process, reopen database file
      {
        final db2 = AppDatabase.forFile(dbFile);
        final repo2 = LocalOperationRepository(PendingOperationsDao(db2));

        final restored = await repo2.getOperationById(opId);
        expect(restored, isNotNull);
        expect(restored!.id, opId);
        expect(restored.idempotencyKey, idKey);
        expect(restored.status, OperationStatus.pending);
        expect(restored.attemptCount, 0);

        final restoredPayload = restored.payload as SendMoneyPayload;
        expect(restoredPayload.recipientAccountNumber, '0987654321');
        expect(restoredPayload.recipientName, 'Folake Solanke');
        expect(restoredPayload.bankName, 'Zenith Bank');
        expect(restoredPayload.amount.kobo, 4500000);

        await db2.close();
      }

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Sync Riverpod Providers (T-SYNC-001)', () {
    test(
      'operationRepositoryProvider and stream providers update reactively',
      () async {
        final inMemoryDb = AppDatabase.inMemory();
        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(inMemoryDb)],
        );

        addTearDown(() async {
          container.dispose();
          await inMemoryDb.close();
        });

        final repo = container.read(operationRepositoryProvider);
        expect(repo, isA<LocalOperationRepository>());

        final pendingUpdates = <List<FinancialOperation>>[];
        final sub = container.listen<AsyncValue<List<FinancialOperation>>>(
          pendingOperationsStreamProvider,
          (prev, next) => next.whenData(pendingUpdates.add),
        );
        addTearDown(sub.close);

        await Future<void>.delayed(Duration.zero);
        expect(pendingUpdates.last, isEmpty);

        // Enqueue an operation
        await repo.enqueueSendMoney(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '1234567890',
            recipientName: 'Test Recipient',
            bankName: 'Access Bank',
            amount: Money.fromNaira(2000),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        expect(pendingUpdates.last.length, 1);
        expect(pendingUpdates.last.first.payload.type, OperationType.send);
      },
    );
  });
}
