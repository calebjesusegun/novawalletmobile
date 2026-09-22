import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
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
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/sync_error.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

class FakeSyncCoordinator implements SyncCoordinator {
  int synchronizeCallCount = 0;
  SyncTrigger? lastTrigger;

  @override
  SyncStatus get status => SyncStatus.idle;

  @override
  Stream<SyncStatus> get onStatusChanged => const Stream.empty();

  @override
  bool get isSyncing => false;

  @override
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    synchronizeCallCount++;
    lastTrigger = trigger;
    return SyncRunResult.empty(trigger);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWalletRepository implements WalletRepository {
  @override
  Future<void> refresh() async {}

  @override
  Future<WalletSnapshot?> getWalletSnapshot() async => null;

  @override
  Future<void> setWalletSnapshot(WalletSnapshot snapshot) async {}

  @override
  Stream<WalletSnapshot?> watchWalletSnapshot() => const Stream.empty();

  @override
  Future<void> saveTransaction(WalletTransaction transaction) async {}

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) async {}

  @override
  Future<List<WalletTransaction>> getRecentTransactions({
    int? limit,
    int? offset,
  }) async => const [];

  @override
  Stream<List<WalletTransaction>> watchRecentTransactions({int? limit}) =>
      const Stream.empty();

  @override
  Future<WalletTransaction?> getTransactionById(String id) async => null;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Widget buildTestableWidget({
    required Widget child,
    List<dynamic> overrides = const [],
    WalletRepository? repository,
  }) {
    final effectiveRepo = repository ?? MockWalletRepository();
    return ProviderScope(
      overrides: [
        walletRepositoryProvider.overrideWithValue(effectiveRepo),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Inter'),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: child,
        ),
      ),
    );
  }

  group(
    'T-WAL-003 — Wallet Offline, Pending, Reconnect, and Sync-Failure States',
    () {
      testWidgets(
        'UI-WAL-02 / WAL-005: Offline state renders offline notification and last-updated balance',
        (tester) async {
          final lastUpdated = DateTime.utc(2026, 9, 21, 10, 30);
          final projection = WalletProjection(
            confirmedBalance: const Money.fromKobo(12545000), // ₦125,450.00
            spendableBalance: const Money.fromKobo(12545000),
            pendingDebitTotal: const Money.zero(),
            lastUpdatedAt: lastUpdated,
            activities: const [],
            pendingOperations: const [],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              overrides: [
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.offline,
                ),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
              ],
              child: const WalletHomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // 1. System notification banner for offline is visible
          expect(find.byType(AppSystemNotification), findsOneWidget);
          expect(
            find.text(
              "You're offline. Requests are queued securely and will process when you're back online.",
            ),
            findsOneWidget,
          );

          // 2. Headline balance is still visible and shows confirmed balance
          expect(find.text('₦125,450.00'), findsOneWidget);

          // 3. Balance card indicates last-updated time while offline
          expect(find.textContaining('Last updated at'), findsOneWidget);
        },
      );

      testWidgets(
        'UI-WAL-03 / WAL-006: Pending offline transfer renders in activity with Pending badge and does not debit headline balance',
        (tester) async {
          final op = FinancialOperation.create(
            id: OperationId.generate(),
            idempotencyKey: IdempotencyKey.generate(),
            payload: SendMoneyPayload(
              recipientName: 'Amina Bello',
              recipientAccountNumber: '0123456789',
              bankName: 'FirstBank',
              amount: const Money.fromKobo(500000), // ₦5,000.00
            ),
            createdAt: DateTime.utc(2026, 9, 21, 11, 0),
          );

          final projection = WalletProjection.build(
            snapshot: null,
            confirmedTransactions: const [],
            operations: [op],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              overrides: [
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.offline,
                ),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
              ],
              child: const WalletHomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // Headline balance remains ₦0.00 (not debited by pending transfer)
          expect(find.text('₦0.00'), findsOneWidget);

          // Pending transfer appears in activity list
          expect(find.byType(WalletActivityTile), findsOneWidget);
          expect(find.text('Amina Bello'), findsOneWidget);
          expect(find.text('-₦5,000.00'), findsOneWidget);

          // Pending badge is displayed
          expect(find.byType(AppStatusBadge), findsOneWidget);
          expect(find.text('Pending'), findsOneWidget);
        },
      );

      testWidgets(
        'UI-WAL-04 / WAL-007: Reconnecting / syncing state renders Back Online banner and Processing badge',
        (tester) async {
          final baseOp = FinancialOperation.create(
            id: OperationId.generate(),
            idempotencyKey: IdempotencyKey.generate(),
            payload: SendMoneyPayload(
              recipientName: 'Kelechi Okafor',
              recipientAccountNumber: '9876543210',
              bankName: 'FirstBank',
              amount: const Money.fromKobo(200000), // ₦2,000.00
            ),
            createdAt: DateTime.utc(2026, 9, 21, 11, 0),
          );
          final op = baseOp.markProcessing(
            at: DateTime.utc(2026, 9, 21, 11, 1),
          );

          final projection = WalletProjection.build(
            snapshot: null,
            confirmedTransactions: const [],
            operations: [op],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              overrides: [
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.online,
                ),
                syncStatusProvider.overrideWithValue(SyncStatus.syncing),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
              ],
              child: const WalletHomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Back online banner is displayed
          expect(find.byType(AppSystemNotification), findsOneWidget);
          expect(
            find.text('Back online. Syncing pending actions...'),
            findsOneWidget,
          );

          // 2. Activity row displays Processing badge
          expect(find.byType(WalletActivityTile), findsOneWidget);
          expect(find.text('Kelechi Okafor'), findsOneWidget);
          expect(find.text('-₦2,000.00'), findsOneWidget);
          expect(find.byType(AppStatusBadge), findsOneWidget);
          expect(find.text('Processing'), findsOneWidget);
        },
      );

      testWidgets(
        'UI-WAL-05 / WAL-008: Successful send completion updates confirmed balance and removes pending status badge',
        (tester) async {
          // Completed transfer from local cache
          final tx = WalletTransaction(
            id: 'tx-completed-1',
            counterparty: 'Kelechi Okafor',
            amount: const Money.fromKobo(200000), // ₦2,000.00
            type: TransactionType.debit,
            status: TransactionStatus.completed,
            createdAt: DateTime.utc(2026, 9, 21, 11, 5),
          );

          final projection = WalletProjection(
            confirmedBalance: const Money.fromKobo(
              800000,
            ), // Debited to ₦8,000.00
            spendableBalance: const Money.fromKobo(800000),
            pendingDebitTotal: const Money.zero(),
            lastUpdatedAt: DateTime.utc(2026, 9, 21, 11, 5),
            activities: [WalletActivityItem.fromTransaction(tx)],
            pendingOperations: const [],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              overrides: [
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.online,
                ),
                syncStatusProvider.overrideWithValue(SyncStatus.idle),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
              ],
              child: const WalletHomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // Confirmed debited balance is displayed
          expect(find.text('₦8,000.00'), findsOneWidget);

          // Transaction row is completed: no AppStatusBadge
          expect(find.byType(WalletActivityTile), findsOneWidget);
          expect(find.text('Kelechi Okafor'), findsOneWidget);
          expect(find.text('-₦2,000.00'), findsOneWidget);
          expect(find.byType(AppStatusBadge), findsNothing);
        },
      );

      testWidgets(
        'UI-WAL-06 / WAL-009: Recoverable sync failure renders banner with Retry action, and tapping Retry triggers sync',
        (tester) async {
          final fakeSync = FakeSyncCoordinator();

          final baseOp = FinancialOperation.create(
            id: OperationId.generate(),
            idempotencyKey: IdempotencyKey.generate(),
            payload: SendMoneyPayload(
              recipientName: 'David Adeleke',
              recipientAccountNumber: '1122334455',
              bankName: 'FirstBank',
              amount: const Money.fromKobo(1000000),
            ),
            createdAt: DateTime.utc(2026, 9, 21, 11, 0),
          );
          final op = baseOp.markProcessing().markRecoverableError(
            error: SyncError.recoverable(
              message: 'Network connection reset by peer',
            ),
          );

          final projection = WalletProjection.build(
            snapshot: null,
            confirmedTransactions: const [],
            operations: [op],
          );

          await tester.pumpWidget(
            buildTestableWidget(
              overrides: [
                connectivityStatusProvider.overrideWithValue(
                  ConnectivityStatus.online,
                ),
                syncStatusProvider.overrideWithValue(SyncStatus.failed),
                syncCoordinatorProvider.overrideWithValue(fakeSync),
                walletProjectionProvider.overrideWithValue(
                  AsyncValue.data(projection),
                ),
              ],
              child: const WalletHomeScreen(),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Sync failure banner is rendered
          expect(find.byType(AppSystemNotification), findsOneWidget);
          expect(
            find.text(
              "Couldn't sync pending actions. Your funds and requests are queued securely.",
            ),
            findsOneWidget,
          );

          // 2. Retry button is present in banner
          expect(find.text('Retry'), findsOneWidget);

          // 3. Saved transfer is retained in activity list with Failed status badge
          expect(find.byType(WalletActivityTile), findsOneWidget);
          expect(find.text('David Adeleke'), findsOneWidget);
          expect(find.text('-₦10,000.00'), findsOneWidget);
          expect(find.byType(AppStatusBadge), findsOneWidget);
          expect(find.text('Failed'), findsOneWidget);

          // 4. Tap Retry button on banner
          await tester.tap(find.text('Retry'));
          await tester.pumpAndSettle();

          expect(fakeSync.synchronizeCallCount, equals(1));
          expect(fakeSync.lastTrigger, equals(SyncTrigger.userRetry));
        },
      );
    },
  );
}
