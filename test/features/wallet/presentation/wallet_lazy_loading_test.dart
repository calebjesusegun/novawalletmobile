import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

class _FakeSyncCoordinator implements SyncCoordinator {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockWalletRepository implements WalletRepository {
  @override
  Future<void> refresh() async {}

  @override
  Future<WalletSnapshot?> getWalletSnapshot() async => null;

  @override
  Future<void> setWalletSnapshot(WalletSnapshot snapshot) async {}

  @override
  Stream<WalletSnapshot?> watchWalletSnapshot() => Stream.value(null);

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {}

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) async {}

  @override
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  }) async => [];

  @override
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit}) =>
      Stream.value([]);

  @override
  Future<WalletTransaction?> getTransactionById(String id) async => null;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group(
    'T-PERF-001 / ASM-017 / PERF-001 / HC-PERFORMANCE — Wallet Lazy Loading',
    () {
      testWidgets(
        'Wallet activity feed virtualizes 1,000 transactions lazily without eager build',
        (tester) async {
          // Generate 1,000 activity items
          final activities = List.generate(1000, (index) {
            return WalletActivityItem(
              id: 'tx_$index',
              title: 'Recipient #$index',
              subtitle: 'Transfer',
              type: TransactionType.debit,
              amount: Money.fromKobo((index + 1) * 10000),
              timestamp: DateTime.utc(
                2026,
                9,
                22,
                10,
                0,
              ).subtract(Duration(minutes: index)),
              status: TransactionStatus.completed,
              operationId: OperationId('op_$index'),
            );
          });

          final projection = WalletProjection(
            confirmedBalance: const Money.fromKobo(10000000),
            spendableBalance: const Money.fromKobo(10000000),
            pendingDebitTotal: const Money.zero(),
            lastUpdatedAt: DateTime.utc(2026, 9, 22, 12, 0),
            activities: activities,
            pendingOperations: const [],
          );

          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                walletRepositoryProvider.overrideWithValue(
                  _MockWalletRepository(),
                ),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.online,
                ),
                syncStatusProvider.overrideWithValue(SyncStatus.idle),
                syncCoordinatorProvider.overrideWithValue(
                  _FakeSyncCoordinator(),
                ),
              ],
              child: const MaterialApp(home: WalletHomeScreen()),
            ),
          );

          await tester.pumpAndSettle();

          // First items should be built
          expect(find.text('Recipient #0'), findsOneWidget);
          expect(find.text('Recent Activity'), findsOneWidget);

          // Verify that offscreen item 999 is NOT instantiated in the widget tree (O(visible) lazy loading)
          expect(find.text('Recipient #999'), findsNothing);
          expect(find.text('Recipient #500'), findsNothing);
          expect(find.text('Recipient #100'), findsNothing);

          // Count constructed tiles — only a small window of visible tiles should exist (e.g. <= 15)
          final constructedTilesCount = tester
              .widgetList(find.byType(WalletActivityTile))
              .length;
          expect(
            constructedTilesCount,
            lessThan(15),
            reason: 'Large list must be virtualized lazily; only visible items should be built',
          );

          // Scroll down and verify dynamic virtualization builds subsequent items on-demand
          await tester.scrollUntilVisible(
            find.text('Recipient #20'),
            500.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          // Now Recipient #20 is in the tree
          expect(find.text('Recipient #20'), findsOneWidget);

          // Initial item Recipient #0 is now scrolled out and recycled
          expect(find.text('Recipient #0'), findsNothing);
        },
      );
    },
  );
}
