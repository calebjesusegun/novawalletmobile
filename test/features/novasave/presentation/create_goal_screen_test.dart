import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_text_field.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/novasave_repository.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/create_goal_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';

class MockNovaSaveRepository implements NovaSaveRepository {
  final List<SavingsGoal> createdGoals = [];

  @override
  Future<void> createGoal(SavingsGoal goal) async {
    createdGoals.add(goal);
  }

  @override
  Future<List<SavingsGoal>> getGoals() async => createdGoals;

  @override
  Stream<List<SavingsGoal>> watchGoals() => Stream.value(createdGoals);

  @override
  Future<SavingsGoal?> getGoal(String id) async => createdGoals
      .cast<SavingsGoal?>()
      .firstWhere((g) => g?.id == id, orElse: () => null);

  @override
  Future<void> updateGoal(SavingsGoal goal) async {}

  @override
  Future<SavingsGoal> applyContribution(
    String goalId,
    Money contribution,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteGoal(String id) async {}
}

void main() {
  late MockNovaSaveRepository mockRepo;

  setUp(() {
    mockRepo = MockNovaSaveRepository();
  });

  Widget buildTestApp({
    ValueChanged<SavingsGoal>? onGoalCreated,
    double textScaleFactor = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        novaSaveRepositoryProvider.overrideWithValue(mockRepo),
        savingsGoalsStreamProvider.overrideWith(
          (ref) => Stream.value(const []),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          );
        },
        home: CreateGoalScreen(onGoalCreated: onGoalCreated),
      ),
    );
  }

  group('T-NSV-002: CreateGoalScreen Presentation and Validation', () {
    testWidgets('Renders empty form correctly (UI-NSV-04)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Create goal'), findsOneWidget);
      expect(find.text('Goal name'), findsOneWidget);
      expect(find.text('For example, Emergency Fund'), findsOneWidget);
      expect(find.text('Target amount'), findsOneWidget);
      expect(find.text('₦'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('Target date'), findsOneWidget);
      expect(find.text('Select a date'), findsOneWidget);

      final buttonFinder = find.widgetWithText(AppButton, 'Create Goal');
      expect(buttonFinder, findsOneWidget);
      final appButton = tester.widget<AppButton>(buttonFinder);
      expect(appButton.onPressed, isNull);
    });

    testWidgets(
      'Shows validation errors when required inputs are missing or invalid (UI-NSV-05, NSV-004, NSV-005, NSV-006)',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Enter amount "0.00" to enable the button and test validation
        final textFields = find.byType(AppTextField);
        await tester.enterText(textFields.at(1), '0.00');
        await tester.pumpAndSettle();

        // Tap Create Goal
        await tester.tap(find.widgetWithText(AppButton, 'Create Goal'));
        await tester.pumpAndSettle();

        // Validates name (NSV-004)
        expect(find.text('Enter a name for your goal.'), findsOneWidget);

        // Validates target amount > ₦0.00 (NSV-005, HC-MONEY)
        expect(
          find.text('Enter a target amount greater than ₦0.00.'),
          findsOneWidget,
        );

        // Validates future date (NSV-006)
        expect(find.text('Choose a date in the future.'), findsOneWidget);
      },
    );

    testWidgets(
      'Target date picker opens, navigates, and selects future date (UI-NSV-06, NSV-007)',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Tap calendar icon or Target date field
        await tester.tap(find.byTooltip('Open date picker'));
        await tester.pumpAndSettle();

        // Bottom sheet is visible with title
        expect(find.text('Select target date'), findsOneWidget);
        expect(find.text('Confirm date'), findsOneWidget);

        // Navigate to next month to guarantee all dates are in future
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();

        // Tap day 15 in next month
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Tap "Confirm date"
        await tester.tap(find.widgetWithText(AppButton, 'Confirm date'));
        await tester.pumpAndSettle();

        // Bottom sheet dismissed, date text field populated
        expect(find.text('Select target date'), findsNothing);
        expect(find.textContaining('15'), findsOneWidget);
      },
    );

    testWidgets(
      'Valid form persists goal with exact integer-kobo targetAmount and navigates to GoalDetails (UI-NSV-07, HC-MONEY, NSV-003)',
      (tester) async {
        SavingsGoal? createdGoal;
        await tester.pumpWidget(
          buildTestApp(
            onGoalCreated: (goal) {
              createdGoal = goal;
            },
          ),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(AppTextField);

        // 1. Enter goal name
        await tester.enterText(textFields.at(0), 'Emergency Fund');
        await tester.pumpAndSettle();

        // 2. Enter target amount ₦500,000.00
        await tester.enterText(textFields.at(1), '500,000.00');
        await tester.pumpAndSettle();

        // 3. Select future date via picker
        await tester.tap(find.byTooltip('Open date picker'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Confirm date'));
        await tester.pumpAndSettle();

        // 4. Submit form
        await tester.tap(find.widgetWithText(AppButton, 'Create Goal'));
        await tester.pumpAndSettle();

        // Repository called
        expect(mockRepo.createdGoals.length, 1);
        final savedGoal = mockRepo.createdGoals.first;
        expect(savedGoal.name, 'Emergency Fund');
        // HC-MONEY: integer kobo exactness 500,000 * 100 = 50,000,000 kobo
        expect(savedGoal.targetAmount.kobo, 50000000);
        expect(savedGoal.targetAmount, const Money.fromKobo(50000000));
        expect(createdGoal, equals(savedGoal));
      },
    );

    testWidgets(
      'Navigates to GoalDetailsScreen by default on successful submission',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final textFields = find.byType(AppTextField);
        await tester.enterText(textFields.at(0), 'School Fees');
        await tester.enterText(textFields.at(1), '200000');

        await tester.tap(find.byTooltip('Open date picker'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppButton, 'Confirm date'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Create Goal'));
        await tester.pumpAndSettle();

        // Now on GoalDetailsScreen
        expect(find.byType(GoalDetailsScreen), findsOneWidget);
        expect(find.text('School Fees'), findsWidgets);
        expect(find.text('Contribute'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders properly under 2.0x font scaling without layout overflow (HC-ACCESSIBILITY)',
      (tester) async {
        await tester.pumpWidget(buildTestApp(textScaleFactor: 2.0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Create goal'), findsOneWidget);
        expect(find.text('Goal name'), findsOneWidget);
        expect(find.text('Target amount'), findsOneWidget);
        expect(find.text('Target date'), findsOneWidget);
      },
    );

    testWidgets(
      'Target amount formats numbers with thousand commas dynamically',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final textFields = find.byType(AppTextField);
        final amountField = textFields.at(1);

        // Enter raw unformatted digits '13000000'
        await tester.enterText(amountField, '13000000');
        await tester.pumpAndSettle();

        // Must display formatted string with commas
        expect(find.text('13,000,000'), findsOneWidget);

        // Enter decimal digits '13000000.50'
        await tester.enterText(amountField, '13000000.50');
        await tester.pumpAndSettle();

        expect(find.text('13,000,000.50'), findsOneWidget);
      },
    );

    testWidgets(
      'Pressing next on goal name shifts focus to target amount field',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final textFields = find.byType(AppTextField);
        await tester.enterText(textFields.at(0), 'Buy a Car');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        // Target amount field should now have focus
        final targetAmountEditable = find.descendant(
          of: textFields.at(1),
          matching: find.byType(EditableText),
        );
        final editableWidget = tester.widget<EditableText>(
          targetAmountEditable,
        );
        expect(editableWidget.focusNode.hasFocus, isTrue);
      },
    );
  });
}
