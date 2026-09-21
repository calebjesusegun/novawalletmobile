import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/fake_backend/remote_operation_result.dart';
import 'package:novawallet/features/novasave/data/local_novasave_repository.dart';
import 'package:novawallet/features/novasave/data/savings_goal_dao.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/wallet/data/local_wallet_repository.dart';
import 'package:novawallet/features/wallet/data/transaction_dao.dart';
import 'package:novawallet/features/wallet/data/wallet_dao.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/sync/application/sync_application.dart';
import 'package:novawallet/sync/data/local_operation_repository.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  group('FailureClassifier (SYNC-012, UI-SND-13, UI-SND-18)', () {
    test('classifies transient exceptions as recoverable SyncError', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0);

      // RemoteTransportException
      final transportError = FailureClassifier.classify(
        const RemoteTransportException(),
        now,
      );
      expect(transportError.isRecoverable, isTrue);
      expect(transportError.code, 'TRANSPORT_ERROR');

      // RemoteServerException
      final serverError = FailureClassifier.classify(
        const RemoteServerException(),
        now,
      );
      expect(serverError.isRecoverable, isTrue);
      expect(serverError.code, 'SERVER_ERROR');

      // RemoteResponseLostException
      final responseLostError = FailureClassifier.classify(
        const RemoteResponseLostException(remoteReference: 'REF-123'),
        now,
      );
      expect(responseLostError.isRecoverable, isTrue);
      expect(responseLostError.code, 'RESPONSE_LOST');

      // SocketException
      final socketError = FailureClassifier.classify(
        const SocketException('Failed host lookup'),
        now,
      );
      expect(socketError.isRecoverable, isTrue);
      expect(socketError.code, 'SOCKET_ERROR');

      // TimeoutException
      final timeoutError = FailureClassifier.classify(
        TimeoutException('Request timed out'),
        now,
      );
      expect(timeoutError.isRecoverable, isTrue);
      expect(timeoutError.code, 'TIMEOUT');
    });

    test(
      'classifies business and validation rejections as terminal SyncError',
      () {
        final now = DateTime.utc(2026, 9, 21, 10, 0);

        // RemoteBusinessRejectionException
        final rejectionError = FailureClassifier.classify(
          const RemoteBusinessRejectionException(
            message: 'Invalid account number',
          ),
          now,
        );
        expect(rejectionError.isRecoverable, isFalse);
        expect(rejectionError.code, 'BUSINESS_REJECTION');

        // ConflictingIdempotencyKeyException
        final conflictError = FailureClassifier.classify(
          ConflictingIdempotencyKeyException(idempotencyKey: 'KEY-123'),
          now,
        );
        expect(conflictError.isRecoverable, isFalse);
        expect(conflictError.code, 'CONFLICTING_KEY');

        // InsufficientRemoteFundsException
        final fundsError = FailureClassifier.classify(
          InsufficientRemoteFundsException(
            requestedKobo: 5000,
            availableKobo: 1000,
          ),
          now,
        );
        expect(fundsError.isRecoverable, isFalse);
        expect(fundsError.code, 'INSUFFICIENT_FUNDS');

        // InvalidRemoteOperationException
        final invalidOpError = FailureClassifier.classify(
          const InvalidRemoteOperationException('Unsupported operation'),
          now,
        );
        expect(invalidOpError.isRecoverable, isFalse);
        expect(invalidOpError.code, 'INVALID_OPERATION');

        // ArgumentError / FormatException
        final argError = FailureClassifier.classify(
          ArgumentError('Bad argument'),
          now,
        );
        expect(argError.isRecoverable, isFalse);
        expect(argError.code, 'DATA_VALIDATION_ERROR');
      },
    );

    test('unclassified errors fail safe to recoverable SyncError', () {
      final error = FailureClassifier.classify(Exception('Something strange'));
      expect(error.isRecoverable, isTrue);
      expect(error.code, 'UNCLASSIFIED_ERROR');
    });

    test('userMessage returns design-compliant presentation text', () {
      final recoverable = SyncError.recoverable(
        message: 'Network drop',
        code: 'TRANSPORT_ERROR',
      );
      expect(
        FailureClassifier.userMessage(recoverable),
        contains('Your transaction is saved safely'),
      );

      final responseLost = SyncError.recoverable(
        message: 'Lost',
        code: 'RESPONSE_LOST',
      );
      expect(
        FailureClassifier.userMessage(responseLost),
        contains('Tap Retry to check status safely without double-charging'),
      );

      final terminal = SyncError.terminal(
        message: 'Account does not exist',
        code: 'BUSINESS_REJECTION',
      );
      expect(FailureClassifier.userMessage(terminal), 'Account does not exist');
    });
  });

  group('RetryPolicy Rules (ASM-010, SYNC-013, HC-RETRY)', () {
    late FinancialOperation pendingOp;

    setUp(() {
      pendingOp = FinancialOperation.create(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        createdAt: DateTime.utc(2026, 9, 21, 10, 0),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );
    });

    test('canRetry returns true for pending operation when online', () {
      expect(RetryPolicy.canRetry(pendingOp, isOnline: true), isTrue);
    });

    test('canRetry returns false when offline', () {
      expect(RetryPolicy.canRetry(pendingOp, isOnline: false), isFalse);
    });

    test('canRetry returns false when operation is already in processing', () {
      final processingOp = pendingOp.markProcessing();
      expect(RetryPolicy.canRetry(processingOp, isOnline: true), isFalse);
    });

    test('canRetry returns false for completed and failed operations', () {
      final completedOp = pendingOp.markProcessing().markCompleted(
        remoteReference: 'REF-1',
        at: DateTime.utc(2026, 9, 21, 10, 5),
      );
      expect(RetryPolicy.canRetry(completedOp, isOnline: true), isFalse);

      final failedOp = pendingOp.markProcessing().markTerminalFailure(
        error: SyncError.terminal(message: 'Closed account'),
        at: DateTime.utc(2026, 9, 21, 10, 5),
      );
      expect(RetryPolicy.canRetry(failedOp, isOnline: true), isFalse);
    });
  });

  group('Manual Retry & Idempotency Key Preservation (SND-019, SND-020, NSV-022, NSV-023, HC-IDEMPOTENCY)', () {
    late AppDatabase db;
    late PendingOperationsDao pendingOpsDao;
    late LocalOperationRepository opRepo;

    late WalletDao walletDao;
    late TransactionDao txDao;
    late LocalWalletRepository walletRepo;

    late SavingsGoalDao goalDao;
    late LocalNovaSaveRepository goalRepo;

    late InMemoryRemoteLedger remoteLedger;
    late FailureSimulator failureSimulator;
    late FakeRemoteApi remoteApi;

    late InMemoryConnectivityService connectivityService;
    late SyncCoordinator coordinator;

    setUp(() async {
      db = AppDatabase.inMemory();
      pendingOpsDao = PendingOperationsDao(db);
      opRepo = LocalOperationRepository(pendingOpsDao);

      walletDao = WalletDao(db);
      txDao = TransactionDao(db);
      walletRepo = LocalWalletRepository(
        walletDao: walletDao,
        transactionDao: txDao,
      );
      await walletRepo.setWalletSnapshot(
        WalletSnapshot(balance: const Money.fromKobo(10000000)),
      );

      goalDao = SavingsGoalDao(db);
      goalRepo = LocalNovaSaveRepository(savingsGoalDao: goalDao);
      await goalRepo.createGoal(
        SavingsGoal(
          id: 'goal-vacation',
          name: 'Vacation',
          targetAmount: const Money.fromKobo(5000000),
          targetDate: DateTime.utc(2027, 1, 1),
          savedAmount: const Money.zero(),
        ),
      );

      remoteLedger = InMemoryRemoteLedger();
      await remoteLedger.setBalance(const Money.fromKobo(10000000));
      failureSimulator = FailureSimulator();
      remoteApi = FakeRemoteApi(
        ledger: remoteLedger,
        failureSimulator: failureSimulator,
      );

      connectivityService = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );

      coordinator = SyncCoordinator(
        operationRepository: opRepo,
        remoteApi: remoteApi,
        connectivityService: connectivityService,
        walletRepository: walletRepo,
        novaSaveRepository: goalRepo,
        autoSubscribeConnectivity: false,
      );
    });

    tearDown(() async {
      coordinator.dispose();
      connectivityService.dispose();
      await db.close();
    });

    test('manual retry reuses identical OperationId and IdempotencyKey across Send Money retries (SND-019, SND-020)', () async {
      final capturedKeys = <String>[];
      final monitoredApi = _KeyCaptureRemoteApi(
        remoteApi,
        onCall: (op) => capturedKeys.add(op.idempotencyKey.value),
      );

      final monitoredCoordinator = SyncCoordinator(
        operationRepository: opRepo,
        remoteApi: monitoredApi,
        connectivityService: connectivityService,
        walletRepository: walletRepo,
        novaSaveRepository: goalRepo,
        autoSubscribeConnectivity: false,
      );
      addTearDown(monitoredCoordinator.dispose);

      final stableOpId = OperationId.generate();
      final stableIdKey = IdempotencyKey.generate();

      await opRepo.enqueueSendMoney(
        id: stableOpId,
        idempotencyKey: stableIdKey,
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      // Attempt 1: Simulate network drop
      failureSimulator.failNext(SimulatedFailureType.transport);
      final sync1 = await monitoredCoordinator.synchronize();
      expect(sync1.recoverableFailures, 1);

      final opAfterFailure = await opRepo.getOperationById(stableOpId);
      expect(opAfterFailure!.status, OperationStatus.pending);
      expect(opAfterFailure.attemptCount, 1);
      expect(opAfterFailure.lastError, isNotNull);

      // Attempt 2: User taps Retry on UI (UI-SND-18)
      final retryResult = await monitoredCoordinator.retryOperation(stableOpId);
      expect(retryResult.isSuccess, isTrue);
      expect(retryResult.status, RetryStatus.success);

      final opAfterRetry = await opRepo.getOperationById(stableOpId);
      expect(opAfterRetry!.status, OperationStatus.completed);
      expect(opAfterRetry.attemptCount, 2);

      // HARD CONSTRAINT VERIFICATION:
      // Both attempts MUST have submitted the EXACT SAME stable IdempotencyKey
      expect(capturedKeys.length, 2);
      expect(capturedKeys[0], stableIdKey.value);
      expect(capturedKeys[1], stableIdKey.value);
      expect(capturedKeys[0], capturedKeys[1]);
    });

    test('manual retry reuses identical IdempotencyKey across NovaSave contribution retries (NSV-022, NSV-023)', () async {
      final capturedKeys = <String>[];
      final monitoredApi = _KeyCaptureRemoteApi(
        remoteApi,
        onCall: (op) => capturedKeys.add(op.idempotencyKey.value),
      );

      final monitoredCoordinator = SyncCoordinator(
        operationRepository: opRepo,
        remoteApi: monitoredApi,
        connectivityService: connectivityService,
        walletRepository: walletRepo,
        novaSaveRepository: goalRepo,
        autoSubscribeConnectivity: false,
      );
      addTearDown(monitoredCoordinator.dispose);

      final stableOpId = OperationId.generate();
      final stableIdKey = IdempotencyKey.generate();

      await opRepo.enqueueContribution(
        id: stableOpId,
        idempotencyKey: stableIdKey,
        payload: ContributionPayload(
          goalId: 'goal-vacation',
          goalName: 'Vacation',
          amount: const Money.fromKobo(500000),
        ),
      );

      // Attempt 1: Server error
      failureSimulator.failNext(SimulatedFailureType.serverError);
      await monitoredCoordinator.synchronize();

      // Attempt 2: User taps Retry on UI (UI-NSV-21)
      final retryResult = await monitoredCoordinator.retryOperation(stableOpId);
      expect(retryResult.isSuccess, isTrue);

      expect(capturedKeys.length, 2);
      expect(capturedKeys[0], stableIdKey.value);
      expect(capturedKeys[1], stableIdKey.value);

      // Goal progress was updated
      final goal = await goalRepo.getGoal('goal-vacation');
      expect(goal!.savedAmount.kobo, 500000);
    });

    test('retry skips execution when device is offline without changing attempt count', () async {
      connectivityService.setStatus(ConnectivityStatus.offline);

      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      final retryResult = await coordinator.retryOperation(op.id);
      expect(retryResult.status, RetryStatus.offline);

      final fromDb = await opRepo.getOperationById(op.id);
      expect(fromDb!.status, OperationStatus.pending);
      expect(fromDb.attemptCount, 0);
    });

    test('retry returns alreadyProcessing if operation is currently claimed or in-flight', () async {
      final op = await opRepo.enqueueSendMoney(
        id: OperationId.generate(),
        idempotencyKey: IdempotencyKey.generate(),
        payload: SendMoneyPayload(
          recipientAccountNumber: '0123456789',
          recipientName: 'Amina',
          bankName: 'Access Bank',
          amount: const Money.fromKobo(1000000),
        ),
      );

      // Claim operation to simulate active in-flight status
      await opRepo.claim(op.id);

      final retryResult = await coordinator.retryOperation(op.id);
      expect(retryResult.status, RetryStatus.alreadyProcessing);
    });

    test(
      'retry returns notRetryable for completed or terminal failed operations',
      () async {
        final op = await opRepo.enqueueSendMoney(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Amina',
            bankName: 'Access Bank',
            amount: const Money.fromKobo(1000000),
          ),
        );

        // Mark completed
        await opRepo.claim(op.id);
        await opRepo.markCompleted(op.id, remoteReference: 'REF-1');

        final retryCompleted = await coordinator.retryOperation(op.id);
        expect(retryCompleted.status, RetryStatus.notRetryable);
      },
    );
  });
}

class _KeyCaptureRemoteApi implements RemoteApi {
  final RemoteApi _delegate;
  final void Function(FinancialOperation) onCall;

  _KeyCaptureRemoteApi(this._delegate, {required this.onCall});

  @override
  Future<RemoteOperationResult> sendMoney(FinancialOperation operation) {
    onCall(operation);
    return _delegate.sendMoney(operation);
  }

  @override
  Future<RemoteOperationResult> contribute(FinancialOperation operation) {
    onCall(operation);
    return _delegate.contribute(operation);
  }

  @override
  Future<RemoteOperationResult> submitOperation(FinancialOperation operation) {
    onCall(operation);
    return _delegate.submitOperation(operation);
  }

  @override
  Future<WalletSnapshot> fetchWalletSnapshot() =>
      _delegate.fetchWalletSnapshot();

  @override
  Future<List<WalletTransaction>> fetchTransactions({
    int limit = 50,
    int offset = 0,
  }) => _delegate.fetchTransactions(limit: limit, offset: offset);
}
