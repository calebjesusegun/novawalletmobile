import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/goals_list_screen.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';

void main() {
  final sampleGoal1 = SavingsGoal(
    id: 'goal-emergency',
    name: 'Emergency Fund',
    targetAmount: const Money.fromKobo(50000000), // ₦500,000
    savedAmount: const Money.fromKobo(15000000), // ₦150,000 (30%)
    targetDate: DateTime.utc(2026, 12, 30),
  );

  final sampleGoal2 = SavingsGoal(
    id: 'goal-macbook',
    name: 'New MacBook Pro',
    targetAmount: const Money.fromKobo(200000000), // ₦2,000,000
    savedAmount: const Money.fromKobo(80000000), // ₦800,000 (40%)
    targetDate: DateTime.utc(2027, 6, 15),
  );

  Widget buildSubject({
    required List<SavingsGoal> goals,
    ConnectivityStatus connectivity = ConnectivityStatus.online,
    List<FinancialOperation> activeOperations = const [],
    VoidCallback? onCreateGoal,
    ValueChanged<SavingsGoal>? onGoalTapped,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        savingsGoalsStreamProvider.overrideWith((ref) => Stream.value(goals)),
        connectivityStatusProvider.overrideWithValue(connectivity),
        activeOperationsStreamProvider.overrideWith(
          (ref) => Stream.value(activeOperations),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
            size: const Size(400, 800),
          ),
          child: GoalsListScreen(
            onCreateGoal: onCreateGoal,
            onGoalTapped: onGoalTapped,
          ),
        ),
      ),
    );
  }

  group(
    'T-NSV-001: NovaSave Goal List & Empty State (UI-NSV-01, UI-NSV-03)',
    () {
      testWidgets(
        'UI-NSV-03 / NSV-002: renders empty state when goals list is empty',
        (tester) async {
          var createGoalTapped = false;

          await tester.pumpWidget(
            buildSubject(
              goals: const [],
              onCreateGoal: () => createGoalTapped = true,
            ),
          );
          await tester.pumpAndSettle();

          // Screen title
          expect(find.text('NovaSave'), findsOneWidget);

          // Empty state presentation
          expect(find.byKey(const Key('novasave_empty_state')), findsOneWidget);
          expect(find.text('Start saving toward something'), findsOneWidget);
          expect(find.text('Create your first NovaSave goal.'), findsOneWidget);

          // Create Goal button in empty state
          final emptyStateButton = find.text('Create Goal');
          expect(emptyStateButton, findsOneWidget);

          // Tap empty state button invokes callback
          await tester.tap(emptyStateButton);
          await tester.pump();
          expect(createGoalTapped, isTrue);

          // Bottom navigation bar Create Goal button should not exist on empty state
          expect(find.byKey(const Key('create_goal_button')), findsNothing);
        },
      );

      testWidgets(
        'UI-NSV-01 / NSV-001: renders populated goal list with name, saved/target, %, and target date',
        (tester) async {
          SavingsGoal? tappedGoal;
          var createGoalTapped = false;

          await tester.pumpWidget(
            buildSubject(
              goals: [sampleGoal1, sampleGoal2],
              onCreateGoal: () => createGoalTapped = true,
              onGoalTapped: (goal) => tappedGoal = goal,
            ),
          );
          await tester.pumpAndSettle();

          // Header & Section Title
          expect(find.text('NovaSave'), findsOneWidget);
          expect(find.text('Your savings goals'), findsOneWidget);

          // Both cards rendered
          expect(
            find.byKey(const Key('goal_card_goal-emergency')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('goal_card_goal-macbook')),
            findsOneWidget,
          );

          // Goal 1 content
          expect(find.text('Emergency Fund'), findsOneWidget);
          expect(find.text('30%'), findsOneWidget);
          expect(find.text('₦150,000 of ₦500,000'), findsOneWidget);
          expect(find.text('Target: 30 Dec 2026'), findsOneWidget);

          // Goal 2 content
          expect(find.text('New MacBook Pro'), findsOneWidget);
          expect(find.text('40%'), findsOneWidget);
          expect(find.text('₦800,000 of ₦2,000,000'), findsOneWidget);
          expect(find.text('Target: 15 Jun 2027'), findsOneWidget);

          // Bottom sticky Create Goal button
          final createGoalButton = find.byKey(const Key('create_goal_button'));
          expect(createGoalButton, findsOneWidget);

          // Tap bottom button invokes onCreateGoal
          await tester.tap(createGoalButton);
          await tester.pump();
          expect(createGoalTapped, isTrue);

          // Tap goal card invokes onGoalTapped with that goal
          await tester.tap(find.byKey(const Key('goal_card_goal-emergency')));
          await tester.pump();
          expect(tappedGoal, equals(sampleGoal1));
        },
      );

      testWidgets(
        'UI-NSV-02: renders offline system notification and pending contribution note on goal card',
        (tester) async {
          final pendingContributionOp = FinancialOperation.contribution(
            id: OperationId('op-contrib-1'),
            idempotencyKey: IdempotencyKey('idem-contrib-1'),
            payload: ContributionPayload(
              goalId: 'goal-emergency',
              goalName: 'Emergency Fund',
              amount: const Money.fromKobo(5000000), // ₦50,000.00
            ),
            createdAt: DateTime.utc(2026, 9, 22),
          );

          await tester.pumpWidget(
            buildSubject(
              goals: [sampleGoal1],
              connectivity: ConnectivityStatus.offline,
              activeOperations: [pendingContributionOp],
            ),
          );
          await tester.pumpAndSettle();

          // Offline system banner visible
          expect(find.byType(AppSystemNotification), findsOneWidget);
          expect(
            find.text(
              "You're offline. Requests are queued securely and will process when you're back online.",
            ),
            findsOneWidget,
          );

          // Goal card confirmed figures remain unchanged (HC-STATE-SEPARATION)
          expect(find.text('Emergency Fund'), findsOneWidget);
          expect(find.text('30%'), findsOneWidget);
          expect(find.text('₦150,000 of ₦500,000'), findsOneWidget);

          // Pending contribution badge visible on the goal card
          expect(
            find.text('₦50,000.00 pending. Will add when you are online.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Dynamic stream updates reactively transition screen from empty to populated',
        (tester) async {
          final streamController = StreamController<List<SavingsGoal>>();
          addTearDown(streamController.close);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                savingsGoalsStreamProvider.overrideWith(
                  (ref) => streamController.stream,
                ),
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.online,
                ),
                activeOperationsStreamProvider.overrideWith(
                  (ref) => Stream.value(const []),
                ),
              ],
              child: const MaterialApp(home: GoalsListScreen()),
            ),
          );

          // Initial loading
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Emit empty list
          streamController.add(const []);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('novasave_empty_state')), findsOneWidget);
          expect(find.byKey(const Key('goals_list_view')), findsNothing);

          // Emit populated list
          streamController.add([sampleGoal1]);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('novasave_empty_state')), findsNothing);
          expect(find.byKey(const Key('goals_list_view')), findsOneWidget);
          expect(find.text('Emergency Fund'), findsOneWidget);
        },
      );

      testWidgets(
        'A11Y-001 / A11Y-002: GoalCard provides complete Semantics and 2.0x text scaling without overflow',
        (tester) async {
          await tester.pumpWidget(
            buildSubject(
              goals: [sampleGoal1],
              textScaleFactor: 2.0,
              onGoalTapped: (_) {},
            ),
          );
          await tester.pumpAndSettle();

          // No Flutter layout overflow exceptions occurred under 2.0x scale
          expect(tester.takeException(), isNull);

          // Verify Semantics
          final semanticsFinder = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label != null &&
                widget.properties.label!.contains('Emergency Fund') &&
                widget.properties.label!.contains('30% saved') &&
                widget.properties.label!.contains('₦150,000 of ₦500,000'),
          );
          expect(semanticsFinder, findsOneWidget);
        },
      );
    },
  );
}
