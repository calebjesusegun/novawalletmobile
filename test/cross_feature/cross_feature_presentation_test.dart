import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribution_result_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_result_screen.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_transaction_detail_sheet.dart';
import 'package:novawallet/sync/application/retry_policy.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

class _MockSyncCoordinatorForRetry implements SyncCoordinator {
  int retryCalls = 0;
  OperationId? lastRetriedId;

  @override
  Future<RetryResult> retryOperation(OperationId id) async {
    retryCalls++;
    lastRetriedId = id;
    return const RetryResult.success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Cross-Feature Status & Presentation Normalization (T-XF-002, WAL-006, WAL-009, SND-019, NSV-018, NSV-022, SYNC-014)', () {
    late _MockSyncCoordinatorForRetry mockSync;

    setUp(() {
      mockSync = _MockSyncCoordinatorForRetry();
    });

    testWidgets(
      'AppStatusBadge and AppResultIndicator maintain identical semantics across operation states (SYNC-014)',
      (tester) async {
        final handle = tester.ensureSemantics();

        const states = [
          (
            AppOperationStatus.completed,
            'Completed',
            'Operation completed successfully',
          ),
          (
            AppOperationStatus.pending,
            'Pending',
            'Operation pending synchronization',
          ),
          (
            AppOperationStatus.processing,
            'Processing',
            'Operation currently processing',
          ),
          (AppOperationStatus.failed, 'Failed', 'Operation failed'),
        ];

        for (final (status, badgeLabel, indicatorLabel) in states) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AppStatusBadge(status: status),
                    AppResultIndicator(status: status),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(badgeLabel), findsOneWidget);
          expect(find.bySemanticsLabel(indicatorLabel), findsOneWidget);
        }

        handle.dispose();
      },
    );

    testWidgets(
      'Send Money sync failure retry invokes centralized coordinator with stable operation identity (SND-020)',
      (tester) async {
        final opId = OperationId('op-send-retry-001');
        final idempotencyKey = IdempotencyKey('idem-send-retry-001');
        const amount = Money.fromKobo(500000); // ₦5,000.00
        final recoverableError = SyncError.recoverable(
          message: 'Network timed out',
          code: 'NETWORK_TIMEOUT',
        );

        final sendOp = FinancialOperation.send(
          id: opId,
          idempotencyKey: idempotencyKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Amina Bello',
            bankName: 'FirstBank',
            amount: amount,
          ),
        ).markProcessing().markRecoverableError(error: recoverableError);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              syncCoordinatorProvider.overrideWithValue(mockSync),
              operationByIdStreamProvider(opId)
                  .overrideWith((_) => Stream.value(sendOp)),
              connectivityStatusProvider.overrideWithValue(
                ConnectivityStatus.online,
              ),
            ],
            child: MaterialApp(
              home: TransferResultScreen(operation: sendOp, onDone: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final sendRetryBtn = find.byKey(
          const Key('transfer_sync_failure_retry_button'),
        );
        expect(sendRetryBtn, findsOneWidget);
        await tester.tap(sendRetryBtn);
        await tester.pumpAndSettle();

        expect(mockSync.retryCalls, 1);
        expect(mockSync.lastRetriedId, opId);
      },
    );

    testWidgets(
      'NovaSave Contribution sync failure retry invokes centralized coordinator with stable operation identity (NSV-023)',
      (tester) async {
        final opId = OperationId('op-contrib-retry-001');
        final idempotencyKey = IdempotencyKey('idem-contrib-retry-001');
        const amount = Money.fromKobo(500000); // ₦5,000.00
        final recoverableError = SyncError.recoverable(
          message: 'Network timed out',
          code: 'NETWORK_TIMEOUT',
        );

        final goal = SavingsGoal(
          id: 'goal-emergency',
          name: 'Emergency Fund',
          targetAmount: const Money.fromKobo(50000000),
          savedAmount: const Money.fromKobo(10000000),
          targetDate: DateTime.utc(2027, 12, 31),
        );

        final contribOp = FinancialOperation.contribution(
          id: opId,
          idempotencyKey: idempotencyKey,
          payload: ContributionPayload(
            goalId: goal.id,
            goalName: goal.name,
            amount: amount,
          ),
        ).markProcessing().markRecoverableError(error: recoverableError);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              syncCoordinatorProvider.overrideWithValue(mockSync),
              operationByIdStreamProvider(opId)
                  .overrideWith((_) => Stream.value(contribOp)),
              connectivityStatusProvider.overrideWithValue(
                ConnectivityStatus.online,
              ),
            ],
            child: MaterialApp(
              home: ContributionResultScreen(
                operation: contribOp,
                goal: goal,
                onDone: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final contribRetryBtn = find.byKey(
          const Key('contribution_sync_failure_retry_button'),
        );
        expect(contribRetryBtn, findsOneWidget);
        await tester.tap(contribRetryBtn);
        await tester.pumpAndSettle();

        expect(mockSync.retryCalls, 1);
        expect(mockSync.lastRetriedId, opId);
      },
    );

    testWidgets(
      'Wallet Transaction Detail Sheet retry triggers coordinator with stable operation identity (WAL-009)',
      (tester) async {
        final opId = OperationId('op-wallet-retry-001');
        final idempotencyKey = IdempotencyKey('idem-wallet-retry-001');
        const amount = Money.fromKobo(500000); // ₦5,000.00
        final recoverableError = SyncError.recoverable(
          message: 'Network timed out',
          code: 'NETWORK_TIMEOUT',
        );

        final sendOp = FinancialOperation.send(
          id: opId,
          idempotencyKey: idempotencyKey,
          payload: SendMoneyPayload(
            recipientAccountNumber: '0123456789',
            recipientName: 'Amina Bello',
            bankName: 'FirstBank',
            amount: amount,
          ),
        ).markProcessing().markRecoverableError(error: recoverableError);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              syncCoordinatorProvider.overrideWithValue(mockSync),
              operationByIdStreamProvider(opId)
                  .overrideWith((_) => Stream.value(sendOp)),
              connectivityStatusProvider.overrideWithValue(
                ConnectivityStatus.online,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: WalletTransactionDetailSheet(
                  item: WalletActivityItem.fromOperation(sendOp),
                  onRetry: () => mockSync.retryOperation(opId),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final walletRetryBtn = find.text('Retry Transfer');
        expect(walletRetryBtn, findsOneWidget);
        await tester.tap(walletRetryBtn);
        await tester.pumpAndSettle();

        expect(mockSync.retryCalls, 1);
        expect(mockSync.lastRetriedId, opId);
      },
    );

    testWidgets(
      'Connectivity banners do not replace or suppress operation status badges (UI-CMP-03, WAL-006, SND-019, NSV-018)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AppSystemNotification.offline(),
                  const AppStatusBadge(status: AppOperationStatus.pending),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            "You're offline. Requests are queued securely and will process when you're back online.",
          ),
          findsOneWidget,
        );
        expect(find.text('Pending'), findsOneWidget);
        expect(find.byType(AppStatusBadge), findsOneWidget);
      },
    );
  });
}
