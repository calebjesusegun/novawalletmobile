import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribute_amount_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_confirmation_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_result_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/create_goal_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/goals_list_screen.dart';
import 'package:novawallet/features/send_money/data/fake_recipient_directory.dart';
import 'package:novawallet/features/send_money/data/send_money_providers.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_confirmation_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_result_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  const testViewportSize = Size(390 * 3, 844 * 3);
  const testDevicePixelRatio = 3.0;

  const testRecipient = Recipient(
    accountNumber: '0123456789',
    name: 'Musa Bello',
    bankName: 'NovaBank',
  );

  final testGoal = SavingsGoal(
    id: 'goal_laptop_1',
    name: 'New MacBook Pro',
    targetAmount: const Money.fromKobo(150000000), // ₦1,500,000.00
    savedAmount: const Money.fromKobo(75000000), // ₦750,000.00 (50%)
    targetDate: DateTime.utc(2026, 12, 31),
  );

  final testProjection = WalletProjection(
    confirmedBalance: const Money.fromKobo(5000000), // ₦50,000.00
    spendableBalance: const Money.fromKobo(4500000), // ₦45,000.00
    pendingDebitTotal: const Money.fromKobo(500000), // ₦5,000.00
    lastUpdatedAt: DateTime.utc(2026, 9, 22, 10, 0),
    activities: [
      WalletActivityItem(
        id: 'tx_1',
        title: 'Musa Bello',
        subtitle: 'Transfer',
        type: TransactionType.debit,
        amount: const Money.fromKobo(250000),
        timestamp: DateTime.utc(2026, 9, 22, 9, 30),
        status: TransactionStatus.completed,
        operationId: OperationId('op_tx_1'),
      ),
    ],
    pendingOperations: const [],
  );

  final testTransferOp = FinancialOperation.restore(
    id: OperationId('op_test_1'),
    type: OperationType.send,
    idempotencyKey: IdempotencyKey('idem_test_1'),
    payload: SendMoneyPayload(
      recipientAccountNumber: testRecipient.accountNumber,
      recipientName: testRecipient.name,
      bankName: testRecipient.bankName,
      amount: const Money.fromKobo(500000), // ₦5,000.00
    ),
    attemptCount: 1,
    createdAt: DateTime.utc(2026, 9, 22, 10, 0),
    status: OperationStatus.pending,
  );

  final testContributionOp = FinancialOperation.restore(
    id: OperationId('op_test_2'),
    type: OperationType.contribution,
    idempotencyKey: IdempotencyKey('idem_test_2'),
    payload: ContributionPayload(
      goalId: testGoal.id,
      goalName: testGoal.name,
      amount: const Money.fromKobo(1000000), // ₦10,000.00
    ),
    attemptCount: 1,
    createdAt: DateTime.utc(2026, 9, 22, 10, 0),
    status: OperationStatus.pending,
  );

  group('T-A11Y-001 / A11Y-003 — 2.0x Font Scaling Verification', () {
    Widget buildScaledTestScreen({
      required Widget screen,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWithValue(
            ConnectivityStatus.online,
          ),
          syncStatusProvider.overrideWithValue(SyncStatus.idle),
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(testProjection),
          ),
          recipientDirectoryProvider.overrideWithValue(
            const FakeRecipientDirectory(),
          ),
          savingsGoalsStreamProvider.overrideWith(
            (ref) => Stream.value([testGoal]),
          ),
          pendingOperationsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: screen,
          ),
        ),
      );
    }

    void setupViewport(WidgetTester tester) {
      tester.view.physicalSize = testViewportSize;
      tester.view.devicePixelRatio = testDevicePixelRatio;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets(
      '1. WalletHomeScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(screen: const WalletHomeScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WalletHomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. RecipientEntryScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(screen: const RecipientEntryScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RecipientEntryScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. AmountEntryScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: const AmountEntryScreen(recipient: testRecipient),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AmountEntryScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. TransferConfirmationScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: TransferConfirmationScreen(
              recipient: testRecipient,
              amount: const Money.fromKobo(250000),
              onBack: () {},
              onTransferSubmitted: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TransferConfirmationScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. TransferResultScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: TransferResultScreen(
              operation: testTransferOp,
              onDone: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TransferResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '6. GoalsListScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(screen: const GoalsListScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GoalsListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. CreateGoalScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(screen: const CreateGoalScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CreateGoalScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. GoalDetailsScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: GoalDetailsScreen(
              goalId: testGoal.id,
              initialGoal: testGoal,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GoalDetailsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '9. ContributeAmountScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(screen: ContributeAmountScreen(goal: testGoal)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContributeAmountScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '10. ContributionConfirmationScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: ContributionConfirmationScreen(
              goal: testGoal,
              amount: const Money.fromKobo(1000000),
              onBack: () {},
              onContributionSubmitted: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContributionConfirmationScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '11. ContributionResultScreen renders without overflow at 2.0x text scaling',
      (tester) async {
        setupViewport(tester);
        await tester.pumpWidget(
          buildScaledTestScreen(
            screen: ContributionResultScreen(
              operation: testContributionOp,
              goal: testGoal,
              onDone: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ContributionResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
