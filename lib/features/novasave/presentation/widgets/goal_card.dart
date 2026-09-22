import 'package:flutter/material.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Renders an individual savings goal card (UI-NSV-01, UI-NSV-02).
///
/// Under constraint HC-MONEY:
/// - Amounts are formatted via [Money.formatCompact()] (e.g. `₦150,000 of ₦500,000`).
/// - Progress fraction is converted from exact integer basis points via [SavingsProgress.toProgressFraction()].
///
/// Under constraint HC-ACCESSIBILITY:
/// - Screen readers receive complete goal status, saved/target amounts, and target date.
/// - Flexible wrap layout prevents overflow under 2.0x text scaling.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    this.pendingContributionAmount,
    this.onTap,
  });

  final SavingsGoal goal;
  final Money? pendingContributionAmount;
  final VoidCallback? onTap;

  static const List<String> _shortMonths = [
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

  static String formatDate(DateTime dt) {
    final month = _shortMonths[dt.month - 1];
    return '${dt.day} $month ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPending =
        pendingContributionAmount != null &&
        pendingContributionAmount!.isPositive;

    final semanticText = StringBuffer()
      ..write(goal.name)
      ..write(', ')
      ..write('${goal.percentage}% saved. ')
      ..write(
        '${goal.savedAmount.formatCompact()} of ${goal.targetAmount.formatCompact()}. ',
      )
      ..write('Target: ${formatDate(goal.targetDate)}.');

    if (hasPending) {
      semanticText.write(
        ' ${pendingContributionAmount!.format()} pending contribution.',
      );
    }

    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticText.toString(),
      excludeSemantics: true,
      onTapHint: onTap != null ? 'View goal details' : null,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.lgBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.lgBorderRadius,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadii.lgBorderRadius,
            ),
            padding: AppSpacing.insetsAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Goal name and percentage
                if (isLargeText) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: AppTypography.titleBold16),
                      AppSpacing.gapVertical4,
                      Text(
                        '${goal.percentage}%',
                        style: AppTypography.titleBold16.copyWith(
                          color: AppColors.primaryAction,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: AppTypography.titleBold16,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.gapHorizontal12,
                      Text(
                        '${goal.percentage}%',
                        style: AppTypography.titleBold16.copyWith(
                          color: AppColors.primaryAction,
                        ),
                      ),
                    ],
                  ),
                ],
                AppSpacing.gapVertical12,

                // Progress bar
                AppProgressBar(
                  progress: goal.progress.toProgressFraction(),
                  height: 8.0,
                  fillColor: AppColors.primaryAction,
                  backgroundColor: AppColors.grey100,
                  semanticLabel: '${goal.percentage}% progress toward target',
                ),
                AppSpacing.gapVertical12,

                // Bottom row: Saved of target amount and target date
                if (isLargeText) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${goal.savedAmount.formatCompact()} of ${goal.targetAmount.formatCompact()}',
                        style: AppTypography.bodyMedium12.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapVertical4,
                      Text(
                        'Target: ${formatDate(goal.targetDate)}',
                        style: AppTypography.bodyMedium12.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${goal.savedAmount.formatCompact()} of ${goal.targetAmount.formatCompact()}',
                          style: AppTypography.bodyMedium12.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      AppSpacing.gapHorizontal8,
                      Text(
                        'Target: ${formatDate(goal.targetDate)}',
                        style: AppTypography.bodyMedium12.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Offline pending contribution banner (UI-NSV-02)
                if (hasPending) ...[
                  AppSpacing.gapVertical12,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space12,
                      vertical: AppSpacing.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: AppRadii.smBorderRadius,
                      border: Border.all(color: AppColors.amber200, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.amber700,
                        ),
                        AppSpacing.gapHorizontal8,
                        Expanded(
                          child: Text(
                            '${pendingContributionAmount!.format()} pending. Will add when you are online.',
                            style: AppTypography.bodyMedium12.copyWith(
                              color: AppColors.amber900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
