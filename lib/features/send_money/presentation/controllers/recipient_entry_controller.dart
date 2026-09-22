import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/features/send_money/data/send_money_providers.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/domain/recipient_directory.dart';

/// Status of recipient resolution.
enum RecipientResolutionStatus { idle, resolving, resolved, invalid }

/// State for the recipient entry step of Send Money.
///
/// Implements SND-001, SND-002, SND-003, SND-004.
@immutable
class RecipientEntryState {
  const RecipientEntryState({
    this.accountNumber = '',
    this.status = RecipientResolutionStatus.idle,
    this.resolvedRecipient,
    this.errorMessage,
  });

  final String accountNumber;
  final RecipientResolutionStatus status;
  final Recipient? resolvedRecipient;
  final String? errorMessage;

  bool get canContinue =>
      status == RecipientResolutionStatus.resolved &&
      resolvedRecipient != null &&
      (errorMessage == null || errorMessage!.isEmpty);

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  RecipientEntryState copyWith({
    String? accountNumber,
    RecipientResolutionStatus? status,
    Recipient? Function()? resolvedRecipient,
    String? Function()? errorMessage,
  }) {
    return RecipientEntryState(
      accountNumber: accountNumber ?? this.accountNumber,
      status: status ?? this.status,
      resolvedRecipient: resolvedRecipient != null
          ? resolvedRecipient()
          : this.resolvedRecipient,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipientEntryState &&
          runtimeType == other.runtimeType &&
          accountNumber == other.accountNumber &&
          status == other.status &&
          resolvedRecipient == other.resolvedRecipient &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(accountNumber, status, resolvedRecipient, errorMessage);
}

/// Controller managing recipient input, validation, and resolution.
class RecipientEntryController extends StateNotifier<RecipientEntryState> {
  RecipientEntryController(this._directory)
    : super(const RecipientEntryState());

  final RecipientDirectory _directory;

  /// Handles user typing in the account number field.
  void onAccountNumberChanged(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) {
      state = const RecipientEntryState();
      return;
    }

    // Reset error and previous resolution while typing
    state = state.copyWith(
      accountNumber: sanitized,
      status: RecipientResolutionStatus.idle,
      resolvedRecipient: () => null,
      errorMessage: () => null,
    );

    // Automatically resolve when a complete 10-digit number is reached
    if (sanitized.length == 10 && RegExp(r'^\d{10}$').hasMatch(sanitized)) {
      resolveRecipient(sanitized);
    }
  }

  /// Explicitly triggers validation and resolution for the given account number.
  Future<void> resolveRecipient(String accountNumber) async {
    final sanitized = accountNumber.trim().replaceAll(RegExp(r'\s+'), '');

    if (sanitized.isEmpty) {
      state = state.copyWith(
        accountNumber: '',
        status: RecipientResolutionStatus.invalid,
        resolvedRecipient: () => null,
        errorMessage: () => 'Enter who you are sending to.',
      );
      return;
    }

    if (sanitized.length != 10 || !RegExp(r'^\d{10}$').hasMatch(sanitized)) {
      state = state.copyWith(
        accountNumber: sanitized,
        status: RecipientResolutionStatus.invalid,
        resolvedRecipient: () => null,
        errorMessage: () => 'Enter a valid 10-digit account number.',
      );
      return;
    }

    state = state.copyWith(
      accountNumber: sanitized,
      status: RecipientResolutionStatus.resolving,
      errorMessage: () => null,
    );

    final recipient = await _directory.resolveRecipient(sanitized);
    if (recipient != null) {
      state = state.copyWith(
        accountNumber: sanitized,
        status: RecipientResolutionStatus.resolved,
        resolvedRecipient: () => recipient,
        errorMessage: () => null,
      );
    } else {
      state = state.copyWith(
        accountNumber: sanitized,
        status: RecipientResolutionStatus.invalid,
        resolvedRecipient: () => null,
        errorMessage: () =>
            'Recipient not found. Enter a valid account number.',
      );
    }
  }

  /// Validates input when user attempts to proceed without automatic resolution.
  void validateAndSubmit({void Function(Recipient recipient)? onContinue}) {
    final sanitized = state.accountNumber.trim();
    if (sanitized.isEmpty) {
      state = state.copyWith(
        status: RecipientResolutionStatus.invalid,
        resolvedRecipient: () => null,
        errorMessage: () => 'Enter who you are sending to.',
      );
      return;
    }

    if (state.status == RecipientResolutionStatus.resolved &&
        state.resolvedRecipient != null) {
      onContinue?.call(state.resolvedRecipient!);
    } else {
      resolveRecipient(sanitized);
    }
  }

  /// Clears the input and resets state.
  void clear() {
    state = const RecipientEntryState();
  }
}

/// Provider for the recipient entry controller.
final recipientEntryControllerProvider =
    StateNotifierProvider.autoDispose<
      RecipientEntryController,
      RecipientEntryState
    >((ref) {
      final directory = ref.watch(recipientDirectoryProvider);
      return RecipientEntryController(directory);
    });
