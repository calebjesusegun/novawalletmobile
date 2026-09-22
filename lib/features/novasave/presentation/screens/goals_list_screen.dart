import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/money/money.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/empty_states/app_empty_state.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/features/novasave/presentation/screens/create_goal_screen.dart';
import 'package:novawallet/features/novasave/presentation/screens/goal_details_screen.dart';
import 'package:novawallet/features/novasave/presentation/widgets/goal_card.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_type.dart';

/// Primary screen for NovaSave: Goal list and Empty State (UI-NSV-01, UI-NSV-02, UI-NSV-03).
///
/// Implements requirements:
/// - NSV-001: Populated goal list showing goal cards with name, saved, target, percentage, and date.
/// - NSV-002: Empty state when no goals exist with "Create Goal" prompt.
/// - UI-NSV-02: Offline awareness showing system banner and pending contribution badge on goals.
/// - HC-MONEY: All monetary values in integer kobo.
/// - HC-ACCESSIBILITY: Accessible semantics and responsive layout under text scaling.
class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key, this.onCreateGoal, this.onGoalTapped});

  final VoidCallback? onCreateGoal;
  final ValueChanged<SavingsGoal>? onGoalTapped;

  void _navigateToCreateGoal(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateGoalScreen()));
  }

  void _navigateToGoalDetails(BuildContext context, SavingsGoal goal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalDetailsScreen(goalId: goal.id, initialGoal: goal),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;

    // Aggregate pending contributions by goalId
    final activeOps =
        ref.watch(activeOperationsStreamProvider).valueOrNull ?? const [];
    final pendingContributionsByGoal = <String, Money>{};
    for (final op in activeOps) {
      if (op.type == OperationType.contribution &&
          op.payload is ContributionPayload) {
        final payload = op.payload as ContributionPayload;
        pendingContributionsByGoal[payload.goalId] =
            (pendingContributionsByGoal[payload.goalId] ?? const Money.zero()) +
            payload.amount;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NovaSave', style: AppTypography.titleBold18),
        elevation: 0,
        backgroundColor: AppColors.surface,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Offline System Banner (UI-NSV-02)
          if (isOffline)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                0,
              ),
              child: AppSystemNotification.offline(),
            ),

          // Main content area
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: AppEmptyState.novaSaveGoals(
                        key: const Key('novasave_empty_state'),
                        onActionPressed: onCreateGoal != null
                            ? onCreateGoal!
                            : () => _navigateToCreateGoal(context),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space16,
                        AppSpacing.space16,
                        AppSpacing.space16,
                        AppSpacing.space8,
                      ),
                      child: Text(
                        'Your savings goals',
                        style: AppTypography.labelBold14.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Populated Goal Cards List
                    Expanded(
                      child: ListView.separated(
                        key: const Key('goals_list_view'),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space16,
                          AppSpacing.space8,
                          AppSpacing.space16,
                          AppSpacing.space16,
                        ),
                        itemCount: goals.length,
                        separatorBuilder: (_, _) => AppSpacing.gapVertical12,
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          final pendingAmount =
                              pendingContributionsByGoal[goal.id];

                          return GoalCard(
                            key: Key('goal_card_${goal.id}'),
                            goal: goal,
                            pendingContributionAmount: pendingAmount,
                            onTap: onGoalTapped != null
                                ? () => onGoalTapped!(goal)
                                : () => _navigateToGoalDetails(context, goal),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: AppSpacing.insetsAll24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unable to load savings goals',
                        style: AppTypography.titleBold18.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      AppSpacing.gapVertical8,
                      Text(
                        error.toString(),
                        style: AppTypography.bodyRegular14.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: goalsAsync.maybeWhen(
        data: (goals) {
          if (goals.isEmpty) {
            return null;
          }
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: AppButton(
                key: const Key('create_goal_button'),
                label: 'Create Goal',
                onPressed: onCreateGoal != null
                    ? onCreateGoal!
                    : () => _navigateToCreateGoal(context),
                isFullWidth: true,
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
