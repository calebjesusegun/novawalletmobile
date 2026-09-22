import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';

/// Arguments required to initialize the transfer confirmation step.
@immutable
class TransferConfirmationArgs {
  const TransferConfirmationArgs({
    required this.recipient,
    required this.amount,
  });

  final Recipient recipient;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferConfirmationArgs &&
          other.recipient == recipient &&
          other.amount == amount);

  @override
  int get hashCode => Object.hash(recipient, amount);
}

/// State for the Transfer Confirmation step of Send Money.
///
/// Implements SND-009, SND-010, SND-014, SND-015, ASM-006, ASM-009.
/// Visual references: UI-SND-10, UI-SND-14.
@immutable
class TransferConfirmationState {
  const TransferConfirmationState({
    required this.recipient,
    required this.amount,
    this.spendableBalance = const Money.zero(),
    this.confirmedBalance = const Money.zero(),
    this.isOffline = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.enqueuedOperation,
  });

  /// The verified recipient selected in step 1.
  final Recipient recipient;

  /// The monetary transfer amount in integer kobo (HC-MONEY).
  final Money amount;

  /// Current spendable balance available for new debits.
  final Money spendableBalance;

  /// Headline confirmed balance from cache.
  final Money confirmedBalance;

  /// Whether device is currently offline (UI-SND-14 / SND-014).
  final bool isOffline;

  /// Whether a submission attempt is currently in flight.
  final bool isSubmitting;

  /// Error message if enqueue or submission failed.
  final String? errorMessage;

  /// The persisted financial operation once durably enqueued.
  final FinancialOperation? enqueuedOperation;

  /// Balance after transfer calculated via exact integer kobo (HC-MONEY).
  Money get balanceAfter {
    if (amount > spendableBalance) {
      return const Money.zero();
    }
    return spendableBalance - amount;
  }

  /// Whether the user can tap confirm (prevents double tap while submitting).
  bool get canConfirm => !isSubmitting;

  TransferConfirmationState copyWith({
    Recipient? recipient,
    Money? amount,
    Money? spendableBalance,
    Money? confirmedBalance,
    bool? isOffline,
    bool? isSubmitting,
    String? Function()? errorMessage,
    FinancialOperation? enqueuedOperation,
  }) {
    return TransferConfirmationState(
      recipient: recipient ?? this.recipient,
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
      (other is TransferConfirmationState &&
          other.recipient == recipient &&
          other.amount == amount &&
          other.spendableBalance == spendableBalance &&
          other.confirmedBalance == confirmedBalance &&
          other.isOffline == isOffline &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage &&
          other.enqueuedOperation == enqueuedOperation);

  @override
  int get hashCode => Object.hash(
    recipient,
    amount,
    spendableBalance,
    confirmedBalance,
    isOffline,
    isSubmitting,
    errorMessage,
    enqueuedOperation,
  );
}

/// Controller for the Transfer Confirmation step.
///
/// Guarantees:
/// - HC-IDEMPOTENCY: Generates a stable OperationId and IdempotencyKey for this logical transfer.
/// - HC-OFFLINE-DURABILITY & SND-015: Durably persists the operation in [OperationRepository]
///   before completing.
/// - Prevents accidental double submission via atomic submitting guard.
class TransferConfirmationController
    extends
        AutoDisposeFamilyNotifier<
          TransferConfirmationState,
          TransferConfirmationArgs
        > {
  DateTime Function() _clock = () => DateTime.now().toUtc();

  @visibleForTesting
  void setClock(DateTime Function() clock) {
    _clock = clock;
  }

  @override
  TransferConfirmationState build(TransferConfirmationArgs arg) {
    final connectivity = ref.watch(connectivityStatusProvider);
    final walletAsync = ref.watch(walletProjectionProvider);

    final isOffline = connectivity == ConnectivityStatus.offline;
    final spendable = walletAsync.value?.spendableBalance ?? const Money.zero();
    final confirmed = walletAsync.value?.confirmedBalance ?? const Money.zero();

    return TransferConfirmationState(
      recipient: arg.recipient,
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

  /// Confirms the transfer, durably creating and enqueuing the [FinancialOperation].
  ///
  /// Implements:
  /// - SND-010 & ASM-006: Generates one stable operation ID and one stable idempotency key.
  /// - SND-015 & HC-OFFLINE-DURABILITY: Persists to [OperationRepository] before reporting saved.
  /// - Double-tap protection: Rejects concurrent confirm invocations if already submitting.
  Future<FinancialOperation?> confirmTransfer() async {
    // Double-tap protection: guard against concurrent duplicate submissions
    if (state.isSubmitting) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: () => null);

    try {
      final operationRepo = ref.read(operationRepositoryProvider);
      final syncCoordinator = ref.read(syncCoordinatorProvider);

      // Generate stable identities for this logical transfer (HC-IDEMPOTENCY)
      final opId = OperationId.generate();
      final idempotencyKey = IdempotencyKey.fromOperationId(
        opId,
        prefix: 'idem_send_',
      );

      final payload = SendMoneyPayload(
        recipientAccountNumber: state.recipient.accountNumber,
        recipientName: state.recipient.name,
        bankName: state.recipient.bankName,
        amount: state.amount,
      );

      // Durably persist the operation (HC-OFFLINE-DURABILITY / SND-015)
      final operation = await operationRepo.enqueueSendMoney(
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
        errorMessage: () => 'Failed to save transfer: $e',
      );
      rethrow;
    }
  }
}

/// Riverpod family provider for [TransferConfirmationController].
final transferConfirmationControllerProvider = NotifierProvider.autoDispose
    .family<
      TransferConfirmationController,
      TransferConfirmationState,
      TransferConfirmationArgs
    >(TransferConfirmationController.new);
