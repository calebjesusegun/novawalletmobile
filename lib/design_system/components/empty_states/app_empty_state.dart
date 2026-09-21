import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Centralized empty-state presentation for NovaWallet.
///
/// Implements DSN-014, A11Y-001, A11Y-002.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  /// Factory for Wallet empty state per docs/DESIGN_SYSTEM.md §9.9.
  factory AppEmptyState.walletTransactions({
    Key? key,
    VoidCallback? onActionPressed,
  }) {
    return AppEmptyState(
      key: key,
      icon: AppIcons.wallet,
      title: 'No transactions yet',
      description: 'Your recent wallet activity will appear here.',
      actionLabel: onActionPressed != null ? 'Send Money' : null,
      onActionPressed: onActionPressed,
    );
  }

  /// Factory for NovaSave empty state per docs/DESIGN_SYSTEM.md §9.9.
  factory AppEmptyState.novaSaveGoals({
    Key? key,
    VoidCallback? onActionPressed,
  }) {
    return AppEmptyState(
      key: key,
      icon: AppIcons.piggyBank,
      title: 'Start saving toward something',
      description: 'Create your first NovaSave goal.',
      actionLabel: onActionPressed != null ? 'Create Goal' : null,
      onActionPressed: onActionPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space32,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.blue50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 32, color: AppColors.primaryAction),
              ),
            ),
            AppSpacing.gapVertical20,
            Text(
              title,
              style: AppTypography.titleBold18,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVertical8,
            Text(
              description,
              style: AppTypography.bodyRegular14.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              AppSpacing.gapVertical24,
              AppButton(
                label: actionLabel!,
                onPressed: onActionPressed,
                isFullWidth: false,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
