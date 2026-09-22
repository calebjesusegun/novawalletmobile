import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/transfer_confirmation_controller.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

class FakeOperationRepository implements OperationRepository {
  final List<FinancialOperation> enqueuedOperations = [];
  bool shouldThrowOnEnqueue = false;

  @override
  Future<FinancialOperation> enqueue(FinancialOperation operation) async {
    if (shouldThrowOnEnqueue) {
      throw Exception('Database write failed');
    }
    enqueuedOperations.add(operation);
    return operation;
  }

  @override
  Future<FinancialOperation> enqueueSendMoney({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required SendMoneyPayload payload,
    DateTime? createdAt,
  }) async {
    final op = FinancialOperation.send(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
    return enqueue(op);
  }

  @override
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) => throw UnimplementedError();

  @override
  Future<bool> claim(OperationId id, {DateTime? at}) =>
      throw UnimplementedError();

  @override
  Future<List<FinancialOperation>> getActiveOperations() async => [];

  @override
  Future<List<FinancialOperation>> getAllOperations() async =>
      enqueuedOperations;

  @override
  Future<FinancialOperation?> getOperationById(OperationId id) async =>
      enqueuedOperations.cast<FinancialOperation?>().firstWhere(
        (op) => op?.id == id,
        orElse: () => null,
      );

  @override
  Future<FinancialOperation?> getOperationByIdempotencyKey(
    IdempotencyKey key,
  ) async => enqueuedOperations.cast<FinancialOperation?>().firstWhere(
    (op) => op?.idempotencyKey == key,
    orElse: () => null,
  );

  @override
  Future<List<FinancialOperation>> getPendingOperations() async =>
      enqueuedOperations
          .where((op) => op.status == OperationStatus.pending)
          .toList();

  @override
  Future<FinancialOperation> markCompleted(
    OperationId id, {
    required String remoteReference,
    DateTime? at,
  }) => throw UnimplementedError();

  @override
  Future<FinancialOperation> markFailed(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) => throw UnimplementedError();

  @override
  Future<FinancialOperation> markPendingWithError(
    OperationId id, {
    required SyncError error,
    DateTime? at,
  }) => throw UnimplementedError();

  @override
  Future<int> recoverInterrupted() async => 0;

  @override
  Future<void> update(FinancialOperation operation) async {}

  @override
  Stream<List<FinancialOperation>> watchActiveOperations() =>
      Stream.value(enqueuedOperations);

  @override
  Stream<List<FinancialOperation>> watchPendingOperations() =>
      Stream.value(enqueuedOperations);
}

class FakeSyncCoordinator implements SyncCoordinator {
  int syncTriggeredCount = 0;

  @override
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    syncTriggeredCount++;
    return SyncRunResult.empty(trigger);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group(
    'TransferConfirmationController (T-SND-003, SND-009, SND-010, SND-015)',
    () {
      const testRecipient = Recipient(
        accountNumber: '0123456789',
        name: 'John Doe',
        bankName: 'NovaBank',
      );
      final testAmount = Money.fromNaira(10000); // ₦10,000.00
      final args = TransferConfirmationArgs(
        recipient: testRecipient,
        amount: testAmount,
      );

      late FakeOperationRepository fakeRepo;
      late FakeSyncCoordinator fakeSync;

      setUp(() {
        fakeRepo = FakeOperationRepository();
        fakeSync = FakeSyncCoordinator();
      });

      ProviderContainer createContainer({
        ConnectivityStatus connectivity = ConnectivityStatus.online,
        Money spendableBalance = const Money.fromKobo(12545000), // ₦125,450.00
        Money confirmedBalance = const Money.fromKobo(12545000),
      }) {
        return ProviderContainer(
          overrides: [
            connectivityStatusProvider.overrideWithValue(connectivity),
            operationRepositoryProvider.overrideWithValue(fakeRepo),
            syncCoordinatorProvider.overrideWithValue(fakeSync),
            walletProjectionProvider.overrideWithValue(
              AsyncValue.data(
                WalletProjection(
                  confirmedBalance: confirmedBalance,
                  spendableBalance: spendableBalance,
                  pendingDebitTotal: confirmedBalance - spendableBalance,
                  lastUpdatedAt: DateTime.utc(2026, 3, 30),
                  activities: const [],
                  pendingOperations: const [],
                ),
              ),
            ),
          ],
        );
      }

      test(
        'initializes state with exact money balances and offline status',
        () {
          final container = createContainer(
            connectivity: ConnectivityStatus.online,
            spendableBalance: const Money.fromKobo(12545000),
          );
          final state = container.read(
            transferConfirmationControllerProvider(args),
          );

          expect(state.recipient, testRecipient);
          expect(state.amount, testAmount);
          expect(state.spendableBalance, const Money.fromKobo(12545000));
          expect(
            state.balanceAfter,
            const Money.fromKobo(11545000),
          ); // ₦115,450.00
          expect(state.isOffline, isFalse);
          expect(state.isSubmitting, isFalse);
          expect(state.canConfirm, isTrue);
          expect(state.errorMessage, isNull);
          expect(state.enqueuedOperation, isNull);
        },
      );

      test('reflects offline status when connectivity is offline', () {
        final container = createContainer(
          connectivity: ConnectivityStatus.offline,
        );
        final state = container.read(
          transferConfirmationControllerProvider(args),
        );

        expect(state.isOffline, isTrue);
      });

      test('confirmTransfer generates stable IDs, enqueues to repository and triggers sync when online', () async {
        final container = createContainer(
          connectivity: ConnectivityStatus.online,
        );
        final controller = container.read(
          transferConfirmationControllerProvider(args).notifier,
        );

        final fixedTime = DateTime.utc(2026, 3, 30, 10, 0, 0);
        controller.setClock(() => fixedTime);

        final operation = await controller.confirmTransfer();

        expect(operation, isNotNull);
        expect(operation!.id.value.isNotEmpty, isTrue);
        expect(operation.idempotencyKey.value.startsWith('idem_send_'), isTrue);
        expect(operation.type, OperationType.send);
        expect(operation.status, OperationStatus.pending);
        expect(operation.createdAt, fixedTime);

        final payload = operation.payload as SendMoneyPayload;
        expect(payload.recipientAccountNumber, '0123456789');
        expect(payload.recipientName, 'John Doe');
        expect(payload.amount, testAmount);

        // Verify durably enqueued in repo (HC-OFFLINE-DURABILITY / SND-015)
        expect(fakeRepo.enqueuedOperations.length, 1);
        expect(fakeRepo.enqueuedOperations.first.id, operation.id);

        // Verify online sync triggered
        expect(fakeSync.syncTriggeredCount, 1);

        final finalState = container.read(
          transferConfirmationControllerProvider(args),
        );
        expect(finalState.isSubmitting, isFalse);
        expect(finalState.enqueuedOperation, operation);
        expect(finalState.errorMessage, isNull);
      });

      test('confirmTransfer when offline durably enqueues without triggering sync immediately', () async {
        final container = createContainer(
          connectivity: ConnectivityStatus.offline,
        );
        final controller = container.read(
          transferConfirmationControllerProvider(args).notifier,
        );

        final operation = await controller.confirmTransfer();

        expect(operation, isNotNull);
        expect(fakeRepo.enqueuedOperations.length, 1);
        // When offline, does not call syncCoordinator.synchronize
        expect(fakeSync.syncTriggeredCount, 0);
      });

      test('double-tap protection: concurrent confirmTransfer calls only execute once', () async {
        final container = createContainer();
        final controller = container.read(
          transferConfirmationControllerProvider(args).notifier,
        );

        // Trigger two concurrent invocations
        final future1 = controller.confirmTransfer();
        final future2 = controller.confirmTransfer();

        final results = await Future.wait([future1, future2]);

        // Exactly one succeeds, the other is guarded and returns null
        expect(fakeRepo.enqueuedOperations.length, 1);
        expect(results.where((op) => op != null).length, 1);
      });

      test('enqueue error sets errorMessage and rethrows', () async {
        fakeRepo.shouldThrowOnEnqueue = true;
        final container = createContainer();
        final controller = container.read(
          transferConfirmationControllerProvider(args).notifier,
        );

        await expectLater(controller.confirmTransfer(), throwsException);

        final state = container.read(
          transferConfirmationControllerProvider(args),
        );
        expect(state.isSubmitting, isFalse);
        expect(state.errorMessage, contains('Failed to save transfer'));
        expect(state.enqueuedOperation, isNull);
      });
    },
  );
}
