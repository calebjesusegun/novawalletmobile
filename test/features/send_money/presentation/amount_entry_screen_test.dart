import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_amount_field.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';

void main() {
  group('T-SND-002 / UI-SND-05–UI-SND-09 — AmountEntryScreen', () {
    const testRecipient = Recipient(
      accountNumber: '0123456789',
      name: 'John Doe',
      bankName: 'NovaBank',
    );

    Widget buildScreen({
      Recipient recipient = testRecipient,
      Money spendableBalance = const Money.fromKobo(5000000), // ₦50,000.00
      Money confirmedBalance = const Money.fromKobo(5000000),
      bool isOffline = false,
      DateTime? lastUpdatedAt,
      VoidCallback? onBack,
      void Function(Money)? onContinue,
      double textScaleFactor = 1.0,
    }) {
      return ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWithValue(
            isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online,
          ),
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(
              WalletProjection(
                confirmedBalance: confirmedBalance,
                spendableBalance: spendableBalance,
                pendingDebitTotal: confirmedBalance - spendableBalance,
                lastUpdatedAt:
                    lastUpdatedAt ?? DateTime.utc(2026, 9, 21, 14, 30),
                activities: const [],
                pendingOperations: const [],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: AmountEntryScreen(
              recipient: recipient,
              onBack: onBack,
              onContinue: onContinue,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'UI-SND-05: Renders empty/zero amount state with available balance and disabled Continue',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Recipient summary chip
        expect(find.text('Sending to John Doe'), findsOneWidget);
        expect(find.text('NovaBank • 0123456789'), findsOneWidget);

        // Prompt and Available balance
        expect(find.text('How much would you like to send?'), findsOneWidget);
        expect(find.text('Available: ₦50,000.00'), findsOneWidget);

        // Amount field
        expect(find.byType(AppAmountField), findsOneWidget);
        expect(find.text('₦'), findsOneWidget);

        // Continue button is disabled
        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-06: Entering valid amount displays balance-after preview and enables Continue',
      (tester) async {
        Money? submittedAmount;

        await tester.pumpWidget(
          buildScreen(onContinue: (amount) => submittedAmount = amount),
        );
        await tester.pumpAndSettle();

        // Enter ₦10,000
        await tester.enterText(find.byType(TextFormField), '10000');
        await tester.pumpAndSettle();

        // Balance-after preview appears
        expect(find.text('Balance after transfer'), findsOneWidget);
        expect(find.text('₦40,000.00'), findsOneWidget);

        // Continue button becomes available
        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isTrue);

        // Tapping Continue submits exact Money amount
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        expect(submittedAmount, isNotNull);
        expect(submittedAmount, equals(Money.fromNaira(10000)));
      },
    );

    testWidgets(
      'UI-SND-07: Entering amount exceeding available balance rejects with error copy',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Enter ₦60,000 (exceeds ₦50,000 spendable)
        await tester.enterText(find.byType(TextFormField), '60000');
        await tester.pumpAndSettle();

        expect(find.text('Amount exceeds available balance.'), findsOneWidget);
        expect(find.text('Balance after transfer'), findsNothing);

        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-08: Entering zero amount rejects with greater-than-zero error copy',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        // Enter 0
        await tester.enterText(find.byType(TextFormField), '0');
        await tester.pumpAndSettle();

        expect(find.text('Amount must be greater than zero.'), findsOneWidget);
        expect(find.text('Balance after transfer'), findsNothing);

        final continueButton = tester.widget<AppButton>(find.byType(AppButton));
        expect(continueButton.isEnabled, isFalse);
      },
    );

    testWidgets(
      'UI-SND-09: Offline amount state shows offline notification and last-updated balance',
      (tester) async {
        final lastUpdate = DateTime.utc(2026, 9, 21, 15, 45);

        await tester.pumpWidget(
          buildScreen(isOffline: true, lastUpdatedAt: lastUpdate),
        );
        await tester.pumpAndSettle();

        // Offline system notification banner
        expect(find.byType(AppSystemNotification), findsOneWidget);
        expect(
          find.textContaining(
            "You're offline. Showing balance from 21/9/2026 at 15:45.",
          ),
          findsOneWidget,
        );

        // Available balance indicator reflects offline context
        expect(find.text('Available: ₦50,000.00 (Offline)'), findsOneWidget);
      },
    );

    testWidgets('Tapping Change button invokes onBack callback', (
      tester,
    ) async {
      var backTapped = false;

      await tester.pumpWidget(buildScreen(onBack: () => backTapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });

    testWidgets(
      'Exposes accessible Semantics on amount field and recipient card',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.textField == true &&
                w.properties.label == 'Enter amount in Naira',
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets('Renders gracefully without overflow at 2.0x font scaling', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen(textScaleFactor: 2.0));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '10000');
      await tester.pumpAndSettle();

      expect(find.text('Balance after transfer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
