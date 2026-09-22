import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/send_money_flow_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';

void main() {
  group('ASM-005 — SendMoneyFlowScreen (Recipient -> Amount transition)', () {
    Widget buildFlow() {
      return ProviderScope(
        overrides: [
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
  });
}
