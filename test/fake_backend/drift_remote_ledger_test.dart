import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/fake_backend/data/drift_remote_ledger.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novawallet_remote_test_');
    dbFile = File('${tempDir.path}/remote_test.sqlite');
    db = AppDatabase.forFile(dbFile);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DriftRemoteLedger — Restart Recovery Simulation (ASM-011, ASM-013, docs/ARCHITECTURE.md §11.4)', () {
    test('idempotency record survives database close and reopen without duplicate debit', () async {
      final ledger1 = DriftRemoteLedger(
        db,
        initialBalance: const Money.fromKobo(5000000), // ₦50,000.00
      );
      final remote1 = FakeRemoteApi(ledger: ledger1);

      final op = FinancialOperation.send(
        id: OperationId('op-restart-1'),
        idempotencyKey: IdempotencyKey('idem-restart-key-1'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Babatunde Ojo',
          bankName: 'FirstBank',
          amount: const Money.fromKobo(1500000), // ₦15,000.00
        ),
      );

      // Submit before app restart
      final result1 = await remote1.sendMoney(op);
      expect(result1.isDuplicate, isFalse);
      expect(result1.debitAmount, const Money.fromKobo(1500000));

      // Balance before close: ₦35,000.00
      final snapshot1 = await remote1.fetchWalletSnapshot();
      expect(snapshot1.balance, const Money.fromKobo(3500000));

      // SIMULATE APP RESTART: close database connection
      await db.close();

      // Open new database connection from the same file
      db = AppDatabase.forFile(dbFile);
      final ledger2 = DriftRemoteLedger(db);
      final remote2 = FakeRemoteApi(ledger: ledger2);

      // Authoritative remote balance survived restart
      final snapshot2 = await remote2.fetchWalletSnapshot();
      expect(snapshot2.balance, const Money.fromKobo(3500000));

      // Replay operation after restart (e.g. sync engine recovering queued pending item)
      final result2 = await remote2.sendMoney(op);
      expect(result2.isDuplicate, isTrue);
      expect(result2.remoteReference, result1.remoteReference);
      expect(
        result2.settledAt.millisecondsSinceEpoch,
        result1.settledAt.millisecondsSinceEpoch,
      );

      // Verify NO second debit occurred
      final snapshot3 = await remote2.fetchWalletSnapshot();
      expect(snapshot3.balance, const Money.fromKobo(3500000));

      // Verify transaction list contains exactly 1 entry
      final txns = await remote2.fetchTransactions();
      expect(txns.length, 1);
      expect(txns.first.id, result1.remoteReference);
    });

    test('detects conflicting payload reuse after app restart', () async {
      final ledger1 = DriftRemoteLedger(
        db,
        initialBalance: const Money.fromKobo(5000000),
      );
      final remote1 = FakeRemoteApi(ledger: ledger1);

      final key = IdempotencyKey('restart-conflict-key');
      final originalOp = FinancialOperation.send(
        id: OperationId('op-orig'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Babatunde Ojo',
          bankName: 'FirstBank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      await remote1.sendMoney(originalOp);

      // Restart
      await db.close();
      db = AppDatabase.forFile(dbFile);
      final ledger2 = DriftRemoteLedger(db);
      final remote2 = FakeRemoteApi(ledger: ledger2);

      // Submit conflicting operation with same key
      final conflictingOp = FinancialOperation.send(
        id: OperationId('op-conflict'),
        idempotencyKey: key,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Babatunde Ojo',
          bankName: 'FirstBank',
          amount: const Money.fromKobo(2000000), // Different amount!
        ),
      );

      expect(
        () => remote2.sendMoney(conflictingOp),
        throwsA(isA<ConflictingIdempotencyKeyException>()),
      );
    });

    test('concurrent sendMoney calls with identical key against SQLite ledger deduplicate atomically', () async {
      final ledger = DriftRemoteLedger(
        db,
        initialBalance: const Money.fromKobo(10000000), // ₦100,000.00
      );
      final remote = FakeRemoteApi(ledger: ledger);

      final op = FinancialOperation.send(
        id: OperationId('op-drift-concurrent'),
        idempotencyKey: IdempotencyKey('idem-drift-concurrent'),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Babatunde Ojo',
          bankName: 'FirstBank',
          amount: const Money.fromKobo(2000000), // ₦20,000.00
        ),
      );

      final results = await Future.wait([
        remote.sendMoney(op),
        remote.sendMoney(op),
      ]);

      final initialResults = results.where((r) => !r.isDuplicate).toList();
      final duplicateResults = results.where((r) => r.isDuplicate).toList();

      expect(initialResults.length, 1);
      expect(duplicateResults.length, 1);
      expect(
        duplicateResults.first.remoteReference,
        initialResults.first.remoteReference,
      );

      final snapshot = await remote.fetchWalletSnapshot();
      expect(snapshot.balance, const Money.fromKobo(8000000));

      final txns = await remote.fetchTransactions();
      expect(txns.length, 1);
    });
  });
}
