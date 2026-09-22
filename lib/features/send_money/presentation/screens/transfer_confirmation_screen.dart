import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/cards/app_key_value_row.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';
import 'package:novawallet/features/send_money/presentation/controllers/transfer_confirmation_controller.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// Screen for the Transfer Confirmation step of Send Money.
///
/// Implements:
/// - SND-009: Show transfer confirmation (UI-SND-10)
/// - SND-010: Create one stable operation identity/idempotency key
/// - SND-014: Offline confirmation explains operation will be saved (UI-SND-14)
/// - SND-015: Offline send is durably persisted before UI reports saved
/// - ASM-006, ASM-009: Stable identities and offline durability
class TransferConfirmationScreen extends ConsumerWidget {
  const TransferConfirmationScreen({
    super.key,
    required this.recipient,
    required this.amount,
    required this.onBack,
    required this.onTransferSubmitted,
  });

  final Recipient recipient;
  final Money amount;
  final VoidCallback onBack;
  final ValueChanged<FinancialOperation> onTransferSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TransferConfirmationArgs(recipient: recipient, amount: amount);
    final state = ref.watch(transferConfirmationControllerProvider(args));
    final controller = ref.read(
      transferConfirmationControllerProvider(args).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('confirmation_back_button'),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Back to amount entry',
          onPressed: onBack,
        ),
        title: Text(
          'Confirm Transfer',
          style: AppTypography.titleBold18.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.insetsAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Offline explanation notification (SND-014 / UI-SND-14)
              if (state.isOffline) ...[
                AppSystemNotification.offline(
                  key: const Key('confirmation_offline_banner'),
                  message: "You're offline. Transfer will be queued securely and sent when connected.",
                ),
                AppSpacing.gapVertical16,
              ],

              // Error notification if submission failed
              if (state.errorMessage != null) ...[
                AppSystemNotification(
                  key: const Key('confirmation_error_banner'),
                  message: state.errorMessage!,
                  type: SystemNotificationType.syncFailure,
                ),
                AppSpacing.gapVertical16,
              ],

              // Details card with summary rows (UI-SND-10 / DSN-012)
              AppCard(
                key: const Key('confirmation_details_card'),
                padding: AppSpacing.insetsAll16,
                semanticLabel: 'Transfer confirmation details',
                child: Column(
                  children: [
                    AppKeyValueRow(
                      key: const Key('confirmation_recipient_row'),
                      label: 'Recipient',
                      value: state.recipient.name,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('confirmation_account_row'),
                      label: 'Account',
                      value:
                          '${state.recipient.accountNumber} • ${state.recipient.bankName}',
                      isBoldValue: false,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('confirmation_amount_row'),
                      label: 'Amount',
                      value: state.amount.format(),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    const AppKeyValueRow(
                      key: Key('confirmation_source_row'),
                      label: 'Source',
                      value: 'Main Wallet',
                      isBoldValue: false,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('confirmation_balance_after_row'),
                      label: 'Balance after transfer',
                      value: state.balanceAfter.format(),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVertical24,

              // Action button with double-tap protection and loading state
              Semantics(
                button: true,
                label: state.isOffline
                    ? 'Save transfer offline'
                    : 'Confirm and send transfer',
                child: AppButton(
                  key: const Key('confirm_transfer_button'),
                  label: state.isOffline
                      ? 'Save & Send Later'
                      : 'Send ${state.amount.format()}',
                  isLoading: state.isSubmitting,
                  onPressed: state.canConfirm
                      ? () async {
                          final operation = await controller.confirmTransfer();
                          if (operation != null) {
                            onTransferSubmitted(operation);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
