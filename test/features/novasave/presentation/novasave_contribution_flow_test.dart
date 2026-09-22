import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribute_amount_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_confirmation_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/sync/application/retry_policy.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

class MockNovaSaveFlowOperationRepository implements OperationRepository {
  final List<FinancialOperation> operations = [];
  final Map<OperationId, StreamController<FinancialOperation?>> _controllers =
      {};

  StreamController<FinancialOperation?> _getOrCreateController(OperationId id) {
    return _controllers.putIfAbsent(
      id,
      StreamController<FinancialOperation?>.broadcast,
    );
  }

  void emitOperation(FinancialOperation operation) {
    final index = operations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      operations[index] = operation;
    } else {
      operations.add(operation);
    }
    _getOrCreateController(operation.id).add(operation);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  @override
  Future<FinancialOperation> enqueue(FinancialOperation operation) async {
    operations.add(operation);
    _getOrCreateController(operation.id).add(operation);
    return operation;
  }

  @override
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) async {
    final op = FinancialOperation.contribution(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
    operations.add(op);
    _getOrCreateController(op.id).add(op);
    return op;
  }

  @override
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  }) => throw UnimplementedError();

  @override
  Future<bool> claim(OperationId id, {DateTime? at}) async => true;

  @override
  Future<List<FinancialOperation>> getActiveOperations() async => operations
      .where(
        (op) =>
            op.status == OperationStatus.pending ||
            op.status == OperationStatus.processing,
      )
      .toList();

  @override
  Future<List<FinancialOperation>> getAllOperations() async => operations;

  @override
  Future<FinancialOperation?> getOperationById(OperationId id) async =>
      operations.cast<FinancialOperation?>().firstWhere(
        (op) => op?.id == id,
        orElse: () => null,
      );

  @override
  Future<FinancialOperation?> getOperationByIdempotencyKey(
    IdempotencyKey key,
  ) async => operations.cast<FinancialOperation?>().firstWhere(
    (op) => op?.idempotencyKey == key,
    orElse: () => null,
  );

  @override
  Future<List<FinancialOperation>> getPendingOperations() async =>
      operations.where((op) => op.status == OperationStatus.pending).toList();

  @override
  Future<FinancialOperation> markCompleted(
    OperationId id, {
    required String remoteReference,
    DateTime? at,
  }) async {
    final op = operations.firstWhere((o) => o.id == id);
    final completed = op.markCompleted(
      remoteReference: remoteReference,
      at: at ?? DateTime.now().toUtc(),
    );
    emitOperation(completed);
    return completed;
  }

  @override
  Future<FinancialOperation> markFailed(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) async {
    final op = operations.firstWhere((o) => o.id == id);
    final failed = op.markTerminalFailure(error: error);
    emitOperation(failed);
    return failed;
  }

  @override
  Future<FinancialOperation> markPendingWithError(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) async {
    final op = operations.firstWhere((o) => o.id == id);
    final withErr = op.markRecoverableError(error: error, at: at);
    emitOperation(withErr);
    return withErr;
  }

  Future<FinancialOperation> markProcessing(
    OperationId id, {
    DateTime? at,
  }) async {
    final op = operations.firstWhere((o) => o.id == id);
    final processing = op.markProcessing();
    emitOperation(processing);
    return processing;
  }

  @override
  Future<int> recoverInterrupted() async => 0;

  @override
  Future<void> update(FinancialOperation operation) async {
    emitOperation(operation);
  }

  @override
  Stream<List<FinancialOperation>> watchActiveOperations() =>
      Stream.value(operations);

  @override
  Stream<List<FinancialOperation>> watchPendingOperations() =>
      Stream.value(operations);

  @override
  Stream<FinancialOperation?> watchOperationById(OperationId id) {
    // ignore: close_sinks
    final controller = _getOrCreateController(id);
    // ignore: close_sinks
    late StreamController<FinancialOperation?> streamCtrl;
    StreamSubscription<FinancialOperation?>? sub;

    streamCtrl = StreamController<FinancialOperation?>(
      onListen: () {
        final current = operations.cast<FinancialOperation?>().firstWhere(
          (op) => op?.id == id,
          orElse: () => null,
        );
        streamCtrl.add(current);
        sub = controller.stream.listen(
          streamCtrl.add,
          onError: streamCtrl.addError,
          onDone: streamCtrl.close,
        );
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return streamCtrl.stream;
  }
}

class MockNovaSaveFlowSyncCoordinator implements SyncCoordinator {
  int retryCount = 0;
  OperationId? lastRetriedId;

  @override
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async => SyncRunResult.empty(trigger);

  @override
  Future<RetryResult> retryOperation(OperationId id) async {
    retryCount++;
    lastRetriedId = id;
    return const RetryResult.success();
  }

  @override
  Future<int> recoverInterrupted() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NovaSave Contribution Flow Widget Tests (T-TST-002, ASM-023, TST-005)', () {
    late MockNovaSaveFlowOperationRepository repo;
    late MockNovaSaveFlowSyncCoordinator syncCoordinator;
    late StreamController<List<SavingsGoal>> goalsController;
    late StreamController<List<FinancialOperation>> activeOpsController;

    final initialGoal = SavingsGoal(
      id: 'goal-emergency-fund',
      name: 'Emergency Fund',
      targetAmount: Money.fromNaira(500000), // ₦500,000.00
      savedAmount: Money.fromNaira(150000), // ₦150,000.00 (30%)
      targetDate: DateTime(2026, 12, 30),
    );

    setUp(() {
      repo = MockNovaSaveFlowOperationRepository();
      syncCoordinator = MockNovaSaveFlowSyncCoordinator();
      goalsController = StreamController<List<SavingsGoal>>.broadcast();
      activeOpsController =
          StreamController<List<FinancialOperation>>.broadcast();
    });

    tearDown(() {
      repo.dispose();
      goalsController.close();
      activeOpsController.close();
    });

    Widget buildFlow({
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      Money spendableBalance = const Money.fromKobo(12545000), // ₦125,450.00
      SavingsGoal? goal,
    }) {
      final currentGoal = goal ?? initialGoal;
      final projection = WalletProjection(
        confirmedBalance: spendableBalance,
        spendableBalance: spendableBalance,
        pendingDebitTotal: const Money.zero(),
        lastUpdatedAt: DateTime.utc(2026, 9, 21),
        activities: const [],
        pendingOperations: const [],
      );

      return ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWithValue(connectivity),
          operationRepositoryProvider.overrideWithValue(repo),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(projection),
          ),
          operationByIdStreamProvider.overrideWith(
            (ref, id) => repo.watchOperationById(id),
          ),
          savingsGoalsStreamProvider.overrideWith(
            (ref) => goalsController.stream,
          ),
          activeOperationsStreamProvider.overrideWith(
            (ref) => activeOpsController.stream,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: GoalDetailsScreen(
            goalId: currentGoal.id,
            initialGoal: currentGoal,
          ),
        ),
      );
    }

    testWidgets(
      'Step navigation, back-navigation and flow-level validation blocking',
      (tester) async {
        await tester.pumpWidget(buildFlow());
        goalsController.add([initialGoal]);
        activeOpsController.add([]);
        await tester.pumpAndSettle();

        // Step 0: On Goal Details Screen
        expect(find.text('Emergency Fund'), findsOneWidget);
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('30% complete'), findsOneWidget);

        // Tap Contribute button to begin flow
        await tester.tap(
          find.byKey(const Key('goal_details_contribute_button')),
        );
        await tester.pumpAndSettle();

        // Step 1: Contribute Amount Screen
        expect(find.byType(ContributeAmountScreen), findsOneWidget);
        expect(find.text('Contribute'), findsOneWidget);
        expect(find.text('Saved ₦150,000 of ₦500,000'), findsOneWidget);

        // Validation Blocking 1: 0 or empty amount
        final continueBtn = tester.widget<AppButton>(
          find.byKey(const Key('contribute_continue_button')),
        );
        expect(continueBtn.isEnabled, isFalse);
        expect(find.byKey(const Key('projected_progress_card')), findsNothing);

        // Validation Blocking 2: Amount exceeding wallet spendable balance
        await tester.enterText(
          find.byType(TextField),
          '200000',
        ); // ₦200,000 > ₦125,450.00
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Amount is more than your wallet balance. Enter ₦125,450.00 or less.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<AppButton>(
                find.byKey(const Key('contribute_continue_button')),
              )
              .isEnabled,
          isFalse,
        );
        expect(find.byKey(const Key('projected_progress_card')), findsNothing);

        // Enter valid amount ₦50,000.00
        await tester.enterText(find.byType(TextField), '50000');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('projected_progress_card')),
          findsOneWidget,
        );
        expect(find.text('₦200,000 of ₦500,000'), findsOneWidget);
        expect(find.text('40%'), findsOneWidget);

        // Tap Continue to go to Confirmation Screen
        await tester.tap(find.byKey(const Key('contribute_continue_button')));
        await tester.pumpAndSettle();

        // Step 2: Contribution Confirmation Screen
        expect(find.byType(ContributionConfirmationScreen), findsOneWidget);
        expect(find.text('Confirm contribution'), findsOneWidget);
        expect(find.text('Emergency Fund'), findsWidgets);
        expect(find.text('₦150,000.00'), findsWidgets); // Current balance
        expect(find.text('₦50,000.00'), findsWidgets); // Contribution amount
        expect(find.text('₦200,000.00'), findsWidgets); // Balance after
        expect(find.text('40%'), findsOneWidget); // Projected progress

        // Back Navigation: Tap back on confirmation screen returns to amount entry
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(ContributeAmountScreen), findsOneWidget);
        // Value preserved
        expect(
          find.byKey(const Key('projected_progress_card')),
          findsOneWidget,
        );

        // Back Navigation: Tap back on amount entry returns to goal details
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(GoalDetailsScreen), findsOneWidget);
        expect(find.text('Emergency Fund'), findsOneWidget);
      },
    );

    testWidgets(
      'Full online journey: Goal Details -> Amount -> Confirm -> Processing -> Success -> Done -> Confirmed progress advances',
      (tester) async {
        await tester.pumpWidget(
          buildFlow(connectivity: ConnectivityStatus.online),
        );
        goalsController.add([initialGoal]);
        activeOpsController.add([]);
        await tester.pumpAndSettle();

        // Step 0: Goal Details
        expect(find.text('Emergency Fund'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('30% complete'), findsOneWidget);

        // Step 1: Tap Contribute
        await tester.tap(
          find.byKey(const Key('goal_details_contribute_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '50000');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contribute_continue_button')));
        await tester.pumpAndSettle();

        // Step 2: Confirmation Screen
        expect(find.byType(ContributionConfirmationScreen), findsOneWidget);
        final confirmBtn = find.byKey(const Key('confirm_contribution_button'));
        expect(confirmBtn, findsOneWidget);
        expect(find.text('Confirm Contribution'), findsOneWidget);

        // Tap Confirm
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Step 3: Operation is enqueued
        expect(repo.operations.length, 1);
        final op = repo.operations.first;
        expect(op.type, OperationType.contribution);
        expect(
          op.payload.amount,
          const Money.fromKobo(5000000),
        ); // ₦50,000.00 exact kobo

        // Transitioned to Processing View
        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsOneWidget,
        );
        expect(find.text('Adding ₦50,000.00'), findsOneWidget);
        expect(
          find.text(
            'Adding to Emergency Fund. Please wait, this usually takes a few seconds.',
          ),
          findsOneWidget,
        );

        // Step 4: Remote completes successfully -> emit status completed
        final completedOp = op.markProcessing().markCompleted(
          remoteReference: 'REF-NSC-TEST-888',
          at: DateTime.utc(2026, 9, 22, 10, 5),
        );
        repo.emitOperation(completedOp);
        await tester.pump();
        await tester.pumpAndSettle();

        // Step 5: Auto-advances to Success View
        expect(
          find.byKey(const Key('contribution_result_success_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution successful'), findsOneWidget);
        expect(find.text('₦50,000.00'), findsWidgets);
        expect(find.text('New balance'), findsOneWidget);
        expect(find.text('₦200,000.00'), findsWidgets);
        expect(find.text('40%'), findsWidgets);
        expect(find.text('REF-NSC-TEST-888'), findsOneWidget);

        // Step 6: Tap "Done" returns to Goal Details Screen
        await tester.tap(
          find.byKey(const Key('contribution_success_done_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GoalDetailsScreen), findsOneWidget);

        // Goal updated with new confirmed balance
        final updatedGoal = initialGoal.copyWith(
          savedAmount: Money.fromNaira(200000), // ₦200,000.00 (40%)
        );
        goalsController.add([updatedGoal]);
        await tester.pumpAndSettle();

        // Confirmed progress now reflects remote completion
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦200,000.00'), findsOneWidget);
        expect(find.text('40% complete'), findsOneWidget);
        expect(find.text('₦300,000.00'), findsOneWidget); // Still to save
      },
    );

    testWidgets(
      'Full offline journey: Enqueued offline contribution keeps confirmed progress UNCHANGED (HC-MONEY, design rule)',
      (tester) async {
        await tester.pumpWidget(
          buildFlow(connectivity: ConnectivityStatus.offline),
        );
        goalsController.add([initialGoal]);
        activeOpsController.add([]);
        await tester.pumpAndSettle();

        // Step 0: Goal Details Screen shows offline notification (UI-NSV-18)
        expect(find.text("You're offline"), findsOneWidget);
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('30% complete'), findsOneWidget);

        // Step 1: Tap Contribute
        await tester.tap(
          find.byKey(const Key('goal_details_contribute_button')),
        );
        await tester.pumpAndSettle();

        // Step 2: Enter Amount ₦50,000.00 while offline
        await tester.enterText(find.byType(TextField), '50000');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contribute_continue_button')));
        await tester.pumpAndSettle();

        // Step 3: Confirmation Screen shows offline banner and button copy (UI-NSV-16 / NSV-016)
        expect(find.byType(ContributionConfirmationScreen), findsOneWidget);
        expect(
          find.text(
            'You are offline. This contribution will be queued securely and processed once you are back online.',
          ),
          findsOneWidget,
        );
        expect(find.text('Confirm Contribution'), findsOneWidget);

        // Tap Confirm while offline
        await tester.tap(find.byKey(const Key('confirm_contribution_button')));
        await tester.pumpAndSettle();

        // Step 4: Enqueued in pending status without network call (NSV-017 / HC-OFFLINE-DURABILITY)
        expect(repo.operations.length, 1);
        final op = repo.operations.first;
        expect(op.status, OperationStatus.pending);
        expect(
          op.payload.amount,
          const Money.fromKobo(5000000),
        ); // ₦50,000.00 exact kobo
        expect(op.idempotencyKey.value, isNotEmpty);

        // Step 5: Transitioned to Offline Pending View (UI-NSV-17)
        expect(
          find.byKey(const Key('contribution_result_pending_offline_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution Pending'), findsOneWidget);
        expect(find.text('₦50,000.00'), findsWidgets);
        expect(find.text('For: Emergency Fund'), findsOneWidget);
        expect(
          find.text('Pending — will add when back online'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Queued securely. We will add it automatically when you are online. You do not need to add it again.',
          ),
          findsOneWidget,
        );

        // Step 6: Tap "Back to goal"
        await tester.tap(
          find.byKey(const Key('contribution_pending_back_button')),
        );
        await tester.pumpAndSettle();

        // Returned to Goal Details Screen
        expect(find.byType(GoalDetailsScreen), findsOneWidget);

        // Emit the pending operation as an active operation
        activeOpsController.add([op]);
        await tester.pumpAndSettle();

        // CRITICAL HARD CONSTRAINT & DESIGN RULE ASSERTIONS:
        // Confirmed progress MUST NOT advance ahead of remote confirmation!
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget); // NOT ₦200,000.00!
        expect(find.text('30% complete'), findsOneWidget); // NOT 40%!
        expect(
          find.text('₦350,000.00'),
          findsOneWidget,
        ); // Still to save NOT ₦300,000.00!

        final progressBar = tester.widget<AppProgressBar>(
          find.byType(AppProgressBar),
        );
        expect(progressBar.progress, closeTo(0.30, 0.0001)); // NOT 0.40!

        // Pending contribution banner is visible
        expect(find.text('Pending'), findsOneWidget);
        expect(
          find.text('₦50,000.00 pending. Will contribute when back online.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Online recoverable sync failure displays retry option with stable idempotency key',
      (tester) async {
        await tester.pumpWidget(
          buildFlow(connectivity: ConnectivityStatus.online),
        );
        goalsController.add([initialGoal]);
        activeOpsController.add([]);
        await tester.pumpAndSettle();

        // Navigate and submit
        await tester.tap(
          find.byKey(const Key('goal_details_contribute_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '50000');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contribute_continue_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_contribution_button')));
        await tester.pumpAndSettle();

        expect(repo.operations.length, 1);
        final op = repo.operations.first;

        // Emit recoverable sync error
        final errorOp = op.markProcessing().markRecoverableError(
          error: SyncError.recoverable(message: 'Connection timed out'),
        );
        repo.emitOperation(errorOp);
        await tester.pump();
        await tester.pumpAndSettle();

        // Displays Sync Failure View (UI-NSV-21)
        expect(
          find.byKey(const Key('contribution_result_sync_failure_view')),
          findsOneWidget,
        );
        expect(find.text("We couldn't finish syncing"), findsOneWidget);
        expect(find.text('We could not add it yet'), findsOneWidget);
        expect(
          find.text(
            'Your contribution is still saved. We will keep trying, or you can try again now.',
          ),
          findsOneWidget,
        );

        // Retry button is available
        final retryBtn = find.byKey(
          const Key('contribution_sync_failure_retry_button'),
        );
        expect(retryBtn, findsOneWidget);
        expect(find.text('Try again now'), findsOneWidget);

        // Tap Retry button
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        // Verifies retryOperation was called with the exact stable operation identity
        expect(syncCoordinator.retryCount, 1);
        expect(syncCoordinator.lastRetriedId, op.id);
      },
    );

    testWidgets(
      'Terminal failure displays clear non-deduction explanation and returns to goal on Back',
      (tester) async {
        await tester.pumpWidget(
          buildFlow(connectivity: ConnectivityStatus.online),
        );
        goalsController.add([initialGoal]);
        activeOpsController.add([]);
        await tester.pumpAndSettle();

        // Navigate and submit
        await tester.tap(
          find.byKey(const Key('goal_details_contribute_button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '50000');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contribute_continue_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_contribution_button')));
        await tester.pumpAndSettle();

        expect(repo.operations.length, 1);
        final op = repo.operations.first;

        // Emit terminal failure
        final failedOp = op.markProcessing().markTerminalFailure(
          error: SyncError.terminal(message: 'Goal is locked by admin'),
        );
        repo.emitOperation(failedOp);
        await tester.pump();
        await tester.pumpAndSettle();

        // Displays Terminal Failed View (UI-NSV-15)
        expect(
          find.byKey(const Key('contribution_result_failed_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution failed'), findsOneWidget);
        expect(find.text('Could not add to Emergency Fund'), findsOneWidget);
        expect(
          find.text(
            'No funds were deducted from your wallet. Goal is locked by admin',
          ),
          findsOneWidget,
        );

        // Tap Back to goal
        final backBtn = find.byKey(
          const Key('contribution_failure_back_button'),
        );
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        // Returned cleanly to Goal Details Screen
        expect(find.byType(GoalDetailsScreen), findsOneWidget);
        expect(find.text('Emergency Fund'), findsOneWidget);
      },
    );
  });
}
