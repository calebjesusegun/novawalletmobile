import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/cards/app_key_value_row.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';

/// Screen presenting the online processing, success, and failure results for a Send Money transfer.
///
/// Implements requirements:
/// - SND-011: Online transfer enters Processing (UI-SND-11).
/// - SND-012: Online transfer success shows amount, recipient, reference, date, and status (UI-SND-12).
/// - SND-013: Immediate online failure shows no debit + retry/back actions (UI-SND-13).
/// - A11Y-001 / A11Y-002: Accessible Semantics and responsive layout supporting 2.0x font scaling.
class TransferResultScreen extends ConsumerWidget {
  const TransferResultScreen({
    super.key,
    required this.operation,
    required this.onDone,
    this.onTryAgain,
  });

  final FinancialOperation operation;
  final VoidCallback onDone;
  final VoidCallback? onTryAgain;

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveOpAsync = ref.watch(operationByIdStreamProvider(operation.id));
    final currentOp = liveOpAsync.value ?? operation;
    final payload = currentOp.payload as SendMoneyPayload;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: switch (currentOp.status) {
          OperationStatus.completed => _buildSuccessView(
            context,
            currentOp,
            payload,
          ),
          OperationStatus.failed => _buildFailedView(
            context,
            currentOp,
            payload,
          ),
          OperationStatus.pending || OperationStatus.processing =>
            _buildProcessingView(context, currentOp, payload),
        },
      ),
    );
  }

  /// UI-SND-11: Online Processing view.
  Widget _buildProcessingView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_processing_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.processing,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical24,
                  Text(
                    'Sending ${payload.amount.format()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold24.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Sending to ${payload.recipientName}. Please wait, this usually takes a few seconds.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  const AppButton(label: 'Sending...', onPressed: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-SND-12: Online Success view.
  Widget _buildSuccessView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    final displayDate = _formatDateTime(op.completedAt ?? op.createdAt);
    final reference =
        op.remoteReference ?? 'REF-${op.idempotencyKey.value.substring(0, 8)}';

    return LayoutBuilder(
      key: const Key('transfer_result_success_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.completed,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Transfer successful',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    payload.amount.format(),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold28.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    'Sent to ${payload.recipientName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppKeyValueRow(
                          label: 'Recipient',
                          value: payload.recipientName,
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Account',
                          value:
                              '${payload.bankName} • ${payload.recipientAccountNumber}',
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Reference', value: reference),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Date', value: displayDate),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        const AppKeyValueRow(
                          label: 'Status',
                          valueWidget: AppStatusBadge(
                            status: AppOperationStatus.completed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_success_done_button'),
                    label: 'Done',
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-SND-13: Online Immediate Failure view.
  Widget _buildFailedView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_failed_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.failed,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Transfer not completed',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'We could not send ${payload.amount.format()} to ${payload.recipientName}. Please try again.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical20,
                  const AppSystemNotification(
                    message: 'Nothing was taken from your wallet.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_failed_try_again_button'),
                    label: 'Try again',
                    onPressed: onTryAgain ?? onDone,
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('transfer_failed_back_button'),
                    label: 'Back to wallet',
                    variant: AppButtonVariant.outline,
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
