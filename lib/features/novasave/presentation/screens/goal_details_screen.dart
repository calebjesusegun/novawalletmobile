import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/cards/app_key_value_row.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';

/// Screen displaying details of a specific savings goal (UI-NSV-08).
///
/// Implements requirement NSV-008 and provides destination after goal creation (T-NSV-002).
class GoalDetailsScreen extends ConsumerWidget {
  const GoalDetailsScreen({
    super.key,
    required this.goalId,
    this.initialGoal,
    this.onContribute,
  });

  final String goalId;
  final SavingsGoal? initialGoal;
  final VoidCallback? onContribute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final goal =
        goalsAsync.valueOrNull?.firstWhere(
          (g) => g.id == goalId,
          orElse: () =>
              initialGoal ??
              SavingsGoal(
                id: goalId,
                name: 'Goal',
                targetAmount: const Money.fromKobo(100),
                targetDate: DateTime.now().add(const Duration(days: 30)),
              ),
        ) ??
        initialGoal ??
        SavingsGoal(
          id: goalId,
          name: 'Goal',
          targetAmount: const Money.fromKobo(100),
          targetDate: DateTime.now().add(const Duration(days: 30)),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          goal.name,
          style: AppTypography.titleBold18.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Progress Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved so far',
                            style: AppTypography.labelRegular12.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapVertical8,
                          Text(
                            goal.savedAmount.format(),
                            style: AppTypography.headlineBold32.copyWith(
                              color: AppColors.primaryAction,
                            ),
                          ),
                          AppSpacing.gapVertical4,
                          Text(
                            'of ${goal.targetAmount.format()} target',
                            style: AppTypography.bodyMedium14.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapVertical16,
                          AppProgressBar(
                            progress: goal.progress.toProgressFraction(),
                          ),
                          AppSpacing.gapVertical12,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${goal.percentage}% complete',
                                style: AppTypography.titleBold16.copyWith(
                                  color: AppColors.primaryAction,
                                ),
                              ),
                              Text(
                                'Target: ${DateTimeFormatter.formatDate(goal.targetDate)}',
                                style: AppTypography.bodyMedium14.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapVertical16,

                    // Key Values Detail Card
                    AppCard(
                      child: Column(
                        children: [
                          AppKeyValueRow(
                            label: 'Target',
                            value: goal.targetAmount.format(),
                          ),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          AppKeyValueRow(
                            label: 'Still to save',
                            value: goal.remainingAmount.format(),
                          ),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          AppKeyValueRow(
                            label: 'Target date',
                            value: DateTimeFormatter.formatDate(
                              goal.targetDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Contribute Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: AppButton(
                label: 'Contribute',
                onPressed: onContribute ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
