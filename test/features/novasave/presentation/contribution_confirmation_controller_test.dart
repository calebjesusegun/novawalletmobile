import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/controllers/contribution_confirmation_controller.dart';
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
  }) => throw UnimplementedError();

  @override
  Future<FinancialOperation> enqueueContribution({
    required OperationId id,
    required IdempotencyKey idempotencyKey,
    required ContributionPayload payload,
    DateTime? createdAt,
  }) async {
    final op = FinancialOperation.contribution(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
    return enqueue(op);
  }

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
  Stream<FinancialOperation?> watchOperationById(OperationId id) =>
      Stream.value(
        enqueuedOperations.cast<FinancialOperation?>().firstWhere(
          (op) => op?.id == id,
          orElse: () => null,
        ),
      );

  @override
  Stream<List<FinancialOperation>> watchPendingOperations() =>
      Stream.value(enqueuedOperations);
}

class FakeSyncCoordinator implements SyncCoordinator {
  int syncTriggeredCount = 0;
  SyncTrigger? lastTrigger;

  @override
  Future<SyncRunResult> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    syncTriggeredCount++;
    lastTrigger = trigger;
    return SyncRunResult.empty(trigger);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeOperationRepository fakeRepo;
  late FakeSyncCoordinator fakeSync;

  final testGoal = SavingsGoal(
    id: 'goal_car_123',
    name: 'Car insurance',
    targetAmount: const Money.fromKobo(10000000), // ₦100,000.00
    savedAmount: const Money.fromKobo(2000000), // ₦20,000.00
    targetDate: DateTime.utc(2027, 1, 1),
  );

  const testAmount = Money.fromKobo(500000); // ₦5,000.00

  final testArgs = ContributionConfirmationArgs(
    goal: testGoal,
    amount: testAmount,
  );

  setUp(() {
    fakeRepo = FakeOperationRepository();
    fakeSync = FakeSyncCoordinator();
  });

  ProviderContainer createContainer({
    ConnectivityStatus connectivity = ConnectivityStatus.online,
    Money spendableBalance = const Money.fromKobo(5000000), // ₦50,000.00
    Money confirmedBalance = const Money.fromKobo(5000000),
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

  group('ContributionConfirmationController', () {
    test('initializes with goal, amount, and wallet balance', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(
        contributionConfirmationControllerProvider(testArgs),
      );

      expect(state.goal, equals(testGoal));
      expect(state.amount, equals(testAmount));
      expect(state.spendableBalance, equals(const Money.fromKobo(5000000)));
      expect(state.isOffline, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.canSubmit, isTrue);
      expect(state.goalBalanceAfter, equals(const Money.fromKobo(2500000)));
      expect(state.projectedProgress.percentage, equals(25));
    });

    test('initializes as offline when connectivity is offline (NSV-016)', () {
      final container = createContainer(
        connectivity: ConnectivityStatus.offline,
      );
      addTearDown(container.dispose);

      final state = container.read(
        contributionConfirmationControllerProvider(testArgs),
      );

      expect(state.isOffline, isTrue);
      expect(state.canSubmit, isTrue);
    });

    test('canSubmit is false when amount exceeds spendable balance', () {
      final container = createContainer(
        spendableBalance: const Money.fromKobo(200000), // less than ₦5,000
      );
      addTearDown(container.dispose);

      final state = container.read(
        contributionConfirmationControllerProvider(testArgs),
      );

      expect(state.canSubmit, isFalse);
    });

    test('confirmContribution generates stable ID, idem_nsc_ key, and durably enqueues (NSV-012, NSV-017, HC-MONEY, HC-IDEMPOTENCY)', () async {
      final container = createContainer(
        connectivity: ConnectivityStatus.offline,
      );
      addTearDown(container.dispose);

      final controller = container.read(
        contributionConfirmationControllerProvider(testArgs).notifier,
      );
      final fixedTime = DateTime.utc(2026, 9, 22, 12, 0, 0);
      controller.setClock(() => fixedTime);

      final op = await controller.confirmContribution();

      expect(op, isNotNull);
      expect(op!.type, equals(OperationType.contribution));
      expect(op.idempotencyKey.value, startsWith('idem_nsc_'));
      expect(op.createdAt, equals(fixedTime));
      expect(op.status, equals(OperationStatus.pending));

      // Verify payload integrity (HC-MONEY)
      final payload = op.payload as ContributionPayload;
      expect(payload.goalId, equals('goal_car_123'));
      expect(payload.goalName, equals('Car insurance'));
      expect(payload.amount, equals(testAmount));
      expect(payload.amount.kobo, equals(500000)); // integer kobo exactness

      // Verify durable local persistence (HC-OFFLINE-DURABILITY / NSV-017)
      expect(fakeRepo.enqueuedOperations.length, equals(1));
      expect(fakeRepo.enqueuedOperations.first.id, equals(op.id));

      // When offline, centralized sync coordinator should NOT be triggered
      expect(fakeSync.syncTriggeredCount, equals(0));
    });

    test('confirmContribution online triggers sync coordinator immediately (HC-SYNC)', () async {
      final container = createContainer(
        connectivity: ConnectivityStatus.online,
      );
      addTearDown(container.dispose);

      final controller = container.read(
        contributionConfirmationControllerProvider(testArgs).notifier,
      );

      final op = await controller.confirmContribution();

      expect(op, isNotNull);
      expect(fakeRepo.enqueuedOperations.length, equals(1));
      expect(fakeSync.syncTriggeredCount, equals(1));
      expect(fakeSync.lastTrigger, equals(SyncTrigger.manual));
    });

    test('rejects double-tap during confirm submission', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        contributionConfirmationControllerProvider(testArgs).notifier,
      );

      // Start first confirm
      final future1 = controller.confirmContribution();
      // Attempt second confirm immediately
      final future2 = controller.confirmContribution();

      final results = await Future.wait([future1, future2]);

      expect(results[0], isNotNull);
      expect(results[1], isNull);
      expect(fakeRepo.enqueuedOperations.length, equals(1));
    });

    test('handles persistence error gracefully', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      fakeRepo.shouldThrowOnEnqueue = true;

      final controller = container.read(
        contributionConfirmationControllerProvider(testArgs).notifier,
      );

      await expectLater(controller.confirmContribution(), throwsException);

      final state = container.read(
        contributionConfirmationControllerProvider(testArgs),
      );
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, contains('Failed to save contribution'));
    });
  });
}
