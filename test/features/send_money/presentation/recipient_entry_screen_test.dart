import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_text_field.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/send_money/data/fake_recipient_directory.dart';
import 'package:novawallet/features/send_money/data/send_money_providers.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/widgets/resolved_recipient_card.dart';

void main() {
  group('T-SND-001 / UI-SND-01–UI-SND-04 — RecipientEntryScreen', () {
    Widget buildScreen({
      void Function(Recipient)? onContinue,
      FakeRecipientDirectory? directory,
      double textScaleFactor = 1.0,
    }) {
      return ProviderScope(
        overrides: [
          if (directory != null)
            recipientDirectoryProvider.overrideWithValue(directory),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: RecipientEntryScreen(onContinue: onContinue),
          ),
        ),
      );
    }

    testWidgets(
      'UI-SND-01: Renders empty recipient entry screen with disabled Continue button',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Verify title and prompts
        expect(find.text('Send Money'), findsOneWidget);
        expect(find.text('Who are you sending to?'), findsOneWidget);
        expect(
          find.text('Transfer funds securely even while offline.'),
          findsOneWidget,
        );

        // Verify text field exists and is empty
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.text('Enter 10-digit account number'), findsOneWidget);

        // Verify Continue button is disabled
        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-02: Shows required error "Enter who you are sending to."',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Enter some text then clear it out
        await tester.enterText(find.byType(TextField), '012');
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        // Or submit empty via keyboard
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('Enter who you are sending to.'), findsOneWidget);

        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-03: Shows invalid-account helper / error for non-existent account',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Enter a 10-digit account not in the directory
        await tester.enterText(find.byType(TextField), '9999999999');
        await tester.pumpAndSettle();

        expect(
          find.text('Recipient not found. Enter a valid account number.'),
          findsOneWidget,
        );

        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-03: Shows length error for short account on submission',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '12345');
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(
          find.text('Enter a valid 10-digit account number.'),
          findsOneWidget,
        );

        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-04: Resolves 0123456789 to John Doe and enables Continue',
      (tester) async {
        Recipient? selectedRecipient;

        await tester.pumpWidget(
          buildScreen(onContinue: (r) => selectedRecipient = r),
        );
        await tester.pumpAndSettle();

        // Enter the approved design fixture account
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();

        // Resolved recipient card must appear
        expect(find.byType(ResolvedRecipientCard), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('NovaBank • 0123456789'), findsOneWidget);

        // Continue button must become available (enabled)
        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isTrue);

        // Tapping Continue triggers callback with resolved recipient
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        expect(selectedRecipient, isNotNull);
        expect(selectedRecipient!.name, equals('John Doe'));
        expect(selectedRecipient!.accountNumber, equals('0123456789'));
      },
    );

    testWidgets(
      'Tapping clear on ResolvedRecipientCard resets state and disables Continue',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();

        expect(find.byType(ResolvedRecipientCard), findsOneWidget);
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).isEnabled,
          isTrue,
        );

        // Tap clear button on resolved recipient card
        await tester.tap(find.byTooltip('Change recipient'));
        await tester.pumpAndSettle();

        // Card is dismissed and Continue is disabled again
        expect(find.byType(ResolvedRecipientCard), findsNothing);
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).isEnabled,
          isFalse,
        );
      },
    );

    testWidgets('Exposes accessible Semantics for screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Semantics for input field
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.textField == true &&
              w.properties.label == 'Recipient account number',
        ),
        findsOneWidget,
      );

      // Resolve recipient
      await tester.enterText(find.byType(TextField), '0123456789');
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Resolved recipient.*John Doe')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('Renders gracefully without overflow at 2.0x font scaling', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(textScaleFactor: 2.0));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0123456789');
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
