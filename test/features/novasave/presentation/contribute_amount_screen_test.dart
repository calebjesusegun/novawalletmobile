import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_amount_field.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribute_amount_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';

void main() {
  final sampleGoal = SavingsGoal(
    id: 'goal-emergency-fund',
    name: 'Emergency Fund',
    targetAmount: Money.fromNaira(500000),
    savedAmount: Money.fromNaira(150000),
    targetDate: DateTime(2026, 12, 30),
  );

  Widget buildTestApp({
    SavingsGoal? goal,
    Money spendableBalance = const Money.fromKobo(12545000), // ₦125,450.00
    VoidCallback? onBack,
    void Function(Money)? onContinue,
    double textScaleFactor = 1.0,
  }) {
    final effectiveGoal = goal ?? sampleGoal;
    final projection = WalletProjection(
      confirmedBalance: spendableBalance,
      spendableBalance: spendableBalance,
      pendingDebitTotal: const Money.zero(),
      lastUpdatedAt: DateTime.utc(2026, 9, 21),
      activities: const [],
      pendingOperations: const [],
    );

    return ProviderScope(
      overrides: [
        walletProjectionProvider.overrideWithValue(AsyncValue.data(projection)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
            size: const Size(390, 844),
          ),
          child: ContributeAmountScreen(
            goal: effectiveGoal,
            onBack: onBack,
            onContinue: onContinue,
          ),
        ),
      ),
    );
  }

  group('ContributeAmountScreen Widget Tests (UI-NSV-09, UI-NSV-10, NSV-009, NSV-010)', () {
    testWidgets(
      'renders initial amount entry screen matching UI-NSV-09 baseline',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Header Card
        expect(find.text('Contribute'), findsOneWidget);
        expect(find.text('Contributing to'), findsOneWidget);
        expect(find.text('Emergency Fund'), findsOneWidget);
        expect(find.text('Saved ₦150,000 of ₦500,000'), findsOneWidget);

        // Field
        expect(find.text('Amount to add'), findsOneWidget);
        expect(find.byType(AppAmountField), findsOneWidget);
        expect(find.text('Wallet balance ₦125,450.00'), findsOneWidget);

        // Projected progress card is NOT displayed when amount is 0
        expect(find.byKey(const Key('projected_progress_card')), findsNothing);

        // Continue button disabled initially
        final continueButton = tester.widget<AppButton>(
          find.byKey(const Key('contribute_continue_button')),
        );
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'entering valid ₦50,000 displays live projected progress (40%) and enables Continue (UI-NSV-09 / MNY-003)',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final field = find.byType(TextField);
        await tester.enterText(field, '50000');
        await tester.pumpAndSettle();

        // Projected Progress Card is displayed
        expect(
          find.byKey(const Key('projected_progress_card')),
          findsOneWidget,
        );
        expect(find.text('₦200,000 of ₦500,000'), findsOneWidget);
        expect(find.text('40%'), findsOneWidget);

        final progressBar = tester.widget<AppProgressBar>(
          find.descendant(
            of: find.byKey(const Key('projected_progress_card')),
            matching: find.byType(AppProgressBar),
          ),
        );
        expect(progressBar.progress, closeTo(0.40, 0.0001));

        // Continue button is enabled
        final continueButton = tester.widget<AppButton>(
          find.byKey(const Key('contribute_continue_button')),
        );
        expect(continueButton.isEnabled, isTrue);
      },
    );

    testWidgets(
      'entering amount exceeding wallet balance shows exact error and disables Continue (UI-NSV-10 / NSV-010)',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final field = find.byType(TextField);
        await tester.enterText(field, '200000'); // ₦200,000 > ₦125,450.00
        await tester.pumpAndSettle();

        // Exact error message
        expect(
          find.text(
            'Amount is more than your wallet balance. Enter ₦125,450.00 or less.',
          ),
          findsOneWidget,
        );

        // Projected progress card is NOT displayed when invalid
        expect(find.byKey(const Key('projected_progress_card')), findsNothing);

        // Continue button disabled
        final continueButton = tester.widget<AppButton>(
          find.byKey(const Key('contribute_continue_button')),
        );
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'tapping Continue invokes onContinue callback with parsed Money amount',
      (tester) async {
        Money? submittedAmount;
        await tester.pumpWidget(
          buildTestApp(onContinue: (amt) => submittedAmount = amt),
        );
        await tester.pumpAndSettle();

        final field = find.byType(TextField);
        await tester.enterText(field, '50000');
        await tester.pumpAndSettle();

        final continueButton = find.byKey(
          const Key('contribute_continue_button'),
        );
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(submittedAmount, equals(Money.fromNaira(50000)));
        expect(submittedAmount?.kobo, equals(5000000));
      },
    );

    testWidgets('tapping back button invokes onBack callback', (tester) async {
      var backTapped = false;
      await tester.pumpWidget(buildTestApp(onBack: () => backTapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });

    testWidgets(
      'supports 2.0x font scaling without layout overflow (HC-ACCESSIBILITY)',
      (tester) async {
        await tester.pumpWidget(buildTestApp(textScaleFactor: 2.0));
        await tester.pumpAndSettle();

        final field = find.byType(TextField);
        await tester.enterText(field, '50000');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Emergency Fund'), findsOneWidget);
        expect(find.text('₦200,000 of ₦500,000'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );
  });
}
