import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/app.dart';
import 'package:novawallet/app/navigation/app_bottom_nav_bar.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/core/persistence/persistence_providers.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';

void main() {
  group(
    'T-APP-001 / ASM-001 / DSN-011 / A11Y-001 — App Shell and Navigation',
    () {
      late AppDatabase db;

      setUp(() {
        db = AppDatabase.inMemory();
      });

      tearDown(() async {
        await db.close();
      });

      Widget buildApp({List<dynamic> additionalOverrides = const []}) {
        return ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            walletProjectionProvider.overrideWithValue(
              AsyncValue.data(
                WalletProjection(
                  confirmedBalance: const Money.zero(),
                  spendableBalance: const Money.zero(),
                  pendingDebitTotal: const Money.zero(),
                  lastUpdatedAt: DateTime.utc(2026, 9, 21),
                  activities: const [],
                  pendingOperations: const [],
                ),
              ),
            ),
            ...additionalOverrides.cast(),
          ],
          child: const NovaWalletApp(),
        );
      }

      testWidgets('App launches into shell with Wallet selected by default', (
        tester,
      ) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Verify bottom nav items exist
        expect(find.byType(AppBottomNavBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('Wallet'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('Send'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('NovaSave'),
          ),
          findsOneWidget,
        );

        // Verify Wallet tab is active by default
        expect(find.byType(WalletHomeScreen), findsOneWidget);
        expect(find.text('No transactions yet'), findsOneWidget);
      });

      testWidgets('Tapping Send and NovaSave tabs updates destination', (
        tester,
      ) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Tap Send tab
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('Send'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SendMoneyShellTab), findsOneWidget);
        expect(
          find.text('Transfer funds securely even while offline.'),
          findsOneWidget,
        );

        // Tap NovaSave tab
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('NovaSave'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NovaSaveShellTab), findsOneWidget);
        expect(find.text('Start saving toward something'), findsOneWidget);

        // Tap back to Wallet tab
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.text('Wallet'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WalletHomeScreen), findsOneWidget);
      });

      testWidgets('Bottom nav exposes accessible Semantics for each tab', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Wallet tab'), findsOneWidget);
        expect(find.bySemanticsLabel('Send tab'), findsOneWidget);
        expect(find.bySemanticsLabel('NovaSave tab'), findsOneWidget);

        handle.dispose();
      });

      testWidgets('appNavigationProvider can be overridden in tests', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            additionalOverrides: [
              appNavigationProvider.overrideWith(
                (ref) => AppNavigationNotifier(AppDestination.send),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Starts on Send tab due to override
        expect(find.byType(SendMoneyShellTab), findsOneWidget);
        expect(find.byIcon(AppIcons.arrowUpRight), findsWidgets);
      });
    },
  );
}
