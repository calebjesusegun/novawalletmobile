import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/core/time/date_time_formatter.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/cards/app_key_value_row.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/progress/app_progress_bar.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/contribute_amount_screen.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

/// Screen displaying details of a specific savings goal (UI-NSV-08, UI-NSV-18).
///
/// Implements requirements:
/// - ASM-008: NovaSave goal details and progress.
/// - NSV-008: Show goal details and remaining amount.
/// - MNY-003: Calculate savings goal progress and remaining amount from integer kobo.
/// - HC-MONEY: Exact integer-kobo arithmetic without floating-point values.
/// - HC-OFFLINE-DURABILITY: Offline-awareness and pending contribution display.
/// - HC-ACCESSIBILITY: Screen reader semantics and responsive 2.0x text scaling.
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
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;

    final goal =
        goalsAsync.valueOrNull?.where((g) => g.id == goalId).firstOrNull ??
        initialGoal;

    if (goal == null) {
      if (goalsAsync.isLoading) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Goal details', style: AppTypography.titleBold18),
          elevation: 0,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Goal not found',
            style: AppTypography.bodyMedium16.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Aggregate pending contributions for this specific goal (UI-NSV-18)
    final activeOps =
        ref.watch(activeOperationsStreamProvider).valueOrNull ?? const [];
    var pendingContributionAmount = const Money.zero();
    for (final op in activeOps) {
      if (op.type == OperationType.contribution &&
          op.payload is ContributionPayload) {
        final payload = op.payload as ContributionPayload;
        if (payload.goalId == goalId) {
          pendingContributionAmount += payload.amount;
        }
      }
    }
    final hasPending = pendingContributionAmount.isPositive;

    final formattedTargetDate = DateTimeFormatter.formatDate(goal.targetDate);
    final semanticSummary = StringBuffer()
      ..write('Goal details for ${goal.name}. ')
      ..write('Saved so far: ${goal.savedAmount.format()} ')
      ..write('of ${goal.targetAmount.format()} target, ')
      ..write('${goal.percentage}% complete. ')
      ..write('Still to save: ${goal.remainingAmount.format()}. ')
      ..write('Target date: $formattedTargetDate.');
    if (hasPending) {
      semanticSummary.write(
        ' ${pendingContributionAmount.format()} pending contribution. Will contribute when back online.',
      );
    }

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
            // Offline Notification Banner (UI-NSV-18)
            if (isOffline)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  0,
                ),
                child: AppSystemNotification.offline(
                  title: "You're offline",
                  message: "Requests will be queued securely and processed when you're back online.",
                ),
              ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Semantics(
                  container: true,
                  label: semanticSummary.toString(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Progress Card (UI-NSV-08)
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
                              height: 8.0,
                              fillColor: AppColors.primaryAction,
                              backgroundColor: AppColors.grey100,
                              semanticLabel:
                                  '${goal.percentage}% progress toward ${goal.targetAmount.format()}',
                            ),
                            AppSpacing.gapVertical12,
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.space8,
                              runSpacing: AppSpacing.space4,
                              children: [
                                Text(
                                  '${goal.percentage}% complete',
                                  style: AppTypography.titleBold16.copyWith(
                                    color: AppColors.primaryAction,
                                  ),
                                ),
                                Text(
                                  'Target: $formattedTargetDate',
                                  style: AppTypography.bodyMedium14.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Pending Contribution Banner (UI-NSV-18)
                      if (hasPending) ...[
                        AppSpacing.gapVertical16,
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.space12),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: AppRadii.smBorderRadius,
                            border: Border.all(
                              color: AppColors.amber200,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending',
                                style: AppTypography.titleBold14.copyWith(
                                  color: AppColors.amber900,
                                ),
                              ),
                              AppSpacing.gapVertical4,
                              Text(
                                '${pendingContributionAmount.format()} pending. Will contribute when back online.',
                                style: AppTypography.bodyMedium12.copyWith(
                                  color: AppColors.amber900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      AppSpacing.gapVertical16,

                      // Key Values Detail Card (UI-NSV-08)
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
                              value: formattedTargetDate,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Contribute Button (UI-NSV-08)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: AppButton(
                key: const Key('goal_details_contribute_button'),
                label: 'Contribute',
                semanticLabel: 'Contribute to ${goal.name}',
                onPressed:
                    onContribute ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ContributeAmountScreen(goal: goal),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
