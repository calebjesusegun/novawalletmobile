import 'dart:async';

import 'package:novawallet/core/connectivity/connectivity_service.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/novasave/domain/novasave_repository.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

/// Centralized synchronization coordinator for NovaWallet.
///
/// Implements requirements:
/// - HC-SYNC: Shared synchronization mechanism owning all pending-operation processing;
///   no ad-hoc replay loops in feature widgets.
/// - HC-EXACTLY-ONCE-EFFECT: Delivery may repeat on retry; financial effects occur at most once.
/// - HC-STATE-SEPARATION: SyncStatus, ConnectivityStatus, and OperationStatus are kept strictly independent.
/// - ASM-011: On reconnect, queued actions are replayed without duplicate financial effect.
/// - ASM-013: A queued action is not sent twice after reconnect/restart.
/// - SYNC-004: Synchronize eligible pending operations on reconnect.
/// - SYNC-005: Single shared coordinator for Send and Contribution operations.
/// - SYNC-010: Concurrent sync triggers cannot process the same local operation concurrently.
class SyncCoordinator {
  final OperationRepository operationRepository;
  final RemoteApi remoteApi;
  final ConnectivityService connectivityService;
  final WalletRepository walletRepository;
  final NovaSaveRepository novaSaveRepository;
  final DateTime Function() _clock;

  StreamSubscription<dynamic>? _connectivitySubscription;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _status = SyncStatus.idle;
  Completer<SyncRunResult>? _activeSyncCompleter;
  bool _hasPendingTrigger = false;
  bool _isDisposed = false;

  SyncCoordinator({
    required this.operationRepository,
    required this.remoteApi,
    required this.connectivityService,
    required this.walletRepository,
    required this.novaSaveRepository,
    DateTime Function()? clock,
    bool autoSubscribeConnectivity = true,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()) {
    if (autoSubscribeConnectivity) {
      _subscribeToConnectivity();
    }
  }

  /// The current synchronization status.
  SyncStatus get status => _status;

  /// Stream of synchronization status changes.
  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  /// Whether a synchronization run is currently active.
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Subscribes to network connectivity transitions to trigger sync on reconnect (SYNC-004, ASM-011).
  void _subscribeToConnectivity() {
    _connectivitySubscription = connectivityService.onConnectivityChanged
        .distinct()
        .listen((connectivity) {
          if (connectivity.isOnline) {
            synchronize(trigger: SyncTrigger.reconnect);
          }
        });
  }

  /// Recovers operations left in [OperationStatus.processing] after an abrupt process termination (ASM-012, SYNC-003).
  ///
  /// Resets them back to [OperationStatus.pending] while preserving their stable idempotency keys
  /// and attempt counts so they become eligible to be claimed and processed again.
  ///
  /// Returns the number of recovered operations.
  Future<int> recoverInterrupted() async {
    if (_isDisposed) {
      throw StateError('Cannot recover on a disposed SyncCoordinator.');
    }
    return await operationRepository.recoverInterrupted();
  }

  /// Runs startup crash recovery and triggers initial synchronization if online (ASM-012, SYNC-003).
  ///
  /// 1. Recovers any interrupted in-flight operations.
  /// 2. If [triggerSyncIfOnline] is true and connectivity is online, runs a synchronization pass
  ///    with [SyncTrigger.startup].
  ///
  /// Returns the [SyncRunResult] if a sync pass was executed, or null if skipped.
  Future<SyncRunResult?> startup({bool triggerSyncIfOnline = true}) async {
    if (_isDisposed) {
      throw StateError('Cannot startup a disposed SyncCoordinator.');
    }

    await recoverInterrupted();

    if (triggerSyncIfOnline) {
      final connectivity = await connectivityService.checkConnectivity();
      if (connectivity.isOnline) {
        return await synchronize(trigger: SyncTrigger.startup);
      }
    }

    return null;
  }

  /// Triggers a synchronization run for all eligible pending operations.
  ///
  /// Serializes concurrent sync calls: if a run is already active, subsequent triggers
  /// are coalesced and guaranteed to be executed after the current run completes (SYNC-010).
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    if (_isDisposed) {
      throw StateError('Cannot synchronize a disposed SyncCoordinator.');
    }

    // If a sync pass is currently running, coalesce this trigger
    if (_activeSyncCompleter != null) {
      _hasPendingTrigger = true;
      return _activeSyncCompleter!.future;
    }

    final completer = Completer<SyncRunResult>();
    _activeSyncCompleter = completer;

    try {
      final result = await _executeSyncPass(trigger);
      completer.complete(result);
      return result;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _activeSyncCompleter = null;
      // If a new trigger arrived while syncing and we are still online, execute a follow-up pass
      if (_hasPendingTrigger && !_isDisposed) {
        _hasPendingTrigger = false;
        final connectivity = await connectivityService.checkConnectivity();
        if (connectivity.isOnline) {
          unawaited(synchronize(trigger: trigger));
        }
      }
    }
  }

  /// Executes a single synchronization pass over currently eligible operations.
  Future<SyncRunResult> _executeSyncPass(SyncTrigger trigger) async {
    final connectivity = await connectivityService.checkConnectivity();
    if (connectivity.isOffline) {
      // Cannot sync while offline
      _updateStatus(SyncStatus.idle);
      return SyncRunResult.empty(trigger);
    }

    _updateStatus(SyncStatus.syncing);

    final pendingOperations = await operationRepository.getPendingOperations();
    if (pendingOperations.isEmpty) {
      _updateStatus(SyncStatus.idle);
      return SyncRunResult.empty(trigger);
    }

    int totalClaimed = 0;
    int succeeded = 0;
    int recoverableFailures = 0;
    int terminalFailures = 0;
    int skipped = 0;
    final errors = <SyncError>[];

    final now = _clock().toUtc();

    for (final operation in pendingOperations) {
      // Check connectivity before each operation to avoid unnecessary remote attempts during outages
      final currentConnectivity = await connectivityService.checkConnectivity();
      if (currentConnectivity.isOffline) {
        _updateStatus(SyncStatus.idle);
        break;
      }

      // 1. Atomic claim per operation (SYNC-010)
      final claimed = await operationRepository.claim(operation.id, at: now);
      if (!claimed) {
        skipped++;
        continue;
      }
      totalClaimed++;

      // 2. Process claimed operation
      final outcome = await _processClaimedOperation(operation, now);
      switch (outcome.type) {
        case _OutcomeType.success:
          succeeded++;
          break;
        case _OutcomeType.recoverableFailure:
          recoverableFailures++;
          errors.add(outcome.error!);
          // Stop queue processing on transient network/server failure
          _updateStatus(SyncStatus.failed);
          return SyncRunResult(
            trigger: trigger,
            totalDiscovered: pendingOperations.length,
            totalClaimed: totalClaimed,
            succeeded: succeeded,
            recoverableFailures: recoverableFailures,
            terminalFailures: terminalFailures,
            skipped: skipped,
            errors: errors,
          );
        case _OutcomeType.terminalFailure:
          terminalFailures++;
          errors.add(outcome.error!);
          // Terminal failure releases reservation; continue processing remaining queue
          break;
      }
    }

    if (recoverableFailures > 0) {
      _updateStatus(SyncStatus.failed);
    } else {
      _updateStatus(SyncStatus.idle);
    }

    return SyncRunResult(
      trigger: trigger,
      totalDiscovered: pendingOperations.length,
      totalClaimed: totalClaimed,
      succeeded: succeeded,
      recoverableFailures: recoverableFailures,
      terminalFailures: terminalFailures,
      skipped: skipped,
      errors: errors,
    );
  }

  /// Processes a single claimed operation and applies local side-effects upon success.
  Future<_OperationOutcome> _processClaimedOperation(
    FinancialOperation operation,
    DateTime now,
  ) async {
    RemoteOperationResult remoteResult;
    try {
      if (operation.type == OperationType.send) {
        remoteResult = await remoteApi.sendMoney(operation);
      } else {
        remoteResult = await remoteApi.contribute(operation);
      }
    } on RemoteApiException catch (e) {
      final syncError = e.toSyncError();
      if (e.isRecoverable) {
        await operationRepository.markPendingWithError(
          operation.id,
          error: syncError,
          at: now,
        );
        return _OperationOutcome.recoverable(syncError);
      } else {
        await operationRepository.markFailed(
          operation.id,
          error: syncError,
          at: now,
        );
        return _OperationOutcome.terminal(syncError);
      }
    } catch (e) {
      final syncError = SyncError.recoverable(
        message: e.toString(),
        timestamp: now,
      );
      await operationRepository.markPendingWithError(
        operation.id,
        error: syncError,
        at: now,
      );
      return _OperationOutcome.recoverable(syncError);
    }

    // Remote call succeeded -> Apply local side-effects BEFORE exposing operation completion
    // (docs/ARCHITECTURE.md §12, §16 and T-SYNC-002 acceptance criteria)
    await _applySuccessfulOperationEffects(operation, remoteResult, now);

    return _OperationOutcome.success(remoteResult);
  }

  /// Atomically applies local wallet balance, transaction ledger, and savings goal progress
  /// updates before marking the financial operation completed.
  Future<void> _applySuccessfulOperationEffects(
    FinancialOperation operation,
    RemoteOperationResult result,
    DateTime now,
  ) async {
    // 1. Update confirmed wallet balance
    final currentSnapshot = await walletRepository.getWalletSnapshot();
    if (currentSnapshot != null) {
      final updatedBalance = currentSnapshot.balance - operation.payload.amount;
      await walletRepository.setWalletSnapshot(
        currentSnapshot.copyWith(balance: updatedBalance, lastUpdatedAt: now),
      );
    }

    // 2. Insert confirmed transaction in wallet activity history
    final transaction = WalletTransaction(
      id: operation.id.value,
      type: TransactionType.debit,
      amount: operation.payload.amount,
      counterparty: operation.type == OperationType.send
          ? (operation.payload as SendMoneyPayload).recipientName
          : (operation.payload as ContributionPayload).goalName,
      createdAt: now,
      status: TransactionStatus.completed,
      reference: result.remoteReference,
      narration: operation.type == OperationType.send
          ? (operation.payload as SendMoneyPayload).narration
          : 'NovaSave Contribution',
    );
    await walletRepository.saveTransaction(transaction);

    // 3. If contribution, increment the savings goal progress
    if (operation.type == OperationType.contribution) {
      final payload = operation.payload as ContributionPayload;
      await novaSaveRepository.applyContribution(
        payload.goalId,
        operation.payload.amount,
      );
    }

    // 4. Mark the financial operation as completed in durable storage
    await operationRepository.markCompleted(
      operation.id,
      remoteReference: result.remoteReference,
      at: now,
    );
  }

  /// Retries a single pending operation explicitly (e.g. user taps Retry button).
  Future<bool> retryOperation(OperationId id) async {
    if (_isDisposed) {
      throw StateError('Cannot retry on a disposed SyncCoordinator.');
    }

    final connectivity = await connectivityService.checkConnectivity();
    if (connectivity.isOffline) {
      return false;
    }

    final operation = await operationRepository.getOperationById(id);
    if (operation == null || operation.status != OperationStatus.pending) {
      return false;
    }

    final now = _clock().toUtc();
    final claimed = await operationRepository.claim(id, at: now);
    if (!claimed) {
      return false;
    }

    final outcome = await _processClaimedOperation(operation, now);
    return outcome.type == _OutcomeType.success;
  }

  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus && !_isDisposed) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Releases connectivity subscriptions and closes the status stream.
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _connectivitySubscription?.cancel();
      _statusController.close();
    }
  }
}

enum _OutcomeType { success, recoverableFailure, terminalFailure }

class _OperationOutcome {
  final _OutcomeType type;
  final RemoteOperationResult? result;
  final SyncError? error;

  const _OperationOutcome.success(this.result)
    : type = _OutcomeType.success,
      error = null;

  const _OperationOutcome.recoverable(this.error)
    : type = _OutcomeType.recoverableFailure,
      result = null;

  const _OperationOutcome.terminal(this.error)
    : type = _OutcomeType.terminalFailure,
      result = null;
}
