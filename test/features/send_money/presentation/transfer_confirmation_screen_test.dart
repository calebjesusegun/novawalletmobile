import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
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

class MockOperationRepository implements OperationRepository {
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
}

class MockSyncCoordinator implements SyncCoordinator {
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
  group('TransferConfirmationScreen (T-SND-003, UI-SND-10, UI-SND-14, SND-009, SND-014)', () {
    const testRecipient = Recipient(
      accountNumber: '0123456789',
      name: 'John Doe',
      bankName: 'NovaBank',
    );
    final testAmount = Money.fromNaira(10000); // ₦10,000.00
    const confirmedBalance = Money.fromKobo(12545000); // ₦125,450.00

    late MockOperationRepository mockRepo;
    late MockSyncCoordinator mockSync;

    setUp(() {
      mockRepo = MockOperationRepository();
      mockSync = MockSyncCoordinator();
    });

    Widget buildScreen({
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      VoidCallback? onBack,
      ValueChanged<FinancialOperation>? onTransferSubmitted,
      double textScale = 1.0,
    }) {
      return ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWithValue(connectivity),
          operationRepositoryProvider.overrideWithValue(mockRepo),
          syncCoordinatorProvider.overrideWithValue(mockSync),
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(
              WalletProjection(
                confirmedBalance: confirmedBalance,
                spendableBalance: confirmedBalance,
                pendingDebitTotal: const Money.zero(),
                lastUpdatedAt: DateTime.utc(2026, 3, 30),
                activities: const [],
                pendingOperations: const [],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: TransferConfirmationScreen(
              recipient: testRecipient,
              amount: testAmount,
              onBack: onBack ?? () {},
              onTransferSubmitted: onTransferSubmitted ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets(
      'UI-SND-10: Online confirmation displays all required detail rows and button',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.online),
        );
        await tester.pumpAndSettle();

        // App bar
        expect(find.text('Confirm Transfer'), findsOneWidget);

        // Detail rows
        expect(find.text('Recipient'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);

        expect(find.text('Account'), findsOneWidget);
        expect(find.text('0123456789 • NovaBank'), findsOneWidget);

        expect(find.text('Amount'), findsOneWidget);
        expect(find.text('₦10,000.00'), findsOneWidget);

        expect(find.text('Source'), findsOneWidget);
        expect(find.text('Main Wallet'), findsOneWidget);

        expect(find.text('Balance after transfer'), findsOneWidget);
        expect(find.text('₦115,450.00'), findsOneWidget);

        // Confirm button
        expect(find.text('Send ₦10,000.00'), findsOneWidget);

        // Offline banner is NOT present
        expect(
          find.byKey(const Key('confirmation_offline_banner')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'UI-SND-14: Offline confirmation shows offline banner and Save & Send Later button',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.offline),
        );
        await tester.pumpAndSettle();

        // Offline explanation banner (SND-014)
        expect(
          find.byKey(const Key('confirmation_offline_banner')),
          findsOneWidget,
        );
        expect(
          find.text(
            "You're offline. Transfer will be saved securely and sent when connected.",
          ),
          findsOneWidget,
        );

        // Confirm button reflects offline action
        expect(find.text('Save & Send Later'), findsOneWidget);
      },
    );

    testWidgets('Back button invokes onBack callback', (tester) async {
      var backCalled = false;
      await tester.pumpWidget(buildScreen(onBack: () => backCalled = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmation_back_button')));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });

    testWidgets(
      'Tapping confirm button durably enqueues operation and calls onTransferSubmitted',
      (tester) async {
        FinancialOperation? submittedOp;
        await tester.pumpWidget(
          buildScreen(
            connectivity: ConnectivityStatus.online,
            onTransferSubmitted: (op) => submittedOp = op,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_transfer_button')));
        await tester.pumpAndSettle();

        expect(submittedOp, isNotNull);
        expect(mockRepo.operations.length, 1);
        expect(submittedOp!.id, mockRepo.operations.first.id);
        expect(
          submittedOp!.idempotencyKey.value.startsWith('idem_send_'),
          isTrue,
        );
      },
    );

    testWidgets(
      'Accessibility semantics: confirmation card and action button have meaningful labels',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Transfer confirmation details',
          ),
          findsOneWidget,
        );

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.label == 'Confirm and send transfer',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'A11Y-002: Responsive 2.0x text scaling renders without overflow',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.offline, textScale: 2.0),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Confirm Transfer'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Save & Send Later'), findsOneWidget);
      },
    );
  });
}
