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
/// - UI-WAL-07: Refreshing presentation.
/// - A11Y-001, A11Y-002: Accessible semantics and responsive text scaling.
class WalletBalanceCard extends StatelessWidget {
  final Money balance;
  final bool isRefreshing;
  final VoidCallback onSendMoneyTap;
  final VoidCallback onNovaSaveTap;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.isRefreshing = false,
    required this.onSendMoneyTap,
    required this.onNovaSaveTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Available Balance',
                style: AppTypography.bodyMedium14.copyWith(
                  color: AppColors.textSecondary,
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
            label: 'Available balance: ${balance.format()}',
            child: Text(
              balance.format(),
              style: AppTypography.headlineBold32.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          AppSpacing.gapVertical20,
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
      ),
    );
  }
}
