import 'package:flutter/material.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Card component displaying the user's available wallet balance and quick action buttons.
///
/// Implements requirements:
/// - WAL-001 / ASM-002: Available balance formatted in Naira from integer kobo.
/// - UI-WAL-01: Headline card with Send Money and NovaSave shortcuts.
/// - UI-WAL-02: Offline balance with last-updated timestamp.
/// - UI-WAL-07: Refreshing presentation.
/// - A11Y-001, A11Y-002: Accessible semantics and responsive text scaling.
class WalletBalanceCard extends StatelessWidget {
  final Money balance;
  final DateTime? lastUpdatedAt;
  final bool isOffline;
  final bool isRefreshing;
  final VoidCallback onSendMoneyTap;
  final VoidCallback onNovaSaveTap;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.lastUpdatedAt,
    this.isOffline = false,
    this.isRefreshing = false,
    required this.onSendMoneyTap,
    required this.onNovaSaveTap,
  });

  String _formatLastUpdated(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return 'Last updated at $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isOffline && lastUpdatedAt != null
        ? 'Available balance: ${balance.format()}, ${_formatLastUpdated(lastUpdatedAt!)}'
        : 'Available balance: ${balance.format()}';

    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return AppCard(
      padding: AppSpacing.insetsAll20,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Available Balance',
                  style: AppTypography.bodyMedium14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (isRefreshing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryAction,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapVertical8,
          Semantics(
            label: semanticLabel,
            excludeSemantics: true,
            child: Text(
              balance.format(),
              style: AppTypography.headlineBold32.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (isOffline && lastUpdatedAt != null) ...[
            AppSpacing.gapVertical4,
            Text(
              _formatLastUpdated(lastUpdatedAt!),
              style: AppTypography.bodyMedium12.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          AppSpacing.gapVertical20,
          if (isLargeText) ...[
            AppButton(
              label: 'Send Money',
              icon: AppIcons.arrowUpRight,
              variant: AppButtonVariant.primary,
              onPressed: onSendMoneyTap,
            ),
            AppSpacing.gapVertical8,
            AppButton(
              label: 'NovaSave',
              icon: AppIcons.piggyBank,
              variant: AppButtonVariant.secondary,
              onPressed: onNovaSaveTap,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Send Money',
                    icon: AppIcons.arrowUpRight,
                    variant: AppButtonVariant.primary,
                    onPressed: onSendMoneyTap,
                  ),
                ),
                AppSpacing.gapHorizontal12,
                Expanded(
                  child: AppButton(
                    label: 'NovaSave',
                    icon: AppIcons.piggyBank,
                    variant: AppButtonVariant.secondary,
                    onPressed: onNovaSaveTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
