import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity_providers.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/components/cards/app_key_value_row.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/components/progress/app_step_progress.dart';
import 'package:novawallet/design_system/components/status/app_result_indicator.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/novasave/domain/savings_goal.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';

/// Screen presenting the complete result lifecycle for NovaSave Contributions.
///
/// Implements requirements:
/// - NSV-013: Online contribution enters Processing (UI-NSV-12).
/// - NSV-014: Successful contribution updates amount/progress (UI-NSV-13, UI-NSV-14).
/// - NSV-015: Immediate online contribution failure leaves wallet unchanged and offers retry (UI-NSV-15).
/// - NSV-017 / NSV-018: Offline Contribution is durably saved as Pending (UI-NSV-17).
/// - NSV-020: Reconnect transitions pending contribution into processing (UI-NSV-19).
/// - NSV-021: Reconnect success completes once and updates goal once (UI-NSV-20).
/// - NSV-022 / NSV-023: Sync failure retains contribution safely and offers retry (UI-NSV-21).
/// - HC-MONEY: Exact integer-kobo money representation.
/// - HC-ACCESSIBILITY: Accessible semantics and responsive layout up to 2.0x font scaling.
class ContributionResultScreen extends ConsumerWidget {
  const ContributionResultScreen({
    super.key,
    required this.operation,
    required this.goal,
    required this.onDone,
    this.onTryAgain,
    this.wasOffline = false,
  });

  final FinancialOperation operation;
  final SavingsGoal goal;
  final VoidCallback onDone;
  final VoidCallback? onTryAgain;
  final bool wasOffline;

  static String _formatDateTime(DateTime dt) {
    const months = [
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Future<void> _handleRetry(WidgetRef ref, FinancialOperation op) async {
    if (onTryAgain != null) {
      onTryAgain!();
      return;
    }
    final syncCoordinator = ref.read(syncCoordinatorProvider);
    await syncCoordinator.retryOperation(op.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveOpAsync = ref.watch(operationByIdStreamProvider(operation.id));
    final currentOp = liveOpAsync.value ?? operation;
    final payload = currentOp.payload as ContributionPayload;
    final connectivity = ref.watch(connectivityStatusProvider);
    final isDeviceOffline = connectivity == ConnectivityStatus.offline;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _selectView(context, ref, currentOp, payload, isDeviceOffline),
      ),
    );
  }

  Widget _selectView(
    BuildContext context,
    WidgetRef ref,
    FinancialOperation op,
    ContributionPayload payload,
    bool isDeviceOffline,
  ) {
    // 1. Recoverable sync failure (UI-NSV-21)
    if (op.status == OperationStatus.pending &&
        op.lastError != null &&
        op.lastError!.isRecoverable) {
      return _buildSyncFailureView(context, ref, op, payload);
    }

    // 2. Terminal failure (UI-NSV-15)
    if (op.status == OperationStatus.failed) {
      return _buildTerminalFailedView(context, ref, op, payload);
    }

    // 3. Completed (UI-NSV-13 or UI-NSV-20)
    if (op.status == OperationStatus.completed) {
      if (wasOffline) {
        return _buildReconnectSuccessView(context, op, payload);
      }
      return _buildOnlineSuccessView(context, op, payload);
    }

    // 4. Processing (UI-NSV-12 or UI-NSV-19)
    if (op.status == OperationStatus.processing) {
      if (wasOffline) {
        return _buildReconnectProcessingView(context, op, payload);
      }
      return _buildOnlineProcessingView(context, op, payload);
    }

    // 5. Pending while offline or submitted offline (UI-NSV-17)
    if (isDeviceOffline || wasOffline) {
      return _buildOfflinePendingView(context, op, payload);
    }

    // 6. Online initial pending before sync claims it (UI-NSV-12)
    return _buildOnlineProcessingView(context, op, payload);
  }

  /// UI-NSV-17: Offline Contribution Pending view.
  Widget _buildOfflinePendingView(
    BuildContext context,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('contribution_result_pending_offline_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  AppSystemNotification.offline(
                    title: "You're offline",
                    message: "Some actions will be saved and processed when you're back online.",
                  ),
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.pending,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Contribution Pending',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    payload.amount.format(),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold28.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    'For: ${payload.goalName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Pending — will add when back online',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelBold12.copyWith(
                      color: AppColors.amber700,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.offlinePending(),
                  AppSpacing.gapVertical24,
                  const AppSystemNotification(
                    message: 'Saved on this phone. We will add it automatically when you are online. You do not need to add it again.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('contribution_pending_back_button'),
                    label: 'Back to goal',
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-19: Reconnect Processing view.
  Widget _buildReconnectProcessingView(
    BuildContext context,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('contribution_result_reconnect_processing_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const AppSystemNotification(
                    title: 'Back online',
                    message: 'Processing your saved actions...',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.processing,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Adding ${payload.amount.format()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Adding to ${payload.goalName} after you came back online.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.reconnectProcessing(),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  const AppButton(label: 'Adding...', onPressed: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-20: Reconnect Success view.
  Widget _buildReconnectSuccessView(
    BuildContext context,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    final displayDate = _formatDateTime(op.completedAt ?? op.createdAt);
    final reference =
        op.remoteReference ?? 'REF-${op.idempotencyKey.value.substring(0, 8)}';
    final progress = goal.projectContribution(payload.amount);

    return LayoutBuilder(
      key: const Key('contribution_result_reconnect_success_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.completed,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Contribution successful',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    payload.amount.format(),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold28.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    'Added to ${payload.goalName} after you came back online.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.reconnectSuccess(),
                  AppSpacing.gapVertical24,
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppKeyValueRow(label: 'Goal', value: payload.goalName),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Progress',
                          value: '${progress.percentage}%',
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Reference', value: reference),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Added at', value: displayDate),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('contribution_reconnect_done_button'),
                    label: 'Done',
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-21: Recoverable Sync Failure & Retry view.
  Widget _buildSyncFailureView(
    BuildContext context,
    WidgetRef ref,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('contribution_result_sync_failure_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const AppSystemNotification(
                    title: "We couldn't finish syncing",
                    message: 'Your saved actions are safe. We will try again shortly.',
                    type: SystemNotificationType.syncFailure,
                  ),
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.pending,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'We could not add it yet',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Your contribution is still saved. We will keep trying, or you can try again now.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.syncFailure(),
                  AppSpacing.gapVertical24,
                  AppSystemNotification(
                    message:
                        'Nothing is lost. Your ${payload.amount.format()} contribution to ${payload.goalName} is still waiting.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('contribution_sync_failure_retry_button'),
                    label: 'Try again now',
                    onPressed: () => _handleRetry(ref, op),
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('contribution_sync_failure_back_button'),
                    label: 'Back to goal',
                    variant: AppButtonVariant.outline,
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-12: Online Processing view.
  Widget _buildOnlineProcessingView(
    BuildContext context,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('contribution_result_processing_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.processing,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical24,
                  Text(
                    'Adding ${payload.amount.format()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold24.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Adding to ${payload.goalName}. Please wait, this usually takes a few seconds.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  const AppButton(label: 'Adding...', onPressed: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-13: Online Success view.
  Widget _buildOnlineSuccessView(
    BuildContext context,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    final displayDate = _formatDateTime(op.completedAt ?? op.createdAt);
    final reference =
        op.remoteReference ?? 'REF-${op.idempotencyKey.value.substring(0, 8)}';
    final newSavedAmount = goal.savedAmount + payload.amount;
    final progress = goal.projectContribution(payload.amount);

    return LayoutBuilder(
      key: const Key('contribution_result_success_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.completed,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Contribution successful',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    payload.amount.format(),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold28.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    'Added to ${payload.goalName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppKeyValueRow(label: 'Goal', value: payload.goalName),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Contribution',
                          value: payload.amount.format(),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'New balance',
                          value: newSavedAmount.format(),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Target',
                          value: goal.targetAmount.format(),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Progress',
                          value: '${progress.percentage}%',
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Reference', value: reference),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Date', value: displayDate),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('contribution_success_done_button'),
                    label: 'Done',
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-NSV-15: Terminal Failed view.
  Widget _buildTerminalFailedView(
    BuildContext context,
    WidgetRef ref,
    FinancialOperation op,
    ContributionPayload payload,
  ) {
    final errorMessage =
        op.lastError?.message ??
        'We could not process your contribution. Please try again.';

    return LayoutBuilder(
      key: const Key('contribution_result_failed_view'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.space20 * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.failed,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Contribution failed',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    payload.amount.format(),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold28.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    'Could not add to ${payload.goalName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppSystemNotification(
                    message:
                        'No funds were deducted from your wallet. $errorMessage',
                    type: SystemNotificationType.syncFailure,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('contribution_failure_retry_button'),
                    label: 'Try again',
                    onPressed: () => _handleRetry(ref, op),
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('contribution_failure_back_button'),
                    label: 'Back to goal',
                    variant: AppButtonVariant.outline,
                    onPressed: onDone,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
