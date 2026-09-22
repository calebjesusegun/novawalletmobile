import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/progress/app_step_progress.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_result_screen.dart';
import 'package:novawallet/sync/application/retry_policy.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

class FakeSyncCoordinatorForRetry implements SyncCoordinator {
  int retryCount = 0;
  OperationId? retriedOperationId;

  @override
  Future<RetryResult> retryOperation(OperationId id) async {
    retryCount++;
    retriedOperationId = id;
    return const RetryResult.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ContributionResultScreen (T-NSC-003, UI-NSV-12–UI-NSV-15, NSV-013–NSV-015, MNY-005)', () {
    final testOpId = OperationId('test-nsc-op-123');
    final testIdemKey = IdempotencyKey('idem_nsc_test_123');

    final testGoal = SavingsGoal(
      id: 'goal_car_999',
      name: 'Car insurance',
      targetAmount: const Money.fromKobo(10000000), // ₦100,000.00
      savedAmount: const Money.fromKobo(2000000), // ₦20,000.00 (20%)
      targetDate: DateTime.utc(2027, 1, 1),
    );

    const testContributionAmount = Money.fromKobo(500000); // ₦5,000.00

    FinancialOperation createTestOperation({
      OperationStatus status = OperationStatus.processing,
      int attemptCount = 1,
      String? remoteReference,
      DateTime? completedAt,
      SyncError? syncError,
    }) {
      return FinancialOperation.restore(
        id: testOpId,
        type: OperationType.contribution,
        idempotencyKey: testIdemKey,
        payload: ContributionPayload(
          goalId: testGoal.id,
          goalName: testGoal.name,
          amount: testContributionAmount,
        ),
        createdAt: DateTime.utc(2026, 9, 22, 10, 0),
        status: status,
        attemptCount: attemptCount,
        remoteReference: remoteReference,
        completedAt: completedAt,
        lastError: syncError,
      );
    }

    Widget buildTestScreen({
      required FinancialOperation operation,
      Stream<FinancialOperation?>? operationStream,
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      bool wasOffline = false,
      VoidCallback? onDone,
      VoidCallback? onTryAgain,
      SyncCoordinator? syncCoordinator,
      double textScaleFactor = 1.0,
    }) {
      return ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWithValue(connectivity),
          if (operationStream != null)
            operationByIdStreamProvider(operation.id)
                .overrideWith((ref) => operationStream),
          if (syncCoordinator != null)
            syncCoordinatorProvider.overrideWithValue(syncCoordinator),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: ContributionResultScreen(
              operation: operation,
              goal: testGoal,
              wasOffline: wasOffline,
              onDone: onDone ?? () {},
              onTryAgain: onTryAgain,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'UI-NSV-12: Online processing view displays progress indicator, Adding text, and disabled button',
      (tester) async {
        final op = createTestOperation(status: OperationStatus.processing);

        await tester.pumpWidget(buildTestScreen(operation: op));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsOneWidget,
        );
        expect(find.byType(AppResultIndicator), findsOneWidget);
        expect(find.text('Adding ₦5,000.00'), findsOneWidget);
        expect(
          find.text(
            'Adding to Car insurance. Please wait, this usually takes a few seconds.',
          ),
          findsOneWidget,
        );
        expect(find.text('Adding...'), findsOneWidget);

        // Button is disabled during processing
        final button = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Adding...'),
        );
        expect(button.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-NSV-13: Online success view displays completed indicator, details card, and Done button',
      (tester) async {
        final op = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'REMOTE-NSC-777',
          completedAt: DateTime.utc(2026, 9, 22, 10, 0, 5),
        );

        bool doneTapped = false;

        await tester.pumpWidget(
          buildTestScreen(operation: op, onDone: () => doneTapped = true),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_success_view')),
          findsOneWidget,
        );
        expect(find.byType(AppResultIndicator), findsOneWidget);
        expect(find.text('Contribution successful'), findsOneWidget);
        expect(find.text('₦5,000.00'), findsNWidgets(2)); // headline & row
        expect(find.text('Added to Car insurance'), findsOneWidget);

        // Details Card
        expect(find.text('Goal'), findsOneWidget);
        expect(find.text('Car insurance'), findsOneWidget);
        expect(find.text('Contribution'), findsOneWidget);
        expect(find.text('New balance'), findsOneWidget);
        expect(find.text('₦25,000.00'), findsOneWidget); // 20k + 5k
        expect(find.text('Target'), findsOneWidget);
        expect(find.text('₦100,000.00'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget); // 25k of 100k
        expect(find.text('Reference'), findsOneWidget);
        expect(find.text('REMOTE-NSC-777'), findsOneWidget);

        // Tap Done
        final doneButton = find.byKey(
          const Key('contribution_success_done_button'),
        );
        expect(doneButton, findsOneWidget);
        await tester.tap(doneButton);
        expect(doneTapped, isTrue);
      },
    );

    testWidgets(
      'UI-NSV-15: Online failure view displays failed indicator, non-debited explanation, and retry/back buttons',
      (tester) async {
        final syncCoordinator = FakeSyncCoordinatorForRetry();
        final op = createTestOperation(
          status: OperationStatus.failed,
          syncError: SyncError.terminal(
            message: 'Goal has expired or reached target limit.',
          ),
        );

        bool backTapped = false;

        await tester.pumpWidget(
          buildTestScreen(
            operation: op,
            syncCoordinator: syncCoordinator,
            onDone: () => backTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_failed_view')),
          findsOneWidget,
        );
        expect(find.byType(AppResultIndicator), findsOneWidget);
        expect(find.text('Contribution failed'), findsOneWidget);
        expect(find.text('₦5,000.00'), findsOneWidget);
        expect(find.text('Could not add to Car insurance'), findsOneWidget);
        expect(
          find.text(
            'No funds were deducted from your wallet. Goal has expired or reached target limit.',
          ),
          findsOneWidget,
        );

        // Tap Try again
        final retryBtn = find.byKey(
          const Key('contribution_failure_retry_button'),
        );
        expect(retryBtn, findsOneWidget);
        await tester.tap(retryBtn);
        expect(syncCoordinator.retryCount, equals(1));
        expect(syncCoordinator.retriedOperationId, equals(testOpId));

        // Tap Back to goal
        final backBtn = find.byKey(
          const Key('contribution_failure_back_button'),
        );
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        expect(backTapped, isTrue);
      },
    );

    testWidgets(
      'Reactive stream transition from Processing to Completed updates UI automatically',
      (tester) async {
        final streamController =
            StreamController<FinancialOperation?>.broadcast();
        addTearDown(streamController.close);

        final initialOp = createTestOperation(
          status: OperationStatus.processing,
        );

        await tester.pumpWidget(
          buildTestScreen(
            operation: initialOp,
            operationStream: streamController.stream,
          ),
        );
        await tester.pump();

        // Initially processing
        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('contribution_result_success_view')),
          findsNothing,
        );

        // Stream emits completed operation
        final completedOp = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'REMOTE-STREAM-123',
          completedAt: DateTime.utc(2026, 9, 22, 10, 0, 3),
        );
        streamController.add(completedOp);
        await tester.pumpAndSettle();

        // Now success view
        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('contribution_result_success_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution successful'), findsOneWidget);
        expect(find.text('REMOTE-STREAM-123'), findsOneWidget);
      },
    );

    testWidgets(
      'Reactive stream transition from Processing to Failed updates UI automatically',
      (tester) async {
        final streamController =
            StreamController<FinancialOperation?>.broadcast();
        addTearDown(streamController.close);

        final initialOp = createTestOperation(
          status: OperationStatus.processing,
        );

        await tester.pumpWidget(
          buildTestScreen(
            operation: initialOp,
            operationStream: streamController.stream,
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsOneWidget,
        );

        // Stream emits failed operation
        final failedOp = createTestOperation(
          status: OperationStatus.failed,
          syncError: SyncError.terminal(message: 'Payment rejected'),
        );
        streamController.add(failedOp);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_processing_view')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('contribution_result_failed_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution failed'), findsOneWidget);
      },
    );

    testWidgets(
      'UI-NSV-17: Offline pending view displays offline banner, step progress, and notice',
      (tester) async {
        final op = createTestOperation(status: OperationStatus.pending);

        await tester.pumpWidget(
          buildTestScreen(
            operation: op,
            connectivity: ConnectivityStatus.offline,
            wasOffline: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_pending_offline_view')),
          findsOneWidget,
        );
        expect(find.text("You're offline"), findsOneWidget);
        expect(find.text('Contribution Pending'), findsOneWidget);
        expect(find.text('For: Car insurance'), findsOneWidget);
        expect(find.byType(AppStepProgress), findsOneWidget);
        expect(
          find.text(
            'Saved on this phone. We will add it automatically when you are online. You do not need to add it again.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('contribution_pending_back_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UI-NSV-19: Reconnect processing view displays back online banner, Adding text, and disabled button',
      (tester) async {
        final op = createTestOperation(status: OperationStatus.processing);

        await tester.pumpWidget(
          buildTestScreen(
            operation: op,
            connectivity: ConnectivityStatus.online,
            wasOffline: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('contribution_result_reconnect_processing_view'),
          ),
          findsOneWidget,
        );
        expect(find.text('Back online'), findsOneWidget);
        expect(find.text('Adding ₦5,000.00'), findsOneWidget);
        expect(
          find.text('Adding to Car insurance after you came back online.'),
          findsOneWidget,
        );
        expect(find.byType(AppStepProgress), findsOneWidget);
        expect(find.text('Adding...'), findsOneWidget);
      },
    );

    testWidgets(
      'UI-NSV-20: Reconnect success view displays reconnect success progression and Done button',
      (tester) async {
        final op = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'REMOTE-RECONNECT-456',
          completedAt: DateTime.utc(2026, 9, 22, 10, 0, 8),
        );

        bool doneTapped = false;

        await tester.pumpWidget(
          buildTestScreen(
            operation: op,
            connectivity: ConnectivityStatus.online,
            wasOffline: true,
            onDone: () => doneTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_reconnect_success_view')),
          findsOneWidget,
        );
        expect(find.text('Contribution successful'), findsOneWidget);
        expect(find.text('₦5,000.00'), findsOneWidget);
        expect(
          find.text('Added to Car insurance after you came back online.'),
          findsOneWidget,
        );
        expect(find.byType(AppStepProgress), findsOneWidget);
        expect(find.text('Goal'), findsOneWidget);
        expect(find.text('Car insurance'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('Reference'), findsOneWidget);
        expect(find.text('REMOTE-RECONNECT-456'), findsOneWidget);

        final doneBtn = find.byKey(
          const Key('contribution_reconnect_done_button'),
        );
        expect(doneBtn, findsOneWidget);
        await tester.tap(doneBtn);
        expect(doneTapped, isTrue);
      },
    );

    testWidgets(
      'UI-NSV-21: Recoverable sync failure view displays retryable banner and action',
      (tester) async {
        final syncCoordinator = FakeSyncCoordinatorForRetry();
        final op = createTestOperation(
          status: OperationStatus.pending,
          syncError: SyncError.recoverable(message: 'Connection timed out'),
        );

        await tester.pumpWidget(
          buildTestScreen(operation: op, syncCoordinator: syncCoordinator),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('contribution_result_sync_failure_view')),
          findsOneWidget,
        );
        expect(find.text("We couldn't finish syncing"), findsOneWidget);
        expect(find.text('We could not add it yet'), findsOneWidget);
        expect(
          find.byKey(const Key('contribution_sync_failure_retry_button')),
          findsOneWidget,
        );

        // Tap retry
        await tester.tap(
          find.byKey(const Key('contribution_sync_failure_retry_button')),
        );
        expect(syncCoordinator.retryCount, equals(1));
      },
    );

    testWidgets(
      'HC-ACCESSIBILITY: Renders without layout overflow at 2.0x system text scaling',
      (tester) async {
        final op = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'REF-ACCESSIBILITY',
          completedAt: DateTime.utc(2026, 9, 22, 10, 0, 5),
        );

        await tester.pumpWidget(
          buildTestScreen(operation: op, textScaleFactor: 2.0),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Contribution successful'), findsOneWidget);
      },
    );
  });
}
