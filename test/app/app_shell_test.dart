import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/app.dart';
import 'package:novawallet/app/navigation/app_bottom_nav_bar.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';

void main() {
  group(
    'T-APP-001 / ASM-001 / DSN-011 / A11Y-001 — App Shell and Navigation',
    () {
      testWidgets('App launches into shell with Wallet selected by default', (
        tester,
      ) async {
        await tester.pumpWidget(const ProviderScope(child: NovaWalletApp()));

        // Verify bottom nav items exist
        expect(find.byType(AppBottomNavBar), findsOneWidget);
        expect(find.text('Wallet'), findsWidgets);
        expect(find.text('Send'), findsOneWidget);
        expect(find.text('NovaSave'), findsOneWidget);

        // Verify Wallet tab is active by default
        expect(find.byType(WalletShellTab), findsOneWidget);
        expect(find.text('No transactions yet'), findsOneWidget);
      });

      testWidgets('Tapping Send and NovaSave tabs updates destination', (
        tester,
      ) async {
        await tester.pumpWidget(const ProviderScope(child: NovaWalletApp()));

        // Tap Send tab
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        expect(find.byType(SendMoneyShellTab), findsOneWidget);
        expect(
          find.text('Transfer funds securely even while offline.'),
          findsOneWidget,
        );

        // Tap NovaSave tab
        await tester.tap(find.text('NovaSave'));
        await tester.pumpAndSettle();

        expect(find.byType(NovaSaveShellTab), findsOneWidget);
        expect(find.text('Start saving toward something'), findsOneWidget);

        // Tap back to Wallet tab
        await tester.tap(find.text('Wallet').last);
        await tester.pumpAndSettle();

        expect(find.byType(WalletShellTab), findsOneWidget);
      });

      testWidgets('Bottom nav exposes accessible Semantics for each tab', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(const ProviderScope(child: NovaWalletApp()));

        expect(find.bySemanticsLabel('Wallet tab'), findsOneWidget);
        expect(find.bySemanticsLabel('Send tab'), findsOneWidget);
        expect(find.bySemanticsLabel('NovaSave tab'), findsOneWidget);

        handle.dispose();
      });

      testWidgets('appNavigationProvider can be overridden in tests', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appNavigationProvider.overrideWith(
                (ref) => AppNavigationNotifier(AppDestination.send),
              ),
            ],
            child: const NovaWalletApp(),
          ),
        );

        // Starts on Send tab due to override
        expect(find.byType(SendMoneyShellTab), findsOneWidget);
        expect(find.byIcon(AppIcons.arrowUpRight), findsWidgets);
      });
    },
  );
}
