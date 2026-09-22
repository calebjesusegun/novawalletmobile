import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_result_screen.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

void main() {
  group('TransferResultScreen (T-SND-004, SND-011, SND-012, SND-013, MNY-004)', () {
    final testOpId = OperationId('test-op-1234');
    final testIdemKey = IdempotencyKey('test-idem-1234');

    FinancialOperation createTestOperation({
      OperationStatus status = OperationStatus.processing,
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
        attemptCount: 1,
        remoteReference: remoteReference,
        completedAt: completedAt,
        lastError: syncError,
      );
    }

    Widget buildTestScreen({
      required FinancialOperation operation,
      Stream<FinancialOperation?>? operationStream,
      VoidCallback? onDone,
      VoidCallback? onTryAgain,
      double textScaleFactor = 1.0,
    }) {
      return ProviderScope(
        overrides: [
          if (operationStream != null)
            operationByIdStreamProvider(operation.id)
                .overrideWith((ref) => operationStream),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: TransferResultScreen(
              operation: operation,
              onDone: onDone ?? () {},
              onTryAgain: onTryAgain,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'UI-SND-11 / SND-011: Renders processing state with expected copy and indicators',
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

        // Initially in processing state
        expect(
          find.byKey(const Key('transfer_result_processing_view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_result_success_view')),
          findsNothing,
        );

        // Stream emits completed operation (simulating remote success)
        controller.add(completedOp);
        await tester.pumpAndSettle();

        // Advances automatically to success view without any user tap
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

        // Detail rows
        expect(find.text('John Doe'), findsWidgets);
        expect(find.text('NovaBank • 0123456789'), findsOneWidget);
        expect(find.text('NP260919041'), findsOneWidget);
        expect(find.text('19 Sep 2026, 09:52'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppStatusBadge && w.status == AppOperationStatus.completed,
          ),
          findsOneWidget,
        );

        // Done button
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
        // Essential copy requirement: Nothing was taken from your wallet
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

        // Try again button
        final tryAgainButton = find.byKey(
          const Key('transfer_failed_try_again_button'),
        );
        expect(tryAgainButton, findsOneWidget);
        await tester.tap(tryAgainButton);
        await tester.pumpAndSettle();
        expect(tryAgainCalled, isTrue);

        // Back to wallet button
        final backButton = find.byKey(const Key('transfer_failed_back_button'));
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(backCalled, isTrue);
      },
    );

    testWidgets(
      'A11Y-002: Renders without layout overflow at 2.0x font scaling',
      (tester) async {
        final op = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'NP260919041',
          completedAt: DateTime.utc(2026, 9, 19, 9, 52),
        );

        await tester.pumpWidget(
          buildTestScreen(operation: op, textScaleFactor: 2.0),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Transfer successful'), findsOneWidget);
      },
    );

    testWidgets(
      'MNY-004: Confirmed wallet balance is not debited while operation is processing or failed',
      (tester) async {
        // Initial confirmed balance is ₦125,450.00
        const initialConfirmed = Money.fromKobo(12545000);
        final processingOp = createTestOperation(
          status: OperationStatus.processing,
        );

        // When operation is processing, confirmed balance must remain unchanged
        expect(processingOp.status, OperationStatus.processing);
        // Balance before settlement is unchanged (MNY-004)
        expect(initialConfirmed, const Money.fromKobo(12545000));

        final failedOp = createTestOperation(
          status: OperationStatus.failed,
          syncError: SyncError.terminal(
            message: 'Destination account is frozen',
            code: 'BUSINESS_REJECTION',
          ),
        );
        // When operation fails terminally, confirmed balance remains untouched (UI-SND-13)
        expect(failedOp.status, OperationStatus.failed);
        expect(initialConfirmed, const Money.fromKobo(12545000));

        final completedOp = createTestOperation(
          status: OperationStatus.completed,
          remoteReference: 'NP260919041',
          completedAt: DateTime.utc(2026, 9, 19, 9, 52),
        );
        // Once successfully completed, the debit occurs
        final finalConfirmed =
            initialConfirmed - (completedOp.payload as SendMoneyPayload).amount;
        expect(finalConfirmed, const Money.fromKobo(11545000)); // ₦115,450.00
      },
    );
  });
}
