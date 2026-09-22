import 'package:flutter/material.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';

/// Modal bottom sheet displaying detailed information about a transaction or pending operation.
///
/// Implements requirements:
/// - WAL-011 / UI-WAL-10: Shows amount, recipient, saved time/status, and saved-on-phone explanation.
/// - A11Y-001, A11Y-002: Screen reader semantics and responsive font scaling.
class WalletTransactionDetailSheet extends StatelessWidget {
  final WalletActivityItem item;
  final VoidCallback? onRetry;

  const WalletTransactionDetailSheet({
    super.key,
    required this.item,
    this.onRetry,
  });

  /// Displays the transaction detail bottom sheet modally.
  static Future<void> show({
    required BuildContext context,
    required WalletActivityItem item,
    VoidCallback? onRetry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          WalletTransactionDetailSheet(item: item, onRetry: onRetry),
    );
  }

  AppOperationStatus _mapStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppOperationStatus.completed;
      case TransactionStatus.pending:
        return AppOperationStatus.pending;
      case TransactionStatus.processing:
        return AppOperationStatus.processing;
      case TransactionStatus.failed:
        return AppOperationStatus.failed;
    }
  }

  String _formatDateTime(DateTime dt) =>
      DateTimeFormatter.formatFullTimestamp(dt);

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == TransactionStatus.pending;
    final isProcessing = item.status == TransactionStatus.processing;
    final isFailed = item.status == TransactionStatus.failed;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.xl),
          topRight: Radius.circular(AppRadii.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space24,
        right: AppSpacing.space24,
        top: AppSpacing.space12,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.grey200,
                borderRadius: AppRadii.pillBorderRadius,
              ),
            ),
          ),
          AppSpacing.gapVertical20,

          // Header title & status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Details',
                style: AppTypography.titleBold18,
              ),
              AppStatusBadge(status: _mapStatus(item.status)),
            ],
          ),
          AppSpacing.gapVertical20,

          // Large amount display
          Center(
            child: Column(
              children: [
                Text(
                  item.amount.format(),
                  style: AppTypography.headlineBold32.copyWith(
                    color: item.status == TransactionStatus.failed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapVertical4,
                Text(
                  item.subtitle,
                  style: AppTypography.bodyRegular14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapVertical24,

          // Offline saved-on-phone banner (UI-WAL-10)
          if (isPending || isProcessing) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: AppRadii.mdBorderRadius,
                border: Border.all(color: AppColors.amber200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  AppSpacing.gapHorizontal12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProcessing
                              ? 'Syncing to Bank...'
                              : 'Queued securely',
                          style: AppTypography.bodyBold12.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapVertical4,
                        Text(
                          isProcessing
                              ? 'Your transfer is currently being submitted.'
                              : 'Queued securely. This transfer will be sent automatically when you\'re back online.',
                          style: AppTypography.bodyRegular12.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVertical20,
          ],

          // Sync failure explanation banner (UI-WAL-06 / WAL-009)
          if (isFailed && item.hasSyncError) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: AppRadii.mdBorderRadius,
                border: Border.all(color: AppColors.red200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  AppSpacing.gapHorizontal12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Failed',
                          style: AppTypography.bodyBold12.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        AppSpacing.gapVertical4,
                        Text(
                          item.failureReason ?? 'We could not complete this transfer. Your intent is preserved and you can retry.',
                          style: AppTypography.bodyRegular12.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVertical20,
          ],

          // Key-value metadata table
          Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadii.mdBorderRadius,
            ),
            child: Column(
              children: [
                _buildRow(label: 'Recipient', value: item.title),
                if (item.counterpartyDetail != null &&
                    item.counterpartyDetail!.isNotEmpty) ...[
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  _buildRow(label: 'Details', value: item.counterpartyDetail!),
                ],
                const Divider(height: 20, color: AppColors.borderSubtle),
                _buildRow(
                  label: isPending ? 'Queued At' : 'Date',
                  value: _formatDateTime(item.timestamp),
                ),
                if (item.reference != null && item.reference!.isNotEmpty) ...[
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  _buildRow(label: 'Reference', value: item.reference!),
                ],
              ],
            ),
          ),
          AppSpacing.gapVertical24,

          // Action buttons
          if (isFailed && onRetry != null) ...[
            AppButton(
              label: 'Retry Transfer',
              onPressed: () {
                Navigator.of(context).pop();
                onRetry!();
              },
            ),
            AppSpacing.gapVertical12,
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            AppButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyRegular14.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapHorizontal12,
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium14.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
