import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  final sampleGoal = SavingsGoal(
    id: 'goal-emergency-fund',
    name: 'Emergency Fund',
    targetAmount: Money.fromNaira(500000),
    savedAmount: Money.fromNaira(150000),
    targetDate: DateTime(2026, 12, 30),
  );

  Widget buildTestApp({
    SavingsGoal? initialGoal,
    String? goalId,
    List<SavingsGoal>? goalsList,
    ConnectivityStatus connectivity = ConnectivityStatus.online,
    List<FinancialOperation> activeOperations = const [],
    VoidCallback? onContribute,
    double textScaleFactor = 1.0,
  }) {
    final effectiveGoalId = goalId ?? initialGoal?.id ?? 'goal-emergency-fund';

    return ProviderScope(
      overrides: [
        connectivityStatusProvider.overrideWithValue(connectivity),
        savingsGoalsStreamProvider.overrideWith(
          (ref) => Stream.value(goalsList ?? [sampleGoal]),
        ),
        activeOperationsStreamProvider.overrideWith(
          (ref) => Stream.value(activeOperations),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
            size: const Size(390, 844),
          ),
          child: GoalDetailsScreen(
            goalId: effectiveGoalId,
            initialGoal: initialGoal,
            onContribute: onContribute,
          ),
        ),
      ),
    );
  }

  group('GoalDetailsScreen Presentation & Progress (T-NSV-003 / UI-NSV-08)', () {
    testWidgets(
      'displays all goal details matching UI-NSV-08: saved, target, percentage, still to save, date',
      (tester) async {
        await tester.pumpWidget(buildTestApp(initialGoal: sampleGoal));
        await tester.pumpAndSettle();

        // Screen title / Goal name in AppBar
        expect(find.text('Emergency Fund'), findsOneWidget);

        // Progress Card
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('of ₦500,000.00 target'), findsOneWidget);
        expect(find.text('30% complete'), findsOneWidget);
        expect(find.text('Target: 30 Dec 2026'), findsOneWidget);

        // Progress bar value
        final progressBar = tester.widget<AppProgressBar>(
          find.byType(AppProgressBar),
        );
        expect(progressBar.progress, closeTo(0.30, 0.0001));

        // Details Card key-value pairs
        expect(find.text('Target'), findsOneWidget);
        expect(find.text('Still to save'), findsOneWidget);
        expect(find.text('₦350,000.00'), findsOneWidget);
        expect(find.text('Target date'), findsOneWidget);
        expect(find.text('30 Dec 2026'), findsOneWidget);

        // Contribute button
        expect(find.text('Contribute'), findsOneWidget);
      },
    );

    testWidgets(
      'invokes onContribute callback when Contribute button is tapped',
      (tester) async {
        var contributeTapped = false;
        await tester.pumpWidget(
          buildTestApp(
            initialGoal: sampleGoal,
            onContribute: () => contributeTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        final contributeButton = find.byKey(
          const Key('goal_details_contribute_button'),
        );
        expect(contributeButton, findsOneWidget);

        await tester.tap(contributeButton);
        await tester.pumpAndSettle();

        expect(contributeTapped, isTrue);
      },
    );

    testWidgets(
      'displays offline system notification when offline (UI-NSV-18)',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            initialGoal: sampleGoal,
            connectivity: ConnectivityStatus.offline,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("You're offline"), findsOneWidget);
        expect(
          find.text(
            "Some actions will be saved and processed when you're back online.",
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays pending contribution banner and keeps confirmed numbers unchanged (UI-NSV-18 / HC-MONEY)',
      (tester) async {
        final pendingOp = FinancialOperation.contribution(
          id: OperationId('op-contrib-1'),
          idempotencyKey: IdempotencyKey('idem-contrib-1'),
          payload: ContributionPayload(
            goalId: sampleGoal.id,
            goalName: sampleGoal.name,
            amount: Money.fromNaira(50000),
          ),
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestApp(initialGoal: sampleGoal, activeOperations: [pendingOp]),
        );
        await tester.pumpAndSettle();

        // Pending banner is displayed
        expect(find.text('Pending'), findsOneWidget);
        expect(
          find.text('₦50,000.00 pending. Will contribute when back online.'),
          findsOneWidget,
        );

        // Confirmed progress remains unchanged (HC-MONEY, design rule)
        expect(find.text('Saved so far'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('30% complete'), findsOneWidget);
        expect(find.text('₦350,000.00'), findsOneWidget); // Still to save
      },
    );

    testWidgets(
      'displays 100% complete and ₦0.00 still to save for completed goal',
      (tester) async {
        final completedGoal = SavingsGoal(
          id: 'goal-completed',
          name: 'School Fees',
          targetAmount: Money.fromNaira(200000),
          savedAmount: Money.fromNaira(200000),
          targetDate: DateTime(2027, 1, 15),
        );

        await tester.pumpWidget(buildTestApp(initialGoal: completedGoal));
        await tester.pumpAndSettle();

        expect(find.text('100% complete'), findsOneWidget);
        expect(find.text('Still to save'), findsOneWidget);
        expect(find.text('₦0.00'), findsOneWidget);

        final progressBar = tester.widget<AppProgressBar>(
          find.byType(AppProgressBar),
        );
        expect(progressBar.progress, 1.0);
      },
    );

    testWidgets(
      'displays Goal not found when goal does not exist in repository',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(goalId: 'non-existent-id', goalsList: []),
        );
        await tester.pumpAndSettle();

        expect(find.text('Goal not found'), findsOneWidget);
      },
    );

    testWidgets(
      'supports 2.0x text scaling without layout overflow (HC-ACCESSIBILITY)',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(initialGoal: sampleGoal, textScaleFactor: 2.0),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Emergency Fund'), findsOneWidget);
        expect(find.text('₦150,000.00'), findsOneWidget);
        expect(find.text('Contribute'), findsOneWidget);
      },
    );

    testWidgets('navigates back when back button in AppBar is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProviderScope(
                        overrides: [
                          savingsGoalsStreamProvider.overrideWith(
                            (ref) => Stream.value([sampleGoal]),
                          ),
                          activeOperationsStreamProvider.overrideWith(
                            (ref) => Stream.value([]),
                          ),
                          connectivityStatusProvider.overrideWithValue(
                            ConnectivityStatus.online,
                          ),
                        ],
                        child: GoalDetailsScreen(
                          goalId: sampleGoal.id,
                          initialGoal: sampleGoal,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Details'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Details'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Fund'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Verified popped
      expect(find.text('Open Details'), findsOneWidget);
      expect(find.text('Emergency Fund'), findsNothing);
    });
  });
}
