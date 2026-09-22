import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/domain/savings_progress.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';

/// Arguments required to initialize the contribution confirmation step.
@immutable
class ContributionConfirmationArgs {
  const ContributionConfirmationArgs({
    required this.goal,
    required this.amount,
  });

  final SavingsGoal goal;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionConfirmationArgs &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(goal, amount);
}

/// State for the Contribution Confirmation step of NovaSave.
///
/// Implements:
/// - NSV-011: Show contribution confirmation (UI-NSV-11).
/// - NSV-012: Create one stable operation identity/idempotency key (ASM-011, ASM-013).
/// - NSV-016: Offline confirmation explains contribution will be saved (UI-NSV-16).
/// - NSV-017: Offline Contribution is durably persisted before UI reports it saved.
/// - HC-MONEY: Exact integer-kobo arithmetic.
/// - HC-IDEMPOTENCY: Stable operation identity and idempotency key.
/// - HC-OFFLINE-DURABILITY: Durable local persistence before acknowledging.
@immutable
class ContributionConfirmationState {
  const ContributionConfirmationState({
    required this.goal,
    required this.amount,
    this.spendableBalance = const Money.zero(),
    this.confirmedBalance = const Money.zero(),
    this.isOffline = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.enqueuedOperation,
  });

  final SavingsGoal goal;
  final Money amount;
  final Money spendableBalance;
  final Money confirmedBalance;
  final bool isOffline;
  final bool isSubmitting;
  final String? errorMessage;
  final FinancialOperation? enqueuedOperation;

  /// Goal balance after contribution.
  Money get goalBalanceAfter => goal.savedAmount + amount;

  /// Projected savings progress.
  SavingsProgress get projectedProgress => goal.projectContribution(amount);

  /// Whether user can tap confirm.
  bool get canSubmit =>
      !isSubmitting && amount.isPositive && amount <= spendableBalance;

  ContributionConfirmationState copyWith({
    SavingsGoal? goal,
    Money? amount,
    Money? spendableBalance,
    Money? confirmedBalance,
    bool? isOffline,
    bool? isSubmitting,
    ValueGetter<String?>? errorMessage,
    FinancialOperation? enqueuedOperation,
  }) {
    return ContributionConfirmationState(
      goal: goal ?? this.goal,
      amount: amount ?? this.amount,
      spendableBalance: spendableBalance ?? this.spendableBalance,
      confirmedBalance: confirmedBalance ?? this.confirmedBalance,
      isOffline: isOffline ?? this.isOffline,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      enqueuedOperation: enqueuedOperation ?? this.enqueuedOperation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionConfirmationState &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          amount == other.amount &&
          spendableBalance == other.spendableBalance &&
          confirmedBalance == other.confirmedBalance &&
          isOffline == other.isOffline &&
          isSubmitting == other.isSubmitting &&
          errorMessage == other.errorMessage &&
          enqueuedOperation == other.enqueuedOperation;

  @override
  int get hashCode => Object.hash(
    goal,
    amount,
    spendableBalance,
    confirmedBalance,
    isOffline,
    isSubmitting,
    errorMessage,
    enqueuedOperation,
  );
}

/// Controller for the Contribution Confirmation step.
///
/// Guarantees:
/// - HC-IDEMPOTENCY: Generates a stable OperationId and IdempotencyKey for this logical contribution.
/// - HC-OFFLINE-DURABILITY & NSV-017: Durably persists the operation in [OperationRepository]
///   before completing.
/// - Double-tap protection: Rejects concurrent confirm invocations if already submitting.
class ContributionConfirmationController
    extends
        AutoDisposeFamilyNotifier<
          ContributionConfirmationState,
          ContributionConfirmationArgs
        > {
  DateTime Function() _clock = () => DateTime.now().toUtc();

  @visibleForTesting
  void setClock(DateTime Function() clock) {
    _clock = clock;
  }

  @override
  ContributionConfirmationState build(ContributionConfirmationArgs arg) {
    final connectivity = ref.watch(connectivityStatusProvider);
    final walletAsync = ref.watch(walletProjectionProvider);

    final isOffline = connectivity == ConnectivityStatus.offline;
    final spendable = walletAsync.value?.spendableBalance ?? const Money.zero();
    final confirmed = walletAsync.value?.confirmedBalance ?? const Money.zero();

    return ContributionConfirmationState(
      goal: arg.goal,
      amount: arg.amount,
      spendableBalance: spendable,
      confirmedBalance: confirmed,
      isOffline: isOffline,
    );
  }

  /// Updates projection values directly (useful for testing or fine-grained updates).
  void updateProjection({
    required Money spendableBalance,
    required Money confirmedBalance,
  }) {
    state = state.copyWith(
      spendableBalance: spendableBalance,
      confirmedBalance: confirmedBalance,
    );
  }

  /// Updates offline status directly (useful for testing).
  void updateOffline(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  /// Confirms the contribution, durably creating and enqueuing the [FinancialOperation].
  ///
  /// Implements:
  /// - NSV-012 & ASM-011: Generates one stable operation ID and one stable idempotency key.
  /// - NSV-017 & HC-OFFLINE-DURABILITY: Persists to [OperationRepository] before reporting saved.
  /// - Double-tap protection: Rejects concurrent confirm invocations if already submitting.
  Future<FinancialOperation?> confirmContribution() async {
    if (state.isSubmitting) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    try {
      final operationRepo = ref.read(operationRepositoryProvider);
      final syncCoordinator = ref.read(syncCoordinatorProvider);

      // Generate stable identities for this logical contribution (HC-IDEMPOTENCY)
      final opId = OperationId.generate();
      final idempotencyKey = IdempotencyKey.fromOperationId(
        opId,
        prefix: 'idem_nsc_',
      );

      final payload = ContributionPayload(
        goalId: state.goal.id,
        goalName: state.goal.name,
        amount: state.amount,
      );

      // Durably persist the operation (HC-OFFLINE-DURABILITY / NSV-017)
      final operation = await operationRepo.enqueueContribution(
        id: opId,
        idempotencyKey: idempotencyKey,
        payload: payload,
        createdAt: _clock(),
      );

      // If online, trigger centralized sync coordinator immediately (HC-SYNC)
      if (!state.isOffline) {
        unawaited(syncCoordinator.synchronize(trigger: SyncTrigger.manual));
      }

      state = state.copyWith(isSubmitting: false, enqueuedOperation: operation);

      return operation;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => 'Failed to save contribution: $e',
      );
      rethrow;
    }
  }
}

/// Riverpod family provider for [ContributionConfirmationController].
final contributionConfirmationControllerProvider = NotifierProvider.autoDispose
    .family<
      ContributionConfirmationController,
      ContributionConfirmationState,
      ContributionConfirmationArgs
    >(ContributionConfirmationController.new);
