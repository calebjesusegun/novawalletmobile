import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<FinancialOperation> enqueue(FinancialOperation operation) async {
    operations.add(operation);
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
  Future<FinancialOperation?> getOperationById(OperationId id) async => null;

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
  Future<void> update(FinancialOperation operation) async {}

  @override
  Stream<List<FinancialOperation>> watchActiveOperations() =>
      Stream.value(operations);

  @override
  Stream<List<FinancialOperation>> watchPendingOperations() =>
      Stream.value(operations);

  @override
  Stream<FinancialOperation?> watchOperationById(OperationId id) =>
      Stream.value(
        operations.cast<FinancialOperation?>().firstWhere(
          (op) => op?.id == id,
          orElse: () => null,
        ),
      );
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
  group(
    'ASM-005 — SendMoneyFlowScreen (Recipient -> Amount -> Confirmation flow)',
    () {
      late MockFlowOperationRepository repo;
      late MockFlowSyncCoordinator syncCoordinator;

      setUp(() {
        repo = MockFlowOperationRepository();
        syncCoordinator = MockFlowSyncCoordinator();
      });

      Widget buildFlow({
        ConnectivityStatus connectivity = ConnectivityStatus.online,
      }) {
        return ProviderScope(
          overrides: [
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
          ],
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

          // Step 1: Recipient entry
          expect(find.byType(RecipientEntryScreen), findsOneWidget);
          expect(find.byType(AmountEntryScreen), findsNothing);

          // Enter John Doe account
          await tester.enterText(find.byType(TextField), '0123456789');
          await tester.pumpAndSettle();

          // Continue button is enabled, tap it
          expect(
            tester.widget<AppButton>(find.byType(AppButton)).isEnabled,
            isTrue,
          );
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();

          // Step 2: Amount entry
          expect(find.byType(RecipientEntryScreen), findsNothing);
          expect(find.byType(AmountEntryScreen), findsOneWidget);
          expect(find.text('Sending to John Doe'), findsOneWidget);

          // Tap Change / Back to return to recipient
          await tester.tap(find.text('Change'));
          await tester.pumpAndSettle();

          // Back to Step 1
          expect(find.byType(RecipientEntryScreen), findsOneWidget);
          expect(find.byType(AmountEntryScreen), findsNothing);
        },
      );

      testWidgets(
        'full journey: Recipient -> Amount -> Confirmation -> Submit enqueues operation',
        (tester) async {
          await tester.pumpWidget(buildFlow());
          await tester.pumpAndSettle();

          // Step 1: Recipient entry
          await tester.enterText(find.byType(TextField), '0123456789');
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();

          // Step 2: Amount entry
          expect(find.byType(AmountEntryScreen), findsOneWidget);
          await tester.enterText(find.byType(TextField), '10000');
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();

          // Step 3: Confirmation screen
          expect(find.byType(TransferConfirmationScreen), findsOneWidget);
          expect(find.text('Confirm Transfer'), findsOneWidget);
          expect(find.text('John Doe'), findsOneWidget);
          expect(find.text('₦10,000.00'), findsOneWidget);

          // Tap confirm button
          await tester.tap(find.byKey(const Key('confirm_transfer_button')));
          await tester.pumpAndSettle();

          // Enqueued and transitioned to processing view (UI-SND-11 / SND-011)
          expect(repo.operations.length, 1);
          expect(
            find.byKey(const Key('transfer_result_processing_view')),
            findsOneWidget,
          );
          expect(find.text('Sending ₦10,000.00'), findsOneWidget);
        },
      );

      testWidgets(
        'full offline journey: Recipient -> Amount -> Confirmation -> Submit enqueues pending operation and displays pending view (UI-SND-14, UI-SND-15 / SND-014–SND-016)',
        (tester) async {
          await tester.pumpWidget(
            buildFlow(connectivity: ConnectivityStatus.offline),
          );
          await tester.pumpAndSettle();

          // Step 1: Recipient entry while offline
          await tester.enterText(find.byType(TextField), '0123456789');
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(AppButton, 'Continue'));
          await tester.pumpAndSettle();

          // Step 2: Amount entry while offline
          expect(find.byType(AmountEntryScreen), findsOneWidget);
          await tester.enterText(find.byType(TextField), '5000');
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

          // Enqueued in pending status without remote attempt
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
        },
      );
    },
  );
}
