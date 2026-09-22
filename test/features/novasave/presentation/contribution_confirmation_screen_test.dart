import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_confirmation_screen.dart';
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
  }) => throw UnimplementedError();

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
    return op;
  }

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
  Stream<FinancialOperation?> watchOperationById(OperationId id) =>
      Stream.value(null);

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
  group('ContributionConfirmationScreen (T-NSC-002, UI-NSV-11, UI-NSV-16, NSV-011, NSV-012, NSV-016, NSV-017)', () {
    final testGoal = SavingsGoal(
      id: 'goal_vacation_101',
      name: 'Japan trip',
      targetAmount: const Money.fromKobo(10000000), // ₦100,000.00
      savedAmount: const Money.fromKobo(2000000), // ₦20,000.00
      targetDate: DateTime.utc(2027, 6, 1),
    );

    const testAmount = Money.fromKobo(500000); // ₦5,000.00
    const confirmedBalance = Money.fromKobo(5000000); // ₦50,000.00

    late MockOperationRepository mockRepo;
    late MockSyncCoordinator mockSync;

    setUp(() {
      mockRepo = MockOperationRepository();
      mockSync = MockSyncCoordinator();
    });

    Widget buildScreen({
      ConnectivityStatus connectivity = ConnectivityStatus.online,
      VoidCallback? onBack,
      ValueChanged<FinancialOperation>? onContributionSubmitted,
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
            child: ContributionConfirmationScreen(
              goal: testGoal,
              amount: testAmount,
              onBack: onBack ?? () {},
              onContributionSubmitted: onContributionSubmitted ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets(
      'UI-NSV-11: Online confirmation displays headline, details card, and action buttons',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.online),
        );
        await tester.pumpAndSettle();

        // Title
        expect(find.text('Confirm contribution'), findsOneWidget);

        // Headline section
        expect(find.text('You are about to add'), findsOneWidget);
        expect(
          find.text('₦5,000.00'),
          findsNWidgets(2),
        ); // headline & details card row
        expect(find.text('to Japan trip'), findsOneWidget);

        // Details Card
        expect(find.text('Goal'), findsOneWidget);
        expect(find.text('Japan trip'), findsWidgets);
        expect(find.text('Contribution'), findsOneWidget);
        expect(find.text('Current balance'), findsOneWidget);
        expect(find.text('₦20,000.00'), findsOneWidget);
        expect(find.text('Balance after'), findsOneWidget);
        expect(find.text('₦25,000.00'), findsOneWidget);
        expect(find.text('Projected progress'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);

        // Buttons
        expect(
          find.byKey(const Key('confirm_contribution_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('edit_details_button')), findsOneWidget);

        // Offline elements should NOT be present
        expect(
          find.byKey(const Key('confirmation_offline_banner')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('confirmation_offline_notice')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'UI-NSV-16: Offline confirmation displays offline system banner and saved-on-phone notice',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.offline),
        );
        await tester.pumpAndSettle();

        // Offline banner
        expect(
          find.byKey(const Key('confirmation_offline_banner')),
          findsOneWidget,
        );
        expect(find.text("You're offline"), findsOneWidget);

        // Offline notice card
        expect(
          find.byKey(const Key('confirmation_offline_notice')),
          findsOneWidget,
        );
        expect(
          find.text(
            'You are offline. We will save this contribution and add it when you are back online.',
          ),
          findsOneWidget,
        );

        // Confirm button remains enabled for durable offline queuing (NSV-017)
        final button = tester.widget<AppButton>(
          find.byKey(const Key('confirm_contribution_button')),
        );
        expect(button.isEnabled, isTrue);
      },
    );

    testWidgets(
      'tapping Confirm Contribution creates operation, enqueues durably, and calls callback',
      (tester) async {
        FinancialOperation? submittedOp;

        await tester.pumpWidget(
          buildScreen(
            connectivity: ConnectivityStatus.online,
            onContributionSubmitted: (op) => submittedOp = op,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_contribution_button')));
        await tester.pumpAndSettle();

        expect(mockRepo.operations.length, equals(1));
        expect(submittedOp, isNotNull);
        expect(submittedOp!.idempotencyKey.value, startsWith('idem_nsc_'));
        expect(mockSync.syncCount, equals(1));
      },
    );

    testWidgets('tapping Edit details or back button triggers onBack', (
      tester,
    ) async {
      int backCount = 0;

      await tester.pumpWidget(buildScreen(onBack: () => backCount++));
      await tester.pumpAndSettle();

      // Tap back icon
      await tester.tap(find.byKey(const Key('confirmation_back_button')));
      await tester.pumpAndSettle();
      expect(backCount, equals(1));

      // Tap Edit details
      await tester.tap(find.byKey(const Key('edit_details_button')));
      await tester.pumpAndSettle();
      expect(backCount, equals(2));
    });

    testWidgets(
      'HC-ACCESSIBILITY: Renders without layout overflow at 2.0x system text scaling',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(connectivity: ConnectivityStatus.offline, textScale: 2.0),
        );
        await tester.pumpAndSettle();

        // If there's an overflow error, flutter test will fail with FlutterError.
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('confirm_contribution_button')),
          findsOneWidget,
        );
      },
    );
  });
}
