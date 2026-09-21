import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';
import 'package:novawallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:novawallet/features/wallet/domain/wallet_transaction.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_loading_skeleton.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_transaction_detail_sheet.dart';
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

  group('T-WAL-004 — Wallet Loading, Empty, and Pending-Detail States', () {
    testWidgets(
      'UI-WAL-08 / WAL-010: Loading state displays WalletLoadingSkeleton with accessible semantics',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [
              walletProjectionProvider.overrideWithValue(
                const AsyncValue.loading(),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        expect(find.byType(WalletLoadingSkeleton), findsOneWidget);
        expect(find.bySemanticsLabel('Loading wallet data'), findsOneWidget);
      },
    );

    testWidgets(
      'UI-WAL-09 / WAL-004: Empty state renders "No transactions yet" and description',
      (tester) async {
        final projection = WalletProjection(
          confirmedBalance: const Money.zero(),
          spendableBalance: const Money.zero(),
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

        expect(find.text('No transactions yet'), findsOneWidget);
        expect(
          find.text('Your recent wallet activity will appear here.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'UI-WAL-10 / WAL-011: Tapping a pending activity tile opens detail sheet with saved-on-phone explanation',
      (tester) async {
        final op = FinancialOperation.create(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientName: 'David Adeleke',
            recipientAccountNumber: '1122334455',
            bankName: 'FirstBank',
            amount: const Money.fromKobo(1000000), // ₦10,000.00
          ),
          createdAt: DateTime.utc(2026, 9, 21, 10, 30),
        );

        final projection = WalletProjection.build(
          snapshot: null,
          confirmedTransactions: const [],
          operations: [op],
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

        // Tap on the pending activity tile
        expect(find.byType(WalletActivityTile), findsOneWidget);
        await tester.tap(find.byType(WalletActivityTile));
        await tester.pumpAndSettle();

        // Verify detail sheet is visible matching UI-WAL-10
        expect(find.byType(WalletTransactionDetailSheet), findsOneWidget);
        expect(find.text('Transaction Details'), findsOneWidget);
        expect(find.text('₦10,000.00'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WalletTransactionDetailSheet),
            matching: find.text('David Adeleke'),
          ),
          findsOneWidget,
        );
        expect(find.text('FirstBank • 1122334455'), findsOneWidget);
        expect(find.text('Saved on this phone'), findsOneWidget);
        expect(
          find.text(
            'Saved on this device. This transfer will be sent automatically when you\'re back online.',
          ),
          findsOneWidget,
        );

        // Close sheet
        await tester.tap(find.widgetWithText(AppButton, 'Close'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletTransactionDetailSheet), findsNothing);
      },
    );

    testWidgets(
      'UI-WAL-10 / WAL-009: Tapping a failed activity tile opens detail sheet with sync failure banner and Retry button',
      (tester) async {
        final fakeSync = FakeSyncCoordinator();
        final baseOp = FinancialOperation.create(
          id: OperationId.generate(),
          idempotencyKey: IdempotencyKey.generate(),
          payload: SendMoneyPayload(
            recipientName: 'Chioma Rowland',
            recipientAccountNumber: '9988776655',
            bankName: 'Zenith Bank',
            amount: const Money.fromKobo(500000), // ₦5,000.00
          ),
          createdAt: DateTime.utc(2026, 9, 21, 11, 0),
        );
        final failedOp = baseOp.markProcessing().markRecoverableError(
          error: SyncError.recoverable(message: 'Connection timed out'),
        );

        final projection = WalletProjection.build(
          snapshot: null,
          confirmedTransactions: const [],
          operations: [failedOp],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            overrides: [
              syncCoordinatorProvider.overrideWithValue(fakeSync),
              walletProjectionProvider.overrideWithValue(
                AsyncValue.data(projection),
              ),
            ],
            child: const WalletHomeScreen(),
          ),
        );

        // Tap on the failed activity tile
        await tester.tap(find.byType(WalletActivityTile));
        await tester.pumpAndSettle();

        expect(find.byType(WalletTransactionDetailSheet), findsOneWidget);
        expect(find.text('Sync Failed'), findsOneWidget);
        expect(find.text('Connection timed out'), findsOneWidget);
        expect(find.text('Retry Transfer'), findsOneWidget);

        // Tap Retry button in bottom sheet
        await tester.tap(find.widgetWithText(AppButton, 'Retry Transfer'));
        await tester.pumpAndSettle();

        // Verify sync triggered with userRetry
        expect(fakeSync.synchronizeCallCount, equals(1));
        expect(fakeSync.lastTrigger, equals(SyncTrigger.userRetry));
        expect(find.byType(WalletTransactionDetailSheet), findsNothing);
      },
    );

    testWidgets(
      'UI-WAL-10: Tapping a completed confirmed transaction displays reference and does not show saved-on-phone banner',
      (tester) async {
        final tx = WalletTransaction(
          id: 'tx-101',
          type: TransactionType.credit,
          amount: const Money.fromKobo(5000000), // ₦50,000.00
          counterparty: 'Salary Deposit',
          createdAt: DateTime.utc(2026, 9, 20, 8, 0),
          status: TransactionStatus.completed,
          reference: 'REF-SALARY-2026',
          narration: 'September Salary',
        );

        final projection = WalletProjection.build(
          snapshot: null,
          confirmedTransactions: [tx],
          operations: const [],
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

        await tester.tap(find.byType(WalletActivityTile));
        await tester.pumpAndSettle();

        expect(find.byType(WalletTransactionDetailSheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(WalletTransactionDetailSheet),
            matching: find.text('Salary Deposit'),
          ),
          findsOneWidget,
        );
        expect(find.text('REF-SALARY-2026'), findsOneWidget);
        expect(find.text('Saved on this phone'), findsNothing);
        expect(find.byType(AppStatusBadge), findsOneWidget);
      },
    );
  });
}
