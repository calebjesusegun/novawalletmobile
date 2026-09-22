import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/app/app.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/fake_backend/fake_backend_providers.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/in_memory_remote_ledger.dart';
import 'package:novawallet/features/send_money/presentation/screens/amount_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/recipient_entry_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/transfer_confirmation_screen.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

void main() {
  group('T-TST-003 / ASM-024 / ASM-012 / ASM-013 / TST-006 — App-Level Offline Queue -> Restart -> Reconnect Integration', () {
    late Directory tempDir;
    late File dbFile;
    late InMemoryRemoteLedger remoteLedger;
    late FakeRemoteApi fakeRemoteApi;
    late InMemoryConnectivityService connectivity;

    const initialBalance = Money.fromKobo(12545000); // ₦125,450.00
    const transferAmount = Money.fromKobo(1000000); // ₦10,000.00
    const expectedBalanceAfter = Money.fromKobo(11545000); // ₦115,450.00

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync(
        'novawallet_app_offline_test_',
      );
      dbFile = File('${tempDir.path}/novawallet_integration.sqlite');

      remoteLedger = InMemoryRemoteLedger();
      await remoteLedger.setBalance(initialBalance);
      fakeRemoteApi = FakeRemoteApi(ledger: remoteLedger);

      connectivity = InMemoryConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
    });

    tearDown(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets(
      'Full App Journey: Offline Send -> Pending in SQLite -> App Kill & Restart -> Reconnect Auto-Sync -> Exactly-Once Settlement (ASM-024, TST-006, HC-EXACTLY-ONCE-EFFECT)',
      (tester) async {
        // ===================================================================
        // STEP 1: Cold App Launch on persistent SQLite file while OFFLINE
        // ===================================================================
        var db = AppDatabase.forFile(dbFile);
        await db.seedInitialDataIfEmpty();

        var container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            connectivityServiceProvider.overrideWithValue(connectivity),
            remoteApiProvider.overrideWithValue(fakeRemoteApi),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NovaWalletApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert on Wallet screen: initial confirmed balance is ₦125,450.00
        expect(find.text('₦125,450.00'), findsOneWidget);
        expect(find.text('Available Balance'), findsOneWidget);

        // Assert offline system notification is displayed
        expect(find.byType(AppSystemNotification), findsOneWidget);
        expect(
          find.text(
            "You're offline. Requests are queued securely and will process when you're back online.",
          ),
          findsOneWidget,
        );

        // Remote balance is untouched
        expect(await remoteLedger.getBalance(), initialBalance);
        expect(await remoteLedger.getTransactions(), isEmpty);

        // ===================================================================
        // STEP 2: Navigate to Send Money tab while OFFLINE
        // ===================================================================
        await tester.tap(find.bySemanticsLabel('Send tab'));
        await tester.pumpAndSettle();

        expect(find.byType(RecipientEntryScreen), findsOneWidget);

        // Enter recipient account number: 0123456789
        await tester.enterText(find.byType(TextField), '0123456789');
        await tester.pumpAndSettle();

        // Resolved recipient details appear (John Doe)
        expect(find.text('John Doe'), findsWidgets);

        // Tap Continue
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 3: Enter Amount ₦10,000.00
        // ===================================================================
        expect(find.byType(AmountEntryScreen), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '10000');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 4: Confirm Transfer while OFFLINE
        // ===================================================================
        expect(find.byType(TransferConfirmationScreen), findsOneWidget);
        expect(find.text('Confirm Transfer'), findsOneWidget);

        // Verify offline notice on confirmation screen
        expect(
          find.text(
            "You're offline. Transfer will be queued securely and sent when connected.",
          ),
          findsOneWidget,
        );

        // Tap Confirm Transfer
        await tester.tap(find.byKey(const Key('confirm_transfer_button')));
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 5: Verify Pending Result View (UI-SND-09 / NSV-017)
        // ===================================================================
        expect(
          find.byKey(const Key('transfer_result_pending_offline_view')),
          findsOneWidget,
        );
        expect(find.text('Transfer Pending'), findsOneWidget);
        expect(find.text('₦10,000.00'), findsOneWidget);
        expect(
          find.text('Pending — will send when back online'),
          findsOneWidget,
        );

        // Tap "Back to wallet"
        await tester.tap(find.byKey(const Key('transfer_pending_back_button')));
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 6: Verify Wallet State with Pending Transfer (HC-MONEY)
        // ===================================================================
        // User is back on Wallet home screen
        expect(find.text('Available Balance'), findsOneWidget);

        // Crucial HC-MONEY design rule:
        // Confirmed balance is STILL ₦125,450.00 (NOT yet debited)
        expect(find.text('₦125,450.00'), findsOneWidget);

        // Pending transfer activity item is displayed
        expect(find.text('John Doe'), findsWidgets);
        expect(find.text('Pending'), findsWidgets);

        // SQLite verification: operation is safely persisted in pending status
        final opRepo = container.read(operationRepositoryProvider);
        final pendingBeforeRestart = await opRepo.getPendingOperations();
        expect(pendingBeforeRestart.length, 1);
        final opId = pendingBeforeRestart.first.id;
        final opIdKey = pendingBeforeRestart.first.idempotencyKey;
        expect(pendingBeforeRestart.first.status, OperationStatus.pending);

        // Remote backend is still completely untouched while offline
        expect(await remoteLedger.getBalance(), initialBalance);
        expect(await remoteLedger.getTransactions(), isEmpty);

        // ===================================================================
        // STEP 7: SIMULATE PROCESS CRASH & APP RESTART WHILE OFFLINE
        // ===================================================================
        // Unmount current UI
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        // Close database and dispose container (simulating complete OS process death)
        await db.close();
        container.dispose();

        // Boot completely NEW application instance on the SAME SQLite file
        db = AppDatabase.forFile(dbFile);
        container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            connectivityServiceProvider.overrideWithValue(connectivity),
            remoteApiProvider.overrideWithValue(fakeRemoteApi),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NovaWalletApp(),
          ),
        );
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 8: ASSERT DURABILITY ACROSS RESTART (HC-OFFLINE-DURABILITY)
        // ===================================================================
        // The pending transfer survived the restart!
        expect(find.text('John Doe'), findsWidgets);
        expect(find.text('Pending'), findsWidgets);
        expect(find.text('₦125,450.00'), findsOneWidget);

        final opRepoAfterRestart = container.read(operationRepositoryProvider);
        final pendingAfterRestart = await opRepoAfterRestart
            .getPendingOperations();
        expect(pendingAfterRestart.length, 1);
        expect(pendingAfterRestart.first.id, opId);
        expect(pendingAfterRestart.first.idempotencyKey, opIdKey);
        expect(pendingAfterRestart.first.status, OperationStatus.pending);

        // Remote backend is still untouched
        expect(await remoteLedger.getBalance(), initialBalance);

        // ===================================================================
        // STEP 9: RECONNECT & CENTRALIZED AUTO-SYNC
        // ===================================================================
        // Bring device back online
        connectivity.setStatus(ConnectivityStatus.online);

        // Allow the sync coordinator to trigger and settle
        final syncCoordinator = container.read(syncCoordinatorProvider);
        await tester.pump(const Duration(milliseconds: 100));

        while (syncCoordinator.status == SyncStatus.syncing) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        // ===================================================================
        // STEP 10: ASSERT EXACTLY-ONCE FINANCIAL EFFECT (HC-EXACTLY-ONCE-EFFECT)
        // ===================================================================
        // 1. Pending operation queue in SQLite is now empty
        final pendingAfterSync = await opRepoAfterRestart
            .getPendingOperations();
        expect(pendingAfterSync, isEmpty);

        // 2. Operation transitioned to completed with remote reference
        final completedOp = await opRepoAfterRestart.getOperationById(opId);
        expect(completedOp, isNotNull);
        expect(completedOp!.status, OperationStatus.completed);
        expect(completedOp.remoteReference, isNotNull);
        expect(completedOp.remoteReference, isNotEmpty);

        // 3. Remote backend balance was debited EXACTLY ONCE (₦125,450 - ₦10,000 = ₦115,450)
        expect(await remoteLedger.getBalance(), expectedBalanceAfter);

        // 4. Remote transaction log has exactly 1 entry for ₦10,000.00
        final remoteTxs = await remoteLedger.getTransactions();
        expect(remoteTxs.length, 1);
        expect(remoteTxs.first.amount, transferAmount);

        // 5. Remote idempotency record exists for this exact key
        final remoteRecord = await remoteLedger.getRecord(opIdKey.value);
        expect(remoteRecord, isNotNull);
        expect(remoteRecord!.operationId, opId.value);

        // 6. Local wallet balance in SQLite updated to ₦115,450.00
        final walletRepo = container.read(walletRepositoryProvider);
        await walletRepo.refresh();
        await tester.pumpAndSettle();

        expect(find.text('₦115,450.00'), findsOneWidget);

        // ===================================================================
        // STEP 11: REPLAY DEDUPLICATION (HC-IDEMPOTENCY)
        // ===================================================================
        // Trigger sync again to prove no second debit occurs
        final secondSync = await syncCoordinator.synchronize();
        expect(secondSync.succeeded, 0); // Already completed, not re-executed

        // Remote balance is STILL ₦115,450.00 (NO duplicate deduction!)
        expect(await remoteLedger.getBalance(), expectedBalanceAfter);
        expect(await remoteLedger.getTransactions(), hasLength(1));

        // Cleanup
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await db.close();
        container.dispose();
      },
    );
  });
}
