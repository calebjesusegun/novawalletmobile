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
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/controllers/contribution_confirmation_controller.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// Screen for the Contribution Confirmation step of NovaSave.
///
/// Implements requirements:
/// - NSV-011: Show contribution confirmation (UI-NSV-11).
/// - NSV-012: Create one stable operation identity/idempotency key (ASM-011, ASM-013).
/// - NSV-016: Offline confirmation explains contribution will be saved (UI-NSV-16).
/// - NSV-017: Offline Contribution is durably persisted before UI reports it saved.
/// - HC-MONEY: Exact integer-kobo arithmetic.
/// - HC-IDEMPOTENCY: Stable operation identity and idempotency key.
/// - HC-OFFLINE-DURABILITY: Durable local persistence before acknowledging.
/// - HC-ACCESSIBILITY: Screen reader semantics and responsive 2.0x text scaling.
/// Visual references: UI-NSV-11, UI-NSV-16.
class ContributionConfirmationScreen extends ConsumerWidget {
  const ContributionConfirmationScreen({
    super.key,
    required this.goal,
    required this.amount,
    required this.onBack,
    required this.onContributionSubmitted,
  });

  final SavingsGoal goal;
  final Money amount;
  final VoidCallback onBack;
  final ValueChanged<FinancialOperation> onContributionSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ContributionConfirmationArgs(goal: goal, amount: amount);
    final state = ref.watch(contributionConfirmationControllerProvider(args));
    final controller = ref.read(
      contributionConfirmationControllerProvider(args).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Confirm contribution',
          style: AppTypography.titleBold18,
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          key: const Key('confirmation_back_button'),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Back',
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error notification if submission failed
              if (state.errorMessage != null) ...[
                AppSystemNotification(
                  key: const Key('confirmation_error_banner'),
                  message: state.errorMessage!,
                  type: SystemNotificationType.syncFailure,
                ),
                AppSpacing.gapVertical16,
              ],

              // Headline Prompt Section
              Semantics(
                header: true,
                child: Column(
                  children: [
                    Text(
                      'You are about to add',
                      style: AppTypography.bodyMedium14.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapVertical8,
                    Text(
                      state.amount.format(),
                      style: AppTypography.headlineBold32.copyWith(
                        color: AppColors.primaryAction,
                      ),
                    ),
                    AppSpacing.gapVertical8,
                    Text(
                      'to ${state.goal.name}',
                      style: AppTypography.titleBold16.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVertical24,

              // Details Key-Value Card
              AppCard(
                key: const Key('contribution_details_card'),
                child: Column(
                  children: [
                    AppKeyValueRow(
                      key: const Key('row_goal_name'),
                      label: 'Goal',
                      value: state.goal.name,
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('row_contribution_amount'),
                      label: 'Contribution',
                      value: state.amount.format(),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('row_current_balance'),
                      label: 'Current balance',
                      value: state.goal.savedAmount.format(),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('row_balance_after'),
                      label: 'Balance after',
                      value: state.goalBalanceAfter.format(),
                    ),
                    const Divider(color: AppColors.borderSubtle, height: 1),
                    AppKeyValueRow(
                      key: const Key('row_projected_progress'),
                      label: 'Projected progress',
                      value: '${state.projectedProgress.percentage}%',
                    ),
                  ],
                ),
              ),

              // Offline Explanation Box (UI-NSV-16)
              if (state.isOffline) ...[
                AppSpacing.gapVertical20,
                AppSystemNotification.savedOnPhone(
                  key: const Key('confirmation_offline_notice'),
                  message: 'You are offline. This contribution will be queued securely and processed once you are back online.',
                ),
              ],

              AppSpacing.gapVertical24,

              // Primary Action: Confirm Contribution
              AppButton(
                key: const Key('confirm_contribution_button'),
                label: 'Confirm Contribution',
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit
                    ? () async {
                        final operation = await controller
                            .confirmContribution();
                        if (operation != null) {
                          onContributionSubmitted(operation);
                        }
                      }
                    : null,
              ),

              AppSpacing.gapVertical12,

              // Secondary Action: Edit details
              AppButton(
                key: const Key('edit_details_button'),
                label: 'Edit details',
                variant: AppButtonVariant.outline,
                onPressed: state.isSubmitting ? null : onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
