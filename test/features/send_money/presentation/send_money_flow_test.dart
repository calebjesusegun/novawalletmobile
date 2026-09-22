import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/send_money_flow_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_confirmation_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

class MockFlowOperationRepository implements OperationRepository {
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
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  }) async {
    final op = FinancialOperation.send(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
    operations.add(op);
    _getOrCreateController(id).add(op);
    return op;
  }

  @override
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) => throw UnimplementedError();

  @override
  Future<bool> claim(OperationId id, {DateTime? at}) =>
      throw UnimplementedError();

  @override
  Future<List<FinancialOperation>> getActiveOperations() async => [];

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
  ) async => null;

  @override
  Future<List<FinancialOperation>> getPendingOperations() async =>
      operations.where((op) => op.status == OperationStatus.pending).toList();

  @override
  Future<FinancialOperation> markCompleted(
    OperationId id, {
    required String remoteReference,
    DateTime? at,
  }) => throw UnimplementedError();

  @override
  Future<FinancialOperation> markFailed(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) => throw UnimplementedError();

  @override
  Future<FinancialOperation> markPendingWithError(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) => throw UnimplementedError();

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

class MockFlowSyncCoordinator implements SyncCoordinator {
  int syncCount = 0;

  @override
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    syncCount++;
    return SyncRunResult.empty(trigger);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ASM-005 / ASM-022 / TST-004 — SendMoneyFlowScreen full journey tests', () {
    late MockFlowOperationRepository repo;
    late MockFlowSyncCoordinator syncCoordinator;

    setUp(() {
      repo = MockFlowOperationRepository();
      syncCoordinator = MockFlowSyncCoordinator();
    });

    tearDown(() {
      repo.dispose();
    });

    List<Override> createOverrides({
      ConnectivityStatus connectivity = ConnectivityStatus.online,
    }) {
      return [
        connectivityStatusProvider.overrideWithValue(connectivity),
        operationRepositoryProvider.overrideWithValue(repo),
        syncCoordinatorProvider.overrideWithValue(syncCoordinator),
        walletProjectionProvider.overrideWithValue(
          AsyncValue.data(
            WalletProjection(
              confirmedBalance: Money.fromNaira(50000),
              spendableBalance: Money.fromNaira(50000),
              pendingDebitTotal: const Money.zero(),
              lastUpdatedAt: DateTime.utc(2026, 9, 21),
              activities: const [],
              pendingOperations: const [],
            ),
          ),
        ),
      ];
    }

    Widget buildFlow({
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      ProviderContainer? container,
    }) {
      if (container != null) {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SendMoneyFlowScreen(),
          ),
        );
      }

      return ProviderScope(
        overrides: createOverrides(connectivity: connectivity),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SendMoneyFlowScreen(),
        ),
      );
    }

    testWidgets(
      'transitions from RecipientEntryScreen to AmountEntryScreen and supports back navigation',
      (tester) async {
        await tester.pumpWidget(buildFlow());
        await tester.pumpAndSettle();

        expect(find.byType(RecipientEntryScreen), findsOneWidget);
        expect(find.byType(AmountEntryScreen), findsNothing);

        // Enter valid recipient account number
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();

        // Tap Continue to navigate to AmountEntryScreen
        final continueButton = find.widgetWithText(AppButton, 'Continue');
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.byType(RecipientEntryScreen), findsNothing);
        expect(find.byType(AmountEntryScreen), findsOneWidget);

        // Tap Change in header summary chip to navigate back to RecipientEntryScreen
        final changeButton = find.widgetWithText(TextButton, 'Change');
        expect(changeButton, findsOneWidget);
        await tester.tap(changeButton);
        await tester.pumpAndSettle();

        expect(find.byType(RecipientEntryScreen), findsOneWidget);
        expect(find.byType(AmountEntryScreen), findsNothing);
      },
    );

    testWidgets(
      'flow validation blocking: invalid recipient, zero amount, and excess amount block continuation',
      (tester) async {
        await tester.pumpWidget(buildFlow());
        await tester.pumpAndSettle();

        // 1. Recipient validation: short account cannot continue
        await tester.enterText(find.byType(TextField), '12345');
        await tester.pumpAndSettle();
        final recipientContinue = find.widgetWithText(AppButton, 'Continue');
        await tester.tap(recipientContinue);
        await tester.pumpAndSettle();
        expect(find.byType(AmountEntryScreen), findsNothing);

        // Enter valid recipient and continue
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();
        await tester.tap(recipientContinue);
        await tester.pumpAndSettle();
        expect(find.byType(AmountEntryScreen), findsOneWidget);

        // 2. Amount validation: zero amount disables continue
        final amountField = find.byType(TextFormField);
        await tester.enterText(amountField, '0');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
              .onPressed,
          isNull,
        );

        // 3. Amount validation: amount exceeding available balance (₦60,000 > ₦50,000) disables continue
        await tester.enterText(amountField, '60000');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
              .onPressed,
          isNull,
        );
        expect(find.text('Amount exceeds available balance.'), findsOneWidget);

        // Enter valid amount within balance enables continue
        await tester.enterText(amountField, '10000');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'full online journey: Recipient -> Amount -> Confirmation -> Submit -> Success -> Done returns to Wallet',
      (tester) async {
        final container = ProviderContainer(overrides: createOverrides());
        addTearDown(container.dispose);

        await tester.pumpWidget(buildFlow(container: container));
        await tester.pumpAndSettle();

        // Step 1: Recipient
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 2: Amount
        await tester.enterText(find.byType(TextFormField), '10000');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 3: Confirmation
        expect(find.byType(TransferConfirmationScreen), findsOneWidget);
        expect(find.text('Confirm Transfer'), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirm_transfer_button')));
        await tester.pumpAndSettle();

        // Enqueued and entered Processing state
        expect(repo.operations.length, 1);
        final submittedOp = repo.operations.first;
        expect(submittedOp.payload.amount, const Money.fromKobo(1000000));
        expect(
          find.byKey(const Key('transfer_result_processing_view')),
          findsOneWidget,
        );
        expect(find.text('Sending ₦10,000.00'), findsOneWidget);

        // Step 4: Operation completes remotely -> transition to Online Success view
        final completedOp = submittedOp.markProcessing().markCompleted(
          remoteReference: 'REF-ONLINE-SUCCESS-001',
        );
        repo.emitOperation(completedOp);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('transfer_result_success_view')),
          findsOneWidget,
        );
        expect(find.text('Transfer successful'), findsOneWidget);

        // Step 5: Tap "Done" button -> resets Send Money and navigates to Wallet tab
        final doneButton = find.byKey(
          const Key('transfer_success_done_button'),
        );
        expect(doneButton, findsOneWidget);
        await tester.tap(doneButton);
        await tester.pumpAndSettle();

        expect(container.read(appNavigationProvider), AppDestination.wallet);
      },
    );

    testWidgets(
      'full offline journey: Recipient -> Amount -> Confirmation -> Enqueue -> Pending -> Back to wallet returns to Wallet',
      (tester) async {
        final container = ProviderContainer(
          overrides: createOverrides(connectivity: ConnectivityStatus.offline),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildFlow(
            connectivity: ConnectivityStatus.offline,
            container: container,
          ),
        );
        await tester.pumpAndSettle();

        // Step 1: Recipient entry while offline
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 2: Amount entry while offline
        expect(find.byType(AmountEntryScreen), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), '5000');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 3: Confirmation screen shows offline notification banner (UI-SND-14)
        expect(find.byType(TransferConfirmationScreen), findsOneWidget);
        expect(find.text('Confirm Transfer'), findsOneWidget);
        expect(
          find.text(
            "You're offline. Transfer will be queued securely and sent when connected.",
          ),
          findsOneWidget,
        );

        // Tap confirm button while offline
        await tester.tap(find.byKey(const Key('confirm_transfer_button')));
        await tester.pumpAndSettle();

        // Enqueued in pending status without remote attempt (HC-OFFLINE-DURABILITY)
        expect(repo.operations.length, 1);
        final op = repo.operations.first;
        expect(op.status, OperationStatus.pending);
        expect(op.payload.amount, const Money.fromKobo(500000)); // ₦5,000.00

        // Transitioned to pending result view (UI-SND-15 / SND-016)
        expect(
          find.byKey(const Key('transfer_result_pending_offline_view')),
          findsOneWidget,
        );
        expect(find.text('Transfer Pending'), findsOneWidget);
        expect(find.text('₦5,000.00'), findsOneWidget);
        expect(
          find.text('Pending — will send when back online'),
          findsOneWidget,
        );

        // Step 4: Tap "Back to wallet" -> resets Send Money and navigates to Wallet tab
        final backButton = find.byKey(
          const Key('transfer_pending_back_button'),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(container.read(appNavigationProvider), AppDestination.wallet);
      },
    );

    testWidgets(
      'online failure journey: Recipient -> Amount -> Confirm -> Processing -> Failure -> Try Again resets to retry',
      (tester) async {
        await tester.pumpWidget(buildFlow());
        await tester.pumpAndSettle();

        // Step 1: Recipient
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 2: Amount
        await tester.enterText(find.byType(TextFormField), '10000');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // Step 3: Confirmation
        await tester.tap(find.byKey(const Key('confirm_transfer_button')));
        await tester.pumpAndSettle();

        expect(repo.operations.length, 1);
        final submittedOp = repo.operations.first;

        // Step 4: Operation fails -> transition to Failure view
        final failedOp = submittedOp.markProcessing().markTerminalFailure(
          error: SyncError.terminal(
            message: 'Transaction declined by beneficiary bank.',
          ),
        );
        repo.emitOperation(failedOp);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('transfer_result_failed_view')),
          findsOneWidget,
        );
        expect(find.text('Transfer not completed'), findsOneWidget);

        // Step 5: Tap "Try Again" -> resets result view to allow user to retry
        final tryAgainButton = find.byKey(
          const Key('transfer_failed_try_again_button'),
        );
        expect(tryAgainButton, findsOneWidget);
        await tester.tap(tryAgainButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('transfer_result_failed_view')),
          findsNothing,
        );
        expect(find.byType(TransferConfirmationScreen), findsOneWidget);
      },
    );
  });
}
