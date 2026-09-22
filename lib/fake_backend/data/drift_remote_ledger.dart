import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_idempotency_ledger.dart';
import 'package:novawallet/fake_backend/remote_idempotency_record.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

/// Drift/SQLite-backed implementation of [RemoteIdempotencyLedger].
///
/// Implements requirement SYNC-008, ASM-011, ASM-013, and docs/ARCHITECTURE.md §11.4:
/// The fake remote's server-side ledger survives process restarts during
/// simulation and integration tests while maintaining a strict persistence boundary
/// (client repositories never touch these tables directly).
class DriftRemoteLedger implements RemoteIdempotencyLedger {
  final AppDatabase _db;
  final Money _initialBalance;

  /// Default initial balance is ₦125,450.00 (12,545,000 kobo) matching design baseline.
  static const Money defaultInitialBalance = Money.fromKobo(12545000);

  DriftRemoteLedger(this._db, {Money? initialBalance})
    : _initialBalance = initialBalance ?? defaultInitialBalance;

  @override
  Future<RemoteIdempotencyRecord?> getRecord(String idempotencyKey) async {
    final query = _db.select(_db.remoteIdempotencyTable)
      ..where((t) => t.idempotencyKey.equals(idempotencyKey));
    final entry = await query.getSingleOrNull();

    if (entry == null) return null;

    final payloadMap = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final metadataMap = entry.metadataJson != null
        ? jsonDecode(entry.metadataJson!) as Map<String, dynamic>
        : const <String, dynamic>{};

    final result = RemoteOperationResult(
      remoteReference: entry.remoteReference,
      settledAt: DateTime.fromMillisecondsSinceEpoch(
        entry.settledAt.toInt(),
        isUtc: true,
      ),
      debitAmount: Money.fromKobo(entry.debitAmountKobo.toInt()),
      isDuplicate: true,
      metadata: metadataMap,
    );

    return RemoteIdempotencyRecord(
      idempotencyKey: entry.idempotencyKey,
      operationId: entry.operationId,
      operationType: entry.operationType,
      payload: payloadMap,
      result: result,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        entry.recordedAt.toInt(),
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> saveRecord(RemoteIdempotencyRecord record) async {
    final metadataJson = record.result.metadata.isNotEmpty
        ? jsonEncode(record.result.metadata)
        : null;

    await _db
        .into(_db.remoteIdempotencyTable)
        .insertOnConflictUpdate(
          RemoteIdempotencyTableCompanion.insert(
            idempotencyKey: record.idempotencyKey,
            operationId: record.operationId,
            operationType: record.operationType,
            payloadJson: jsonEncode(record.payload),
            remoteReference: record.result.remoteReference,
            debitAmountKobo: BigInt.from(record.result.debitAmount.kobo),
            settledAt: BigInt.from(
              record.result.settledAt.toUtc().millisecondsSinceEpoch,
            ),
            recordedAt: BigInt.from(
              record.recordedAt.toUtc().millisecondsSinceEpoch,
            ),
            metadataJson: Value(metadataJson),
          ),
        );
  }

  @override
  Future<Money> getBalance() async {
    final query = _db.select(_db.remoteWalletStateTable)
      ..where((t) => t.id.equals(1));
    final entry = await query.getSingleOrNull();

    if (entry != null) {
      if (entry.balanceKobo == BigInt.from(25000000)) {
        await setBalance(_initialBalance);
        return _initialBalance;
      }
      return Money.fromKobo(entry.balanceKobo.toInt());
    }

    // Initialize balance if not yet seeded
    await setBalance(_initialBalance);
    return _initialBalance;
  }

  @override
  Future<void> setBalance(Money balance) async {
    final nowMs = BigInt.from(DateTime.now().toUtc().millisecondsSinceEpoch);
    await _db
        .into(_db.remoteWalletStateTable)
        .insertOnConflictUpdate(
          RemoteWalletStateTableCompanion.insert(
            id: const Value(1),
            balanceKobo: BigInt.from(balance.kobo),
            lastUpdatedAt: nowMs,
          ),
        );
  }

  @override
  Future<void> addTransaction(WalletTransaction transaction) async {
    await _db
        .into(_db.remoteTransactionsTable)
        .insertOnConflictUpdate(
          RemoteTransactionsTableCompanion.insert(
            id: transaction.id,
            transactionType: transaction.type.name,
            amountKobo: BigInt.from(transaction.amount.kobo),
            counterparty: transaction.counterparty,
            createdAt: BigInt.from(
              transaction.createdAt.toUtc().millisecondsSinceEpoch,
            ),
            status: Value(transaction.status.name),
            reference: Value(transaction.reference),
            narration: Value(transaction.narration),
          ),
        );
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _db.select(_db.remoteTransactionsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);

    final entries = await query.get();
    return entries
        .map((entry) {
          return WalletTransaction(
            id: entry.id,
            type: TransactionType.values.byName(entry.transactionType),
            amount: Money.fromKobo(entry.amountKobo.toInt()),
            counterparty: entry.counterparty,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              entry.createdAt.toInt(),
              isUtc: true,
            ),
            status: TransactionStatus.values.byName(entry.status),
            reference: entry.reference,
            narration: entry.narration,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<RemoteOperationResult> executeAtomicOperation({
    required String idempotencyKey,
    required OperationPayload payload,
    required Money debitAmount,
    required WalletTransaction transaction,
    required RemoteIdempotencyRecord record,
  }) async {
    try {
      return await _db.transaction(() async {
        final existing = await getRecord(idempotencyKey);
        if (existing != null) {
          if (!existing.matchesPayload(payload)) {
            throw ConflictingIdempotencyKeyException(
              idempotencyKey: idempotencyKey,
            );
          }
          return existing.result.copyWith(isDuplicate: true);
        }

        final currentBalance = await getBalance();
        if (currentBalance.kobo < debitAmount.kobo) {
          throw InsufficientRemoteFundsException(
            requestedKobo: debitAmount.kobo,
            availableKobo: currentBalance.kobo,
          );
        }

        await setBalance(currentBalance - debitAmount);
        await addTransaction(transaction);
        await saveRecord(record);

        return record.result;
      });
    } catch (e) {
      final existing = await getRecord(idempotencyKey);
      if (existing != null) {
        if (!existing.matchesPayload(payload)) {
          throw ConflictingIdempotencyKeyException(
            idempotencyKey: idempotencyKey,
          );
        }
        return existing.result.copyWith(isDuplicate: true);
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.remoteIdempotencyTable).go();
    await _db.delete(_db.remoteWalletStateTable).go();
    await _db.delete(_db.remoteTransactionsTable).go();
  }
}
