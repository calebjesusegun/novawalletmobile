import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/fields/app_amount_field.dart';
import 'package:novawallet/design_system/components/fields/app_text_field.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/widgets/goal_card.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_balance_card.dart';

void main() {
  group('T-A11Y-001 / ASM-015 / A11Y-001 — Semantics Accessibility Verification', () {
    testWidgets('AppButton provides accessible button semantics and state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(label: 'Send Money', onPressed: () {}),
                const AppButton(label: 'Disabled Button', onPressed: null),
              ],
            ),
          ),
        ),
      );

      // Verify button 1 has semantic label and button flag
      expect(
        tester.getSemantics(find.text('Send Money')),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Send Money',
        ),
      );

      // Verify disabled button semantics
      expect(
        tester.getSemantics(find.text('Disabled Button')),
        matchesSemantics(
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          label: 'Disabled Button',
        ),
      );

      handle.dispose();
    });

    testWidgets(
      'AppTextField and AppAmountField provide accessible text field semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppTextField(
                    label: 'Account Number',
                    semanticLabel: 'Enter 10-digit NUBAN account number',
                  ),
                  AppAmountField(
                    semanticLabel: 'Enter transfer amount in Naira',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Enter 10-digit NUBAN account number'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Enter transfer amount in Naira'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'AppStatusBadge and AppResultIndicator expose non-color accessible status semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppStatusBadge(status: AppOperationStatus.pending),
                  AppStatusBadge(status: AppOperationStatus.processing),
                  AppStatusBadge(status: AppOperationStatus.completed),
                  AppStatusBadge(status: AppOperationStatus.failed),
                  AppResultIndicator(status: AppOperationStatus.completed),
                  AppResultIndicator(status: AppOperationStatus.pending),
                  AppResultIndicator(status: AppOperationStatus.failed),
                ],
              ),
            ),
          ),
        );

        // Verify that status meanings are readable via semantics (A11Y-002, ASM-016)
        expect(find.bySemanticsLabel('Status: Pending'), findsOneWidget);
        expect(find.bySemanticsLabel('Status: Processing'), findsOneWidget);
        expect(find.bySemanticsLabel('Status: Completed'), findsOneWidget);
        expect(find.bySemanticsLabel('Status: Failed'), findsOneWidget);

        expect(
          find.bySemanticsLabel('Operation completed successfully'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Operation pending synchronization'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Operation failed'), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'AppSystemNotification exposes accessible container semantics with announcement text',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppSystemNotification.offline(),
                  AppSystemNotification.backOnline(),
                  AppSystemNotification.syncFailure(),
                ],
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(
            "You're offline. Requests are queued securely and will process when you're back online.",
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Back online. Syncing pending actions...'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'WalletBalanceCard exposes accessible balance and last-updated semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WalletBalanceCard(
                balance: const Money.fromKobo(5000000), // ₦50,000.00
                lastUpdatedAt: DateTime.utc(2026, 9, 22, 10, 0),
                isOffline: true,
                onSendMoneyTap: () {},
                onNovaSaveTap: () {},
              ),
            ),
          ),
        );

        // Verify balance card has semantic label containing formatted Naira balance and update time
        expect(
          find.bySemanticsLabel(
            RegExp(
              r'Available balance: ₦50,000\.00.*Last updated at',
              caseSensitive: false,
            ),
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'WalletActivityTile exposes complete transaction details in semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        final item = WalletActivityItem(
          id: 'tx_test_1',
          title: 'Musa Bello',
          subtitle: 'Transfer',
          type: TransactionType.debit,
          amount: const Money.fromKobo(250000), // ₦2,500.00
          timestamp: DateTime.utc(2026, 9, 22, 10, 0),
          status: TransactionStatus.completed,
          operationId: OperationId('op_1'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: WalletActivityTile(item: item)),
          ),
        );

        expect(
          find.bySemanticsLabel(
            RegExp(r'Musa Bello.*-₦2,500\.00.*completed', caseSensitive: false),
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );

    testWidgets(
      'GoalCard exposes goal name, saved amount, target, and percentage in semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        final goal = SavingsGoal(
          id: 'goal_test_1',
          name: 'New Laptop',
          targetAmount: const Money.fromKobo(50000000), // ₦500,000.00
          savedAmount: const Money.fromKobo(25000000), // ₦250,000.00 (50%)
          targetDate: DateTime.utc(2026, 12, 31),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GoalCard(goal: goal)),
          ),
        );

        expect(
          find.bySemanticsLabel(
            RegExp(
              r'New Laptop.*50% saved\..*₦250,000 of ₦500,000',
              caseSensitive: false,
            ),
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );
  });
}
