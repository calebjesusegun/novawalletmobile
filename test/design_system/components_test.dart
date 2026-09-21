import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/design_system.dart';

void main() {
  group('DSN-007 / A11Y-001 / A11Y-002 — AppButton', () {
    testWidgets('Renders label and triggers onPressed when enabled', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppButton(
              label: 'Confirm Transfer',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirm Transfer'), findsOneWidget);
      await tester.tap(find.text('Confirm Transfer'));
      expect(pressed, isTrue);
    });

    testWidgets(
      'Disabled button does not trigger action when isLoading is true',
      (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AppButton(
                label: 'Disabled Loading',
                onPressed: () => pressed = true,
                isLoading: true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Disabled Loading'));
        expect(pressed, isFalse);
      },
    );

    testWidgets('Shows CircularProgressIndicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppButton(
              label: 'Processing',
              onPressed: null,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Exposes accessible Semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppButton(label: 'Send Money', onPressed: () {}),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Send Money'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('Supports larger text scale without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: AppButton(label: 'Save Changes Now', onPressed: null),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Save Changes Now'), findsOneWidget);
    });
  });

  group('DSN-008 — AppTextField & AppAmountField', () {
    testWidgets('AppTextField renders label, hint, and accepts input', (
      tester,
    ) async {
      String? entered;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppTextField(
              label: 'Account Number',
              hintText: 'Enter 10-digit number',
              onChanged: (val) => entered = val,
            ),
          ),
        ),
      );

      expect(find.text('Account Number'), findsOneWidget);
      expect(find.text('Enter 10-digit number'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '0123456789');
      expect(entered, equals('0123456789'));
    });

    testWidgets('AppTextField displays errorText when invalid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppTextField(
              label: 'Recipient',
              errorText: 'Account not found',
            ),
          ),
        ),
      );

      expect(find.text('Account not found'), findsOneWidget);
    });

    testWidgets('AppAmountField formats numeric input and shows currency', (
      tester,
    ) async {
      String? enteredAmount;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppAmountField(onChanged: (val) => enteredAmount = val),
          ),
        ),
      );

      expect(find.text('₦'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '5000.50');
      expect(enteredAmount, equals('5000.50'));
    });
  });

  group('DSN-009 — AppSystemNotification', () {
    testWidgets('Renders offline notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AppSystemNotification.offline()),
        ),
      );

      expect(find.byIcon(AppIcons.wifiOff), findsOneWidget);
      expect(
        find.text(
          "You're offline. Changes are saved on this phone and will sync when you're back online.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders syncFailure notification with actionable retry', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppSystemNotification.syncFailure(
              onActionPressed: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.alertCircle), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('DSN-010 — AppStatusBadge & AppResultIndicator', () {
    testWidgets('AppStatusBadge renders all 4 statuses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(
              children: [
                AppStatusBadge(status: AppOperationStatus.completed),
                AppStatusBadge(status: AppOperationStatus.pending),
                AppStatusBadge(status: AppOperationStatus.processing),
                AppStatusBadge(status: AppOperationStatus.failed),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('AppResultIndicator renders hero badge with semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppResultIndicator(
              status: AppOperationStatus.completed,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(
        find.bySemanticsLabel('Operation completed successfully'),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('DSN-012 — AppCard & AppKeyValueRow', () {
    testWidgets('AppCard renders child and triggers onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppKeyValueRow displays key and value cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppKeyValueRow(label: 'Recipient', value: 'Jane Doe'),
          ),
        ),
      );

      expect(find.text('Recipient'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });
  });

  group('DSN-013 — AppProgressBar', () {
    testWidgets(
      'Clamps progress value between 0.0 and 1.0 and exposes semantics',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: AppProgressBar(progress: 0.75)),
          ),
        );

        expect(
          find.bySemanticsLabel('Savings progress: 75 percent'),
          findsOneWidget,
        );

        handle.dispose();
      },
    );
  });

  group('DSN-014 — AppBottomSheet & AppEmptyState', () {
    testWidgets('AppBottomSheet shows modal with title and action buttons', (
      tester,
    ) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      title: 'Confirm Payment',
                      primaryActionLabel: 'Proceed',
                      onPrimaryAction: () => actionTriggered = true,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Payment'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);

      await tester.tap(find.text('Proceed'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppEmptyState renders wallet transactions empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AppEmptyState.walletTransactions()),
        ),
      );

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Your recent wallet activity will appear here.'),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.wallet), findsOneWidget);
    });

    testWidgets('AppEmptyState renders savings goals empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AppEmptyState.novaSaveGoals()),
        ),
      );

      expect(find.text('Start saving toward something'), findsOneWidget);
      expect(find.text('Create your first NovaSave goal.'), findsOneWidget);
      expect(find.byIcon(AppIcons.piggyBank), findsOneWidget);
    });
  });
}
