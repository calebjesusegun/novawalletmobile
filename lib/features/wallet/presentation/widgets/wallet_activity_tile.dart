import 'package:flutter/material.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/domain/transaction_type.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';

/// Presentation tile for an activity item (confirmed or in-flight) on the Wallet feed.
///
/// Implements requirements:
/// - WAL-002 / ASM-003: Render transactions with date, counterparty, amount, status.
/// - UI-WAL-01, UI-WAL-03, UI-WAL-04, UI-WAL-05, UI-WAL-06.
/// - A11Y-001, A11Y-002: Screen reader semantics and flexible layout for font scale.
class WalletActivityTile extends StatelessWidget {
  final WalletActivityItem item;
  final VoidCallback? onTap;

  const WalletActivityTile({super.key, required this.item, this.onTap});

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

  String _formatTimestamp(DateTime dt) =>
      DateTimeFormatter.formatShortTimestamp(dt);

  @override
  Widget build(BuildContext context) {
    final isCredit = item.type == TransactionType.credit;
    final isDebit = item.type == TransactionType.debit;

    final Color iconBg;
    final Color iconColor;
    final IconData icon;

    if (item.status == TransactionStatus.processing) {
      iconBg = AppColors.blue50;
      iconColor = AppColors.primaryAction;
      icon = AppIcons.refresh;
    } else if (item.status == TransactionStatus.pending) {
      iconBg = AppColors.amber50;
      iconColor = AppColors.warning;
      icon = AppIcons.clock;
    } else if (item.status == TransactionStatus.failed) {
      iconBg = AppColors.red50;
      iconColor = AppColors.error;
      icon = AppIcons.close;
    } else if (isCredit) {
      iconBg = AppColors.green50;
      iconColor = AppColors.success;
      icon = AppIcons.arrowDownLeft;
    } else {
      iconBg = AppColors.red50;
      iconColor = AppColors.error;
      icon = AppIcons.arrowUpRight;
    }

    final amountPrefix = isCredit ? '+' : (isDebit ? '-' : '');
    final amountColor = isCredit ? AppColors.success : AppColors.textPrimary;
    final amountText = '$amountPrefix${item.amount.format()}';

    final semanticLabel =
        '${item.title}, ${item.subtitle}, $amountText, status ${item.status.name}';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdBorderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadii.pillBorderRadius,
                ),
                child: Center(child: AppIcon(icon, size: 20, color: iconColor)),
              ),
              AppSpacing.gapHorizontal12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMedium14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapVertical4,
                    Text(
                      '${_formatTimestamp(item.timestamp)} • ${item.subtitle}',
                      style: AppTypography.bodyMedium12.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapHorizontal12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: AppTypography.bodyMedium14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                  if (item.status != TransactionStatus.completed) ...[
                    AppSpacing.gapVertical4,
                    AppStatusBadge(status: _mapStatus(item.status)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
