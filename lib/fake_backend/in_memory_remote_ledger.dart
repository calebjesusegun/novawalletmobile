import 'dart:math';

import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_idempotency_ledger.dart';
import 'package:novawallet/fake_backend/remote_idempotency_record.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

/// In-memory implementation of [RemoteIdempotencyLedger].
///
/// Provides fast, isolated, deterministic storage for unit testing without
/// database or file dependencies.
class InMemoryRemoteLedger implements RemoteIdempotencyLedger {
  Money _balance;
  final Map<String, RemoteIdempotencyRecord> _records = {};
  final List<WalletTransaction> _transactions = [];

  /// Default initial balance is ₦125,450.00 (12,545,000 kobo) matching design baseline.
  static const Money defaultInitialBalance = Money.fromKobo(12545000);

  InMemoryRemoteLedger({Money? initialBalance})
    : _balance = initialBalance ?? defaultInitialBalance;

  @override
  Future<RemoteIdempotencyRecord?> getRecord(String idempotencyKey) async {
    return _records[idempotencyKey];
  }

  @override
  Future<void> saveRecord(RemoteIdempotencyRecord record) async {
    _records[record.idempotencyKey] = record;
  }

  @override
  Future<Money> getBalance() async {
    return _balance;
  }

  @override
  Future<void> setBalance(Money balance) async {
    _balance = balance;
  }

  @override
  Future<void> addTransaction(WalletTransaction transaction) async {
    _transactions.insert(0, transaction);
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    if (offset >= _transactions.length) {
      return const [];
    }
    final end = min(offset + limit, _transactions.length);
    return List.unmodifiable(_transactions.sublist(offset, end));
  }

  @override
  Future<RemoteOperationResult> executeAtomicOperation({
    required String idempotencyKey,
    required OperationPayload payload,
    required Money debitAmount,
    required WalletTransaction transaction,
    required RemoteIdempotencyRecord record,
  }) async {
    final existing = _records[idempotencyKey];
    if (existing != null) {
      if (!existing.matchesPayload(payload)) {
        throw ConflictingIdempotencyKeyException(
          idempotencyKey: idempotencyKey,
        );
      }
      return existing.result.copyWith(isDuplicate: true);
    }

    if (_balance.kobo < debitAmount.kobo) {
      throw InsufficientRemoteFundsException(
        requestedKobo: debitAmount.kobo,
        availableKobo: _balance.kobo,
      );
    }

    _balance = _balance - debitAmount;
    _transactions.insert(0, transaction);
    _records[idempotencyKey] = record;

    return record.result;
  }

  @override
  Future<void> clear() async {
    _records.clear();
    _transactions.clear();
    _balance = defaultInitialBalance;
  }
}
