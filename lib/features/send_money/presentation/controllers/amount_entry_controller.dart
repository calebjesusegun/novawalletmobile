import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';

/// State for the Amount Entry step of Send Money.
///
/// Implements SND-005, SND-006, SND-007, SND-008, MNY-003, MNY-006.
/// Visual references: UI-SND-05 through UI-SND-09.
@immutable
class AmountEntryState {
  const AmountEntryState({
    required this.recipient,
    this.amount = const Money.zero(),
    this.rawInput = '',
    this.validationError,
    this.spendableBalance = const Money.zero(),
    this.confirmedBalance = const Money.zero(),
    this.isOffline = false,
    this.lastUpdatedAt,
  });

  /// The verified recipient selected in step 1.
  final Recipient recipient;

  /// The parsed monetary amount entered in integer kobo.
  final Money amount;

  /// The raw text string entered by the user.
  final String rawInput;

  /// Validation error copy if invalid, or null if valid.
  final String? validationError;

  /// Current spendable balance available for new debits (MNY-006).
  final Money spendableBalance;

  /// Headline confirmed balance from cache.
  final Money confirmedBalance;

  /// Whether device is currently offline (SND-008 / UI-SND-09).
  final bool isOffline;

  /// Timestamp of the last balance update.
  final DateTime? lastUpdatedAt;

  bool get hasError => validationError != null && validationError!.isNotEmpty;

  /// Continue is available only when amount is positive, does not exceed spendable
  /// balance, and has no validation errors.
  bool get canContinue =>
      amount.isPositive && !hasError && amount <= spendableBalance;

  /// Computes the exact balance after transfer preview using integer-kobo arithmetic.
  Money? get balanceAfter {
    if (!amount.isPositive || hasError || amount > spendableBalance) {
      return null;
    }
    return spendableBalance - amount;
  }

  AmountEntryState copyWith({
    Recipient? recipient,
    Money? amount,
    String? rawInput,
    String? Function()? validationError,
    Money? spendableBalance,
    Money? confirmedBalance,
    bool? isOffline,
    DateTime? lastUpdatedAt,
  }) {
    return AmountEntryState(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      rawInput: rawInput ?? this.rawInput,
      validationError: validationError != null
          ? validationError()
          : this.validationError,
      spendableBalance: spendableBalance ?? this.spendableBalance,
      confirmedBalance: confirmedBalance ?? this.confirmedBalance,
      isOffline: isOffline ?? this.isOffline,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmountEntryState &&
          runtimeType == other.runtimeType &&
          recipient == other.recipient &&
          amount == other.amount &&
          rawInput == other.rawInput &&
          validationError == other.validationError &&
          spendableBalance == other.spendableBalance &&
          confirmedBalance == other.confirmedBalance &&
          isOffline == other.isOffline &&
          lastUpdatedAt == other.lastUpdatedAt;

  @override
  int get hashCode => Object.hash(
    recipient,
    amount,
    rawInput,
    validationError,
    spendableBalance,
    confirmedBalance,
    isOffline,
    lastUpdatedAt,
  );
}

/// Controller managing amount input and spendable-balance validation.
class AmountEntryController extends StateNotifier<AmountEntryState> {
  AmountEntryController({
    required Recipient recipient,
    required Money spendableBalance,
    required Money confirmedBalance,
    required bool isOffline,
    DateTime? lastUpdatedAt,
  }) : super(
         AmountEntryState(
           recipient: recipient,
           spendableBalance: spendableBalance,
           confirmedBalance: confirmedBalance,
           isOffline: isOffline,
           lastUpdatedAt: lastUpdatedAt,
         ),
       );

  /// Updates balance projection context.
  void updateProjection({
    required Money spendableBalance,
    required Money confirmedBalance,
    DateTime? lastUpdatedAt,
  }) {
    state = state.copyWith(
      spendableBalance: spendableBalance,
      confirmedBalance: confirmedBalance,
      lastUpdatedAt: lastUpdatedAt,
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
        validationError: () => 'Amount must be greater than zero.',
      );
      return;
    }

    if (parsed > state.spendableBalance) {
      state = state.copyWith(
        amount: parsed,
        rawInput: cleaned,
        validationError: () => 'Amount exceeds available balance.',
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
        validationError: () => 'Amount must be greater than zero.',
      );
      return;
    }

    if (state.amount > state.spendableBalance) {
      state = state.copyWith(
        validationError: () => 'Amount exceeds available balance.',
      );
      return;
    }
  }
}

/// Provider family parameterized by recipient.
final amountEntryControllerProvider = StateNotifierProvider.autoDispose
    .family<AmountEntryController, AmountEntryState, Recipient>((
      ref,
      recipient,
    ) {
      final projection = ref.watch(walletProjectionProvider).asData?.value;
      final connectivity = ref.watch(connectivityStatusProvider);

      final spendable = projection?.spendableBalance ?? const Money.zero();
      final confirmed = projection?.confirmedBalance ?? const Money.zero();
      final isOffline = connectivity == ConnectivityStatus.offline;
      final lastUpdated = projection?.lastUpdatedAt;

      final controller = AmountEntryController(
        recipient: recipient,
        spendableBalance: spendable,
        confirmedBalance: confirmed,
        isOffline: isOffline,
        lastUpdatedAt: lastUpdated,
      );

      ref.listen(walletProjectionProvider, (_, next) {
        final nextProj = next.asData?.value;
        if (nextProj != null) {
          controller.updateProjection(
            spendableBalance: nextProj.spendableBalance,
            confirmedBalance: nextProj.confirmedBalance,
            lastUpdatedAt: nextProj.lastUpdatedAt,
          );
        }
      });

      ref.listen(connectivityStatusProvider, (_, next) {
        controller.updateOffline(next == ConnectivityStatus.offline);
      });

      return controller;
    });
