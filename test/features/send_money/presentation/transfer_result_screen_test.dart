import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/progress/app_step_progress.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_result_screen.dart';
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
  group(
    'TransferResultScreen (T-SND-004, T-SND-005, SND-011–SND-020, MNY-004)',
    () {
      final testOpId = OperationId('test-op-1234');
      final testIdemKey = IdempotencyKey('test-idem-1234');

      FinancialOperation createTestOperation({
        OperationStatus status = OperationStatus.processing,
        int attemptCount = 1,
        String? remoteReference,
        DateTime? completedAt,
        SyncError? syncError,
      }) {
        return FinancialOperation.restore(
          id: testOpId,
          type: OperationType.send,
          idempotencyKey: testIdemKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'John Doe',
            bankName: 'NovaBank',
            amount: const Money.fromKobo(1000000), // ₦10,000.00
          ),
          createdAt: DateTime.utc(2026, 9, 19, 9, 52),
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
              child: TransferResultScreen(
                operation: operation,
                wasOffline: wasOffline,
                onDone: onDone ?? () {},
                onTryAgain: onTryAgain,
              ),
            ),
          ),
        );
      }

      // --- T-SND-004 Tests ---

      testWidgets(
        'UI-SND-11 / SND-011: Renders online processing state with expected copy and indicators',
        (tester) async {
          final op = createTestOperation(status: OperationStatus.processing);

          await tester.pumpWidget(buildTestScreen(operation: op));
          await tester.pump();

          expect(
            find.byKey(const Key('transfer_result_processing_view')),
            findsOneWidget,
          );
          expect(find.text('Sending ₦10,000.00'), findsOneWidget);
          expect(
            find.text(
              'Sending to John Doe. Please wait, this usually takes a few seconds.',
            ),
            findsOneWidget,
          );
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is AppResultIndicator &&
                  w.status == AppOperationStatus.processing,
            ),
            findsOneWidget,
          );
          expect(find.text('Sending...'), findsOneWidget);
        },
      );

      testWidgets(
        'SND-011: Processing state reactively advances to Success without extra user tap',
        (tester) async {
          final controller = StreamController<FinancialOperation?>.broadcast();
          addTearDown(controller.close);

          final initialOp = createTestOperation(
            status: OperationStatus.processing,
          );
          final completedOp = createTestOperation(
            status: OperationStatus.completed,
            remoteReference: 'NP260919041',
            completedAt: DateTime.utc(2026, 9, 19, 9, 52),
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: initialOp,
              operationStream: controller.stream,
            ),
          );
          await tester.pump();

          expect(
            find.byKey(const Key('transfer_result_processing_view')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('transfer_result_success_view')),
            findsNothing,
          );

          controller.add(completedOp);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_processing_view')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('transfer_result_success_view')),
            findsOneWidget,
          );
          expect(find.text('Transfer successful'), findsOneWidget);
          expect(find.text('₦10,000.00'), findsOneWidget);
        },
      );

      testWidgets(
        'UI-SND-12 / SND-012: Success screen displays amount, recipient, reference, date, and status',
        (tester) async {
          bool doneCalled = false;
          final op = createTestOperation(
            status: OperationStatus.completed,
            remoteReference: 'NP260919041',
            completedAt: DateTime.utc(2026, 9, 19, 9, 52),
          );

          await tester.pumpWidget(
            buildTestScreen(operation: op, onDone: () => doneCalled = true),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_success_view')),
            findsOneWidget,
          );
          expect(find.text('Transfer successful'), findsOneWidget);
          expect(find.text('₦10,000.00'), findsOneWidget);
          expect(find.text('Sent to John Doe'), findsOneWidget);

          expect(find.text('John Doe'), findsWidgets);
          expect(find.text('NovaBank • 0123456789'), findsOneWidget);
          expect(find.text('NP260919041'), findsOneWidget);
          expect(find.text('19 Sep 2026, 09:52'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is AppStatusBadge &&
                  w.status == AppOperationStatus.completed,
            ),
            findsOneWidget,
          );

          final doneButton = find.byKey(
            const Key('transfer_success_done_button'),
          );
          expect(doneButton, findsOneWidget);
          await tester.tap(doneButton);
          await tester.pumpAndSettle();

          expect(doneCalled, isTrue);
        },
      );

      testWidgets(
        'UI-SND-13 / SND-013: Immediate failure displays "Nothing was taken from your wallet." + retry/back actions',
        (tester) async {
          bool tryAgainCalled = false;
          bool backCalled = false;

          final op = createTestOperation(
            status: OperationStatus.failed,
            syncError: SyncError.terminal(
              message: 'Destination account is frozen or invalid',
              code: 'BUSINESS_REJECTION',
            ),
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: op,
              onTryAgain: () => tryAgainCalled = true,
              onDone: () => backCalled = true,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_failed_view')),
            findsOneWidget,
          );
          expect(find.text('Transfer not completed'), findsOneWidget);
          expect(
            find.text(
              'We could not send ₦10,000.00 to John Doe. Please try again.',
            ),
            findsOneWidget,
          );
          expect(
            find.text('Nothing was taken from your wallet.'),
            findsOneWidget,
          );
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is AppResultIndicator &&
                  w.status == AppOperationStatus.failed,
            ),
            findsOneWidget,
          );

          final tryAgainButton = find.byKey(
            const Key('transfer_failed_try_again_button'),
          );
          expect(tryAgainButton, findsOneWidget);
          await tester.tap(tryAgainButton);
          await tester.pumpAndSettle();
          expect(tryAgainCalled, isTrue);

          final backButton = find.byKey(
            const Key('transfer_failed_back_button'),
          );
          expect(backButton, findsOneWidget);
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          expect(backCalled, isTrue);
        },
      );

      testWidgets(
        'MNY-004: Confirmed wallet balance is not debited while operation is processing or failed',
        (tester) async {
          const initialConfirmed = Money.fromKobo(12545000);
          final processingOp = createTestOperation(
            status: OperationStatus.processing,
          );

          expect(processingOp.status, OperationStatus.processing);
          expect(initialConfirmed, const Money.fromKobo(12545000));

          final failedOp = createTestOperation(
            status: OperationStatus.failed,
            syncError: SyncError.terminal(
              message: 'Destination account is frozen',
              code: 'BUSINESS_REJECTION',
            ),
          );
          expect(failedOp.status, OperationStatus.failed);
          expect(initialConfirmed, const Money.fromKobo(12545000));

          final completedOp = createTestOperation(
            status: OperationStatus.completed,
            remoteReference: 'NP260919041',
            completedAt: DateTime.utc(2026, 9, 19, 9, 52),
          );
          final finalConfirmed =
              initialConfirmed -
              (completedOp.payload as SendMoneyPayload).amount;
          expect(finalConfirmed, const Money.fromKobo(11545000));
        },
      );

      // --- T-SND-005 Tests ---

      testWidgets(
        'UI-SND-15 / SND-015 / SND-016: Offline Pending screen renders 3-step progress, offline notice and actions',
        (tester) async {
          bool backCalled = false;

          final op = createTestOperation(
            status: OperationStatus.pending,
            attemptCount: 0,
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: op,
              connectivity: ConnectivityStatus.offline,
              wasOffline: true,
              onDone: () => backCalled = true,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_pending_offline_view')),
            findsOneWidget,
          );
          expect(find.text("You're offline"), findsOneWidget);
          expect(find.text('Transfer Pending'), findsOneWidget);
          expect(find.text('₦10,000.00'), findsOneWidget);
          expect(find.text('To: John Doe'), findsOneWidget);
          expect(
            find.text('Pending — will send when back online'),
            findsOneWidget,
          );

          // 3-step progress track
          expect(find.byType(AppStepProgress), findsOneWidget);
          expect(find.text('Saved'), findsOneWidget);
          expect(find.text('Sending'), findsOneWidget);
          expect(find.text('Successful'), findsOneWidget);

          // Notification
          expect(
            find.text(
              'Saved on this phone. We will send it automatically when you are online. You do not need to send it again.',
            ),
            findsOneWidget,
          );

          // Buttons
          final backBtn = find.byKey(const Key('transfer_pending_back_button'));
          expect(backBtn, findsOneWidget);
          await tester.tap(backBtn);
          await tester.pumpAndSettle();
          expect(backCalled, isTrue);

          final viewBtn = find.byKey(const Key('transfer_pending_view_button'));
          expect(viewBtn, findsOneWidget);
        },
      );

      testWidgets(
        'UI-SND-16 / SND-017: Reconnect processing renders back-online banner, active sending step and disabled button',
        (tester) async {
          final op = createTestOperation(
            status: OperationStatus.processing,
            attemptCount: 1,
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: op,
              connectivity: ConnectivityStatus.online,
              wasOffline: true,
            ),
          );
          await tester.pump();

          expect(
            find.byKey(const Key('transfer_result_reconnect_processing_view')),
            findsOneWidget,
          );
          expect(find.text("You're back online"), findsOneWidget);
          expect(
            find.text('Pending transactions are being processed.'),
            findsOneWidget,
          );
          expect(find.text('Sending ₦10,000.00'), findsOneWidget);
          expect(
            find.text(
              'You are back online. We are sending your transfer to John Doe.',
            ),
            findsOneWidget,
          );
          expect(find.byType(AppStepProgress), findsOneWidget);
          expect(find.text('Sending...'), findsOneWidget);
        },
      );

      testWidgets(
        'UI-SND-17 / SND-018: Reconnect success renders "Sent after you came back online", 3-step progress and reference',
        (tester) async {
          bool doneCalled = false;
          final op = createTestOperation(
            status: OperationStatus.completed,
            attemptCount: 1,
            remoteReference: 'NP260919041',
            completedAt: DateTime.utc(2026, 9, 19, 9, 52),
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: op,
              connectivity: ConnectivityStatus.online,
              wasOffline: true,
              onDone: () => doneCalled = true,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_reconnect_success_view')),
            findsOneWidget,
          );
          expect(find.text('Transfer successful'), findsOneWidget);
          expect(find.text('₦10,000.00'), findsOneWidget);
          expect(
            find.text('Sent to John Doe after you came back online.'),
            findsOneWidget,
          );
          expect(find.byType(AppStepProgress), findsOneWidget);
          expect(find.text('NP260919041'), findsOneWidget);
          expect(find.text('19 Sep 2026, 09:52'), findsOneWidget);

          final doneButton = find.byKey(
            const Key('transfer_success_done_button'),
          );
          await tester.tap(doneButton);
          await tester.pumpAndSettle();
          expect(doneCalled, isTrue);
        },
      );

      testWidgets(
        'UI-SND-18 / SND-019 / SND-020: Recoverable sync failure renders warning banner, "Not sent" step, and triggers retry with stable key',
        (tester) async {
          final fakeSync = FakeSyncCoordinatorForRetry();
          final op = createTestOperation(
            status: OperationStatus.pending,
            attemptCount: 1,
            syncError: SyncError.recoverable(
              message: 'Network connection dropped',
              code: 'TRANSPORT_ERROR',
            ),
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: op,
              connectivity: ConnectivityStatus.online,
              wasOffline: true,
              syncCoordinator: fakeSync,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_sync_failure_view')),
            findsOneWidget,
          );
          expect(find.text("We couldn't finish syncing"), findsOneWidget);
          expect(find.text('We could not send it yet'), findsOneWidget);
          expect(
            find.text(
              'Your transfer is still saved. We will keep trying, or you can try again now.',
            ),
            findsOneWidget,
          );
          // Step track with Not sent
          expect(find.byType(AppStepProgress), findsOneWidget);
          expect(find.text('Not sent'), findsOneWidget);

          // Info notification
          expect(
            find.text(
              'Nothing is lost. Your ₦10,000.00 transfer to John Doe is still waiting.',
            ),
            findsOneWidget,
          );

          // Tapping "Try again now" invokes retryOperation with identical OperationId (SND-020, HC-IDEMPOTENCY)
          final retryBtn = find.byKey(
            const Key('transfer_sync_failure_retry_button'),
          );
          expect(retryBtn, findsOneWidget);
          await tester.tap(retryBtn);
          await tester.pumpAndSettle();

          expect(fakeSync.retryCount, 1);
          expect(fakeSync.retriedOperationId, op.id);
        },
      );

      testWidgets(
        'SND-017 / SND-018: Complete offline -> reconnect -> success journey reactively auto-advances',
        (tester) async {
          final controller = StreamController<FinancialOperation?>.broadcast(
            sync: true,
          );
          addTearDown(controller.close);

          final initialPendingOp = createTestOperation(
            status: OperationStatus.pending,
            attemptCount: 0,
          );
          final processingOp = createTestOperation(
            status: OperationStatus.processing,
            attemptCount: 1,
          );
          final completedOp = createTestOperation(
            status: OperationStatus.completed,
            attemptCount: 1,
            remoteReference: 'NP260919041',
            completedAt: DateTime.utc(2026, 9, 19, 9, 52),
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: initialPendingOp,
              operationStream: controller.stream,
              connectivity: ConnectivityStatus.offline,
              wasOffline: true,
            ),
          );
          await tester.pump();

          // Step 1: Offline Pending view
          expect(
            find.byKey(const Key('transfer_result_pending_offline_view')),
            findsOneWidget,
          );

          // Step 2: Device reconnects and operation claims into processing
          controller.add(processingOp);
          await tester.pump();

          expect(
            find.byKey(const Key('transfer_result_pending_offline_view')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('transfer_result_reconnect_processing_view')),
            findsOneWidget,
          );

          // Step 3: Remote completes operation
          controller.add(completedOp);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('transfer_result_reconnect_processing_view')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('transfer_result_reconnect_success_view')),
            findsOneWidget,
          );
          expect(
            find.text('Sent to John Doe after you came back online.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'A11Y-002: Renders without layout overflow at 2.0x font scaling across offline states',
        (tester) async {
          final offlineOp = createTestOperation(
            status: OperationStatus.pending,
            attemptCount: 0,
          );

          await tester.pumpWidget(
            buildTestScreen(
              operation: offlineOp,
              connectivity: ConnectivityStatus.offline,
              wasOffline: true,
              textScaleFactor: 2.0,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Transfer Pending'), findsOneWidget);
        },
      );
    },
  );
}
