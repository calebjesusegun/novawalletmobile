import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/empty_states/app_empty_state.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_balance_card.dart';

class MockWalletRepository implements WalletRepository {
  WalletSnapshot? snapshot;
  final List<WalletTransaction> transactions = [];
  int refreshCallCount = 0;

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  @override
  Future<WalletSnapshot?> getWalletSnapshot() async => snapshot;

  @override
  Future<void> setWalletSnapshot(WalletSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Stream<WalletSnapshot?> watchWalletSnapshot() => Stream.value(snapshot);

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {
    transactions.insert(0, transaction);
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) async {
    this.transactions.insertAll(0, transactions);
  }

  @override
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  }) async => transactions;

  @override
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit}) =>
      Stream.value(transactions);

  @override
  Future<WalletTransaction?> getTransactionById(String id) async {
    for (final tx in transactions) {
      if (tx.id == id) return tx;
    }
    return null;
  }
}

void main() {
  Widget buildTestableWidget({
    required Widget child,
    List<dynamic> overrides = const [],
    TextScaler? textScaler,
  }) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: textScaler ?? TextScaler.noScaling,
          ),
          child: child,
        ),
      ),
    );
  }

  group('WalletHomeScreen Presentation (T-WAL-002, WAL-001, WAL-002, UI-WAL-01)', () {
    testWidgets(
      'renders headline balance formatted in Naira from integer kobo',
      (tester) async {
        final projection = WalletProjection(
          confirmedBalance: const Money.fromKobo(12545000), // ₦125,450.00
          spendableBalance: const Money.fromKobo(12545000),
          pendingDebitTotal: const Money.zero(),
          lastUpdatedAt: DateTime.utc(2026, 9, 21, 10, 0),
          activities: const [],
          pendingOperations: const [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [
              walletProjectionProvider.overrideWithValue(
                AsyncValue.data(projection),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        expect(find.text('Available Balance'), findsOneWidget);
        expect(find.text('₦125,450.00'), findsOneWidget);
        expect(find.text('Send Money'), findsOneWidget);
        expect(find.text('NovaSave'), findsOneWidget);
      },
    );

    testWidgets('Send Money button switches active destination to Send', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(WalletProjection.build()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WalletHomeScreen()),
        ),
      );

      expect(
        container.read(appNavigationProvider),
        equals(AppDestination.wallet),
      );

      await tester.tap(find.widgetWithText(AppButton, 'Send Money'));
      await tester.pumpAndSettle();

      expect(
        container.read(appNavigationProvider),
        equals(AppDestination.send),
      );
    });

    testWidgets('NovaSave button switches active destination to NovaSave', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          walletProjectionProvider.overrideWithValue(
            AsyncValue.data(WalletProjection.build()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WalletHomeScreen()),
        ),
      );

      await tester.tap(find.widgetWithText(AppButton, 'NovaSave'));
      await tester.pumpAndSettle();

      expect(
        container.read(appNavigationProvider),
        equals(AppDestination.novaSave),
      );
    });

    testWidgets(
      'renders empty state when there are no transactions (UI-WAL-09)',
      (tester) async {
        final projection = WalletProjection(
          confirmedBalance: const Money.fromKobo(1000000),
          spendableBalance: const Money.fromKobo(1000000),
          pendingDebitTotal: const Money.zero(),
          lastUpdatedAt: DateTime.utc(2026, 9, 21),
          activities: const [],
          pendingOperations: const [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [
              walletProjectionProvider.overrideWithValue(
                AsyncValue.data(projection),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        expect(find.byType(AppEmptyState), findsOneWidget);
        expect(find.text('No transactions yet'), findsOneWidget);
        expect(
          find.text('Your recent wallet activity will appear here.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders recent activities with amounts, counterparties, and types',
      (tester) async {
        final activities = [
          WalletActivityItem(
            id: 'tx-1',
            title: 'John Doe',
            subtitle: 'Transfer',
            amount: const Money.fromKobo(500000), // ₦5,000.00
            type: TransactionType.debit,
            timestamp: DateTime.utc(2026, 9, 21, 14, 30),
            status: TransactionStatus.completed,
          ),
          WalletActivityItem(
            id: 'tx-2',
            title: 'Salary Deposit',
            subtitle: 'Deposit',
            amount: const Money.fromKobo(50000000), // ₦500,000.00
            type: TransactionType.credit,
            timestamp: DateTime.utc(2026, 9, 20, 9, 0),
            status: TransactionStatus.completed,
          ),
        ];

        final projection = WalletProjection(
          confirmedBalance: const Money.fromKobo(62000000),
          spendableBalance: const Money.fromKobo(62000000),
          pendingDebitTotal: const Money.zero(),
          lastUpdatedAt: DateTime.utc(2026, 9, 21),
          activities: activities,
          pendingOperations: const [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [
              walletProjectionProvider.overrideWithValue(
                AsyncValue.data(projection),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('-₦5,000.00'), findsOneWidget);
        expect(find.text('Salary Deposit'), findsOneWidget);
        expect(find.text('+₦500,000.00'), findsOneWidget);
        expect(find.byType(WalletActivityTile), findsNWidgets(2));
      },
    );

    testWidgets(
      'pull to refresh invokes controller and repository refresh (WAL-003, ASM-004)',
      (tester) async {
        final mockRepo = MockWalletRepository();
        mockRepo.snapshot = WalletSnapshot(
          balance: const Money.fromKobo(5000000),
          lastUpdatedAt: DateTime.utc(2026, 9, 21),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
            child: const WalletHomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(mockRepo.refreshCallCount, equals(0));

        // Drag down to trigger pull-to-refresh
        await tester.fling(
          find.byType(WalletBalanceCard),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(mockRepo.refreshCallCount, equals(1));
      },
    );

    testWidgets(
      'responsive layout supports larger system text scale without overflow (A11Y-002)',
      (tester) async {
        final activities = [
          WalletActivityItem(
            id: 'tx-1',
            title:
                'A Very Long Recipient Name That Might Overflow Small Screens',
            subtitle: 'Transfer',
            amount: const Money.fromKobo(12545000),
            type: TransactionType.debit,
            timestamp: DateTime.utc(2026, 9, 21, 14, 30),
            status: TransactionStatus.completed,
          ),
        ];

        final projection = WalletProjection(
          confirmedBalance: const Money.fromKobo(12545000),
          spendableBalance: const Money.fromKobo(12545000),
          pendingDebitTotal: const Money.zero(),
          lastUpdatedAt: DateTime.utc(2026, 9, 21),
          activities: activities,
          pendingOperations: const [],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            textScaler: const TextScaler.linear(1.5), // 150% font scale
            overrides: [
              walletProjectionProvider.overrideWithValue(
                AsyncValue.data(projection),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('₦125,450.00'), findsOneWidget);
        expect(find.byType(WalletActivityTile), findsOneWidget);
      },
    );
  });
}
