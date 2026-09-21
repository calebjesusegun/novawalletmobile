import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_backend_providers.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/novasave_repository.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/application/sync_application.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';

/// Integration test harness encapsulating the complete NovaWallet synchronization
/// kernel across SQLite database file lifecycles, Riverpod [ProviderContainer] instances,
/// and fake remote infrastructure.
///
/// Designed to simulate real mobile application lifecycles including sudden process
/// termination, offline queuing, restart recovery, and reconnect synchronization.
class SyncKernelTestHarness {
  final Directory tempDir;
  final File dbFile;
  final InMemoryRemoteLedger remoteLedger;
  final FailureSimulator failureSimulator;
  final FakeRemoteApi remoteApi;
  final InMemoryConnectivityService connectivity;

  AppDatabase? _currentDb;
  ProviderContainer? _container;

  SyncKernelTestHarness._({
    required this.tempDir,
    required this.dbFile,
    required this.remoteLedger,
    required this.failureSimulator,
    required this.remoteApi,
    required this.connectivity,
  });

  /// Creates and boots a new [SyncKernelTestHarness] backed by a real SQLite file.
  static Future<SyncKernelTestHarness> create({
    Money initialBalance = const Money.fromKobo(10000000), // ₦100,000
    ConnectivityStatus initialConnectivity = ConnectivityStatus.offline,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'novawallet_kernel_test_',
    );
    final dbFile = File('${tempDir.path}/app_kernel_storage.db');

    final remoteLedger = InMemoryRemoteLedger();
    await remoteLedger.setBalance(initialBalance);
    final failureSimulator = FailureSimulator();
    final remoteApi = FakeRemoteApi(
      ledger: remoteLedger,
      failureSimulator: failureSimulator,
    );
    final connectivity = InMemoryConnectivityService(
      initialStatus: initialConnectivity,
    );

    final harness = SyncKernelTestHarness._(
      tempDir: tempDir,
      dbFile: dbFile,
      remoteLedger: remoteLedger,
      failureSimulator: failureSimulator,
      remoteApi: remoteApi,
      connectivity: connectivity,
    );

    await harness._bootContainer(triggerSyncIfOnline: false);

    // Seed initial local wallet balance to match remote
    await harness.walletRepository.setWalletSnapshot(
      WalletSnapshot(balance: initialBalance),
    );

    return harness;
  }

  /// The active [ProviderContainer].
  ProviderContainer get container {
    final c = _container;
    if (c == null) {
      throw StateError('Kernel harness is not booted or has been disposed.');
    }
    return c;
  }

  /// Active [SyncCoordinator] instance.
  SyncCoordinator get syncCoordinator =>
      container.read(syncCoordinatorProvider);

  /// Active [OperationRepository] instance.
  OperationRepository get operationRepository =>
      container.read(operationRepositoryProvider);

  /// Active [WalletRepository] instance.
  WalletRepository get walletRepository =>
      container.read(walletRepositoryProvider);

  /// Active [NovaSaveRepository] instance.
  NovaSaveRepository get novaSaveRepository =>
      container.read(novaSaveRepositoryProvider);

  /// Boots a fresh [ProviderContainer] and [AppDatabase] on the persistent [dbFile].
  Future<void> _bootContainer({bool triggerSyncIfOnline = true}) async {
    final db = AppDatabase.forFile(dbFile);
    _currentDb = db;

    final newContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        connectivityServiceProvider.overrideWithValue(connectivity),
        remoteApiProvider.overrideWithValue(remoteApi),
        remoteIdempotencyLedgerProvider.overrideWithValue(remoteLedger),
        failureSimulatorProvider.overrideWithValue(failureSimulator),
      ],
    );
    _container = newContainer;

    // Run coordinator startup recovery
    await syncCoordinator.startup(triggerSyncIfOnline: triggerSyncIfOnline);
  }

  /// Simulates abrupt mobile process termination and relaunch.
  ///
  /// Disposes the Riverpod [ProviderContainer], closes the SQLite [AppDatabase],
  /// updates [connectivity] if specified, and boots a new container and database
  /// pointing to the exact same database file.
  Future<void> simulateProcessCrashAndRestart({
    ConnectivityStatus? restartConnectivity,
    bool triggerSyncIfOnline = true,
  }) async {
    _container?.dispose();
    _container = null;

    await _currentDb?.close();
    _currentDb = null;

    if (restartConnectivity != null) {
      connectivity.setStatus(restartConnectivity);
    }

    await _bootContainer(triggerSyncIfOnline: triggerSyncIfOnline);
  }

  /// Sets device connectivity status.
  void setConnectivity(ConnectivityStatus status) {
    connectivity.setStatus(status);
  }

  /// Enqueues a Send Money operation into local SQLite storage.
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required String recipientAccountNumber,
    required String recipientName,
    required String bankName,
    required Money amount,
  }) async {
    return operationRepository.enqueueSendMoney(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: SendMoneyPayload(
        recipientAccountNumber: recipientAccountNumber,
        recipientName: recipientName,
        bankName: bankName,
        amount: amount,
      ),
    );
  }

  /// Enqueues a NovaSave Contribution operation into local SQLite storage.
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required String goalId,
    required String goalName,
    required Money amount,
  }) async {
    return operationRepository.enqueueContribution(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: ContributionPayload(
        goalId: goalId,
        goalName: goalName,
        amount: amount,
      ),
    );
  }

  /// Explicitly runs synchronization.
  Future<SyncRunResult> triggerSync({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    return syncCoordinator.synchronize(trigger: trigger);
  }

  /// Reads current confirmed local wallet balance.
  Future<Money> getLocalWalletBalance() async {
    final snapshot = await walletRepository.getWalletSnapshot();
    return snapshot?.balance ?? const Money.zero();
  }

  /// Reads recent local ledger transactions in SQLite.
  Future<List<WalletTransaction>> getLocalTransactions() async {
    return walletRepository.getRecentTransactions();
  }

  /// Reads a specific NovaSave savings goal in SQLite.
  Future<SavingsGoal?> getLocalGoal(String id) async {
    return novaSaveRepository.getGoal(id);
  }

  /// Reads all pending operations in SQLite.
  Future<List<FinancialOperation>> getLocalPendingOperations() async {
    return operationRepository.getPendingOperations();
  }

  /// Reads all active operations in SQLite.
  Future<List<FinancialOperation>> getLocalActiveOperations() async {
    return operationRepository.getActiveOperations();
  }

  /// Reads a specific operation by id in SQLite.
  Future<FinancialOperation?> getLocalOperationById(OperationId id) async {
    return operationRepository.getOperationById(id);
  }

  /// Reads confirmed remote account balance.
  Future<Money> getRemoteBalance() async {
    return remoteLedger.getBalance();
  }

  /// Reads all transactions recorded in fake remote ledger.
  Future<List<WalletTransaction>> getRemoteTransactions() async {
    return remoteLedger.getTransactions();
  }

  /// Tears down and cleans up temporary resources.
  Future<void> dispose() async {
    _container?.dispose();
    _container = null;

    await _currentDb?.close();
    _currentDb = null;

    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
