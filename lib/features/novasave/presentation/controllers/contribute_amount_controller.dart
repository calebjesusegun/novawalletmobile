import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/domain/savings_progress.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';

/// State for the Contribution Amount Entry step of NovaSave.
///
/// Implements NSV-009, NSV-010, MNY-003, MNY-006.
/// Visual references: UI-NSV-09, UI-NSV-10.
@immutable
class ContributeAmountState {
  const ContributeAmountState({
    required this.goal,
    this.amount = const Money.zero(),
    this.rawInput = '',
    this.validationError,
    this.spendableBalance = const Money.zero(),
    this.confirmedBalance = const Money.zero(),
    this.isOffline = false,
  });

  /// The target savings goal receiving the contribution.
  final SavingsGoal goal;

  /// The parsed contribution amount entered in integer kobo.
  final Money amount;

  /// The raw text string entered by the user.
  final String rawInput;

  /// Validation error copy if invalid, or null if valid.
  final String? validationError;

  /// Current spendable balance available for new debits (MNY-006).
  final Money spendableBalance;

  /// Headline confirmed balance from cache.
  final Money confirmedBalance;

  /// Whether device is currently offline.
  final bool isOffline;

  bool get hasError => validationError != null && validationError!.isNotEmpty;

  /// Continue is available only when amount is strictly positive, does not exceed spendable
  /// balance, and has no validation errors.
  bool get canContinue =>
      amount.isPositive && !hasError && amount <= spendableBalance;

  /// Computes the projected savings progress model via exact integer kobo arithmetic.
  SavingsProgress get projectedProgress =>
      goal.projectContribution(amount.isPositive ? amount : const Money.zero());

  /// Projected cumulative saved amount if this contribution succeeds.
  Money get projectedSavedAmount => goal.savedAmount + amount;

  /// Projected integer progress percentage (e.g. 40%).
  int get projectedPercentage => projectedProgress.percentage;

  ContributeAmountState copyWith({
    SavingsGoal? goal,
    Money? amount,
    String? rawInput,
    ValueGetter<String?>? validationError,
    Money? spendableBalance,
    Money? confirmedBalance,
    bool? isOffline,
  }) {
    return ContributeAmountState(
      goal: goal ?? this.goal,
      amount: amount ?? this.amount,
      rawInput: rawInput ?? this.rawInput,
      validationError: validationError != null
          ? validationError()
          : this.validationError,
      spendableBalance: spendableBalance ?? this.spendableBalance,
      confirmedBalance: confirmedBalance ?? this.confirmedBalance,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributeAmountState &&
          runtimeType == other.runtimeType &&
          goal == other.goal &&
          amount == other.amount &&
          rawInput == other.rawInput &&
          validationError == other.validationError &&
          spendableBalance == other.spendableBalance &&
          confirmedBalance == other.confirmedBalance &&
          isOffline == other.isOffline;

  @override
  int get hashCode => Object.hash(
    goal,
    amount,
    rawInput,
    validationError,
    spendableBalance,
    confirmedBalance,
    isOffline,
  );
}

/// Controller managing NovaSave contribution amount input and spendable-balance validation.
class ContributeAmountController extends StateNotifier<ContributeAmountState> {
  ContributeAmountController({
    required SavingsGoal goal,
    required Money spendableBalance,
    required Money confirmedBalance,
    required bool isOffline,
  }) : super(
         ContributeAmountState(
           goal: goal,
           spendableBalance: spendableBalance,
           confirmedBalance: confirmedBalance,
           isOffline: isOffline,
         ),
       );

  /// Updates balance projection context.
  void updateProjection({
    required Money spendableBalance,
    required Money confirmedBalance,
  }) {
    state = state.copyWith(
      spendableBalance: spendableBalance,
      confirmedBalance: confirmedBalance,
    );

    if (state.rawInput.isNotEmpty) {
      onAmountChanged(state.rawInput);
    }
  }

  /// Updates offline connectivity state.
  void updateOffline(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  /// Handles amount field text input changes.
  void onAmountChanged(String rawValue) {
    final cleaned = rawValue.trim();
    if (cleaned.isEmpty) {
      state = state.copyWith(
        amount: const Money.zero(),
        rawInput: '',
        validationError: () => null,
      );
      return;
    }

    final parsed = Money.tryParse(cleaned);
    if (parsed == null) {
      state = state.copyWith(
        amount: const Money.zero(),
        rawInput: cleaned,
        validationError: () => 'Enter a valid amount.',
      );
      return;
    }

    if (parsed.isZero || parsed.isNegative) {
      state = state.copyWith(
        amount: parsed,
        rawInput: cleaned,
        validationError: () => 'Enter an amount greater than ₦0.00.',
      );
      return;
    }

    if (parsed > state.spendableBalance) {
      state = state.copyWith(
        amount: parsed,
        rawInput: cleaned,
        validationError: () =>
            'Amount is more than your wallet balance. Enter ${state.spendableBalance.format()} or less.',
      );
      return;
    }

    state = state.copyWith(
      amount: parsed,
      rawInput: cleaned,
      validationError: () => null,
    );
  }

  /// Explicit validation check triggered on submission or field blur.
  void validate() {
    if (state.rawInput.isEmpty || state.amount.isZero) {
      state = state.copyWith(
        validationError: () => 'Enter an amount greater than ₦0.00.',
      );
      return;
    }

    if (state.amount > state.spendableBalance) {
      state = state.copyWith(
        validationError: () =>
            'Amount is more than your wallet balance. Enter ${state.spendableBalance.format()} or less.',
      );
      return;
    }
  }
}

/// Provider family parameterized by [SavingsGoal].
final contributeAmountControllerProvider = StateNotifierProvider.autoDispose
    .family<ContributeAmountController, ContributeAmountState, SavingsGoal>((
      ref,
      goal,
    ) {
      final projection = ref.watch(walletProjectionProvider).asData?.value;
      final connectivity = ref.watch(connectivityStatusProvider);

      final spendable = projection?.spendableBalance ?? const Money.zero();
      final confirmed = projection?.confirmedBalance ?? const Money.zero();
      final isOffline = connectivity == ConnectivityStatus.offline;

      final controller = ContributeAmountController(
        goal: goal,
        spendableBalance: spendable,
        confirmedBalance: confirmed,
        isOffline: isOffline,
      );

      ref.listen(walletProjectionProvider, (_, next) {
        final nextProj = next.asData?.value;
        if (nextProj != null) {
          controller.updateProjection(
            spendableBalance: nextProj.spendableBalance,
            confirmedBalance: nextProj.confirmedBalance,
          );
        }
      });

      ref.listen(connectivityStatusProvider, (_, next) {
        controller.updateOffline(next == ConnectivityStatus.offline);
      });

      return controller;
    });
