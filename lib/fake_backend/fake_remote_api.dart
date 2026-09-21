import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_idempotency_ledger.dart';
import 'package:novawallet/fake_backend/remote_idempotency_record.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

/// Concrete in-process fake remote banking service.
///
/// Implements requirements:
/// - ASM-006: A Send uses idempotency so retry cannot double-process the transfer.
/// - ASM-011: On reconnect, queued actions are replayed without duplicate financial effect.
/// - ASM-013: A queued action is not sent twice after reconnect/restart.
/// - SYNC-008: Fake remote deduplicates repeated idempotency keys.
/// - SYNC-009: Repeated key with conflicting payload is rejected/flagged.
/// - SYNC-011: Interruption after remote settlement does not produce duplicate effect.
/// - SYNC-012: Recoverable sync failure keeps operation durable and retryable.
/// - TST-007: Lost/uncertain response simulation.
/// - HC-MONEY: All balance calculations and debits use integer kobo.
/// - docs/ARCHITECTURE.md §11 & §14.
class FakeRemoteApi implements RemoteApi {
  final RemoteIdempotencyLedger _ledger;
  final DateTime Function() _clock;
  final String Function(FinancialOperation)? referenceGenerator;
  final FailureSimulator failureSimulator;

  FakeRemoteApi({
    RemoteIdempotencyLedger? ledger,
    DateTime Function()? clock,
    this.referenceGenerator,
    FailureSimulator? failureSimulator,
  }) : _ledger = ledger ?? InMemoryRemoteLedger(),
       _clock = clock ?? (() => DateTime.now().toUtc()),
       failureSimulator = failureSimulator ?? FailureSimulator();

  /// Exposes the underlying ledger for tests or inspection.
  RemoteIdempotencyLedger get ledger => _ledger;

  @override
  Future<RemoteOperationResult> sendMoney(FinancialOperation operation) async {
    if (operation.type != OperationType.send ||
        operation.payload is! SendMoneyPayload) {
      throw InvalidRemoteOperationException(
        'Expected a Send Money operation, received: ${operation.type}',
      );
    }

    // Pre-execution failure check (e.g. transport error, server error, business rejection)
    failureSimulator.checkPreExecution(operation);

    final key = operation.idempotencyKey.value;
    final debitAmount = operation.payload.amount;
    final now = _clock();
    final reference =
        referenceGenerator?.call(operation) ??
        _defaultReference('TXN', operation);

    final result = RemoteOperationResult(
      remoteReference: reference,
      settledAt: now,
      debitAmount: debitAmount,
      isDuplicate: false,
    );

    final payload = operation.payload as SendMoneyPayload;
    final transaction = WalletTransaction(
      id: reference,
      type: TransactionType.debit,
      amount: debitAmount,
      counterparty: payload.recipientName,
      createdAt: now,
      status: TransactionStatus.completed,
      reference: reference,
      narration: payload.narration,
    );

    final record = RemoteIdempotencyRecord(
      idempotencyKey: key,
      operationId: operation.id.value,
      operationType: operation.type.name,
      payload: operation.payload.toMap(),
      result: result,
      recordedAt: now,
    );

    // Atomically reserve idempotency key, debit balance, and record transaction
    final finalResult = await _ledger.executeAtomicOperation(
      idempotencyKey: key,
      payload: operation.payload,
      debitAmount: debitAmount,
      transaction: transaction,
      record: record,
    );

    // Post-execution failure check (e.g. response lost in flight after remote settlement)
    failureSimulator.checkPostExecution(operation, finalResult.remoteReference);

    return finalResult;
  }

  @override
  Future<RemoteOperationResult> contribute(FinancialOperation operation) async {
    if (operation.type != OperationType.contribution ||
        operation.payload is! ContributionPayload) {
      throw InvalidRemoteOperationException(
        'Expected a Contribution operation, received: ${operation.type}',
      );
    }

    // Pre-execution failure check (e.g. transport error, server error, business rejection)
    failureSimulator.checkPreExecution(operation);

    final key = operation.idempotencyKey.value;
    final debitAmount = operation.payload.amount;
    final now = _clock();
    final reference =
        referenceGenerator?.call(operation) ??
        _defaultReference('GOAL', operation);

    final result = RemoteOperationResult(
      remoteReference: reference,
      settledAt: now,
      debitAmount: debitAmount,
      isDuplicate: false,
    );

    final payload = operation.payload as ContributionPayload;
    final transaction = WalletTransaction(
      id: reference,
      type: TransactionType.debit,
      amount: debitAmount,
      counterparty: 'NovaSave: ${payload.goalName}',
      createdAt: now,
      status: TransactionStatus.completed,
      reference: reference,
      narration: 'Contribution to ${payload.goalName}',
    );

    final record = RemoteIdempotencyRecord(
      idempotencyKey: key,
      operationId: operation.id.value,
      operationType: operation.type.name,
      payload: operation.payload.toMap(),
      result: result,
      recordedAt: now,
    );

    // Atomically reserve idempotency key, debit balance, and record transaction
    final finalResult = await _ledger.executeAtomicOperation(
      idempotencyKey: key,
      payload: operation.payload,
      debitAmount: debitAmount,
      transaction: transaction,
      record: record,
    );

    // Post-execution failure check (e.g. response lost in flight after remote settlement)
    failureSimulator.checkPostExecution(operation, finalResult.remoteReference);

    return finalResult;
  }

  @override
  Future<RemoteOperationResult> submitOperation(
    FinancialOperation operation,
  ) async {
    switch (operation.type) {
      case OperationType.send:
        return sendMoney(operation);
      case OperationType.contribution:
        return contribute(operation);
    }
  }

  @override
  Future<WalletSnapshot> fetchWalletSnapshot() async {
    final balance = await _ledger.getBalance();
    return WalletSnapshot(balance: balance, lastUpdatedAt: _clock());
  }

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    return _ledger.getTransactions(limit: limit, offset: offset);
  }

  String _defaultReference(String prefix, FinancialOperation operation) {
    final opIdSnippet = operation.id.value.length > 8
        ? operation.id.value.substring(0, 8).toUpperCase()
        : operation.id.value.toUpperCase();
    final nowMs = _clock().millisecondsSinceEpoch;
    return '$prefix-$opIdSnippet-$nowMs';
  }
}
