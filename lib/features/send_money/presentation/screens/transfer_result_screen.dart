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
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';

/// Comprehensive screen presenting the complete result lifecycle for Send Money.
///
/// Implements requirements:
/// - SND-011: Online transfer enters Processing (UI-SND-11).
/// - SND-012: Online transfer success shows details (UI-SND-12).
/// - SND-013: Immediate online failure shows no debit + retry/back (UI-SND-13).
/// - SND-015 / SND-016: Offline Send is durably saved as Pending (UI-SND-15).
/// - SND-017: Reconnect transitions pending transfer into processing (UI-SND-16).
/// - SND-018: Reconnect success completes once and updates wallet once (UI-SND-17).
/// - SND-019 / SND-020: Sync failure retains transfer safely and offers retry (UI-SND-18).
/// - A11Y-001 / A11Y-002: Accessible Semantics and responsive layout supporting 2.0x font scaling.
class TransferResultScreen extends ConsumerWidget {
  const TransferResultScreen({
    super.key,
    required this.operation,
    required this.onDone,
    this.onTryAgain,
    this.wasOffline = false,
  });

  final FinancialOperation operation;
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
    final payload = currentOp.payload as SendMoneyPayload;
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
    SendMoneyPayload payload,
    bool isDeviceOffline,
  ) {
    // 1. Recoverable sync failure (UI-SND-18)
    if (op.status == OperationStatus.pending &&
        op.lastError != null &&
        op.lastError!.isRecoverable) {
      return _buildSyncFailureView(context, ref, op, payload);
    }

    // 2. Terminal failure (UI-SND-13)
    if (op.status == OperationStatus.failed) {
      return _buildTerminalFailedView(context, ref, op, payload);
    }

    // 3. Completed (UI-SND-12 or UI-SND-17)
    if (op.status == OperationStatus.completed) {
      if (wasOffline) {
        return _buildReconnectSuccessView(context, op, payload);
      }
      return _buildOnlineSuccessView(context, op, payload);
    }

    // 4. Processing (UI-SND-11 or UI-SND-16)
    if (op.status == OperationStatus.processing) {
      if (wasOffline) {
        return _buildReconnectProcessingView(context, op, payload);
      }
      return _buildOnlineProcessingView(context, op, payload);
    }

    // 5. Pending while offline or submitted offline (UI-SND-15)
    if (isDeviceOffline || wasOffline) {
      return _buildOfflinePendingView(context, op, payload);
    }

    // 6. Online initial pending before sync claims it (UI-SND-11)
    return _buildOnlineProcessingView(context, op, payload);
  }

  /// UI-SND-15: Offline Transfer Pending view.
  Widget _buildOfflinePendingView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_pending_offline_view'),
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
                    status: AppOperationStatus.pending,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical20,
                  Text(
                    'Transfer Pending',
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
                    'To: ${payload.recipientName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Pending — will send when back online',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelBold12.copyWith(
                      color: AppColors.amber700,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.offlinePending(),
                  AppSpacing.gapVertical24,
                  const AppSystemNotification(
                    message: 'Queued securely. We will send it automatically when you are online. You do not need to send it again.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_pending_back_button'),
                    label: 'Back to wallet',
                    onPressed: onDone,
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('transfer_pending_view_button'),
                    label: 'View transaction',
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

  /// UI-SND-16: Reconnect Processing view.
  Widget _buildReconnectProcessingView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_reconnect_processing_view'),
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
                  AppSystemNotification.backOnline(
                    title: "You're back online",
                    message: 'Pending transactions are being processed.',
                  ),
                  const Spacer(),
                  const AppResultIndicator(
                    status: AppOperationStatus.processing,
                    size: 72.0,
                  ),
                  AppSpacing.gapVertical24,
                  Text(
                    'Sending ${payload.amount.format()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold24.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'You are back online. We are sending your transfer to ${payload.recipientName}.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical24,
                  AppStepProgress.reconnectProcessing(),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  const AppButton(label: 'Sending...', onPressed: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-SND-17: Reconnect Success view.
  Widget _buildReconnectSuccessView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    final displayDate = _formatDateTime(op.completedAt ?? op.createdAt);
    final reference =
        op.remoteReference ?? 'REF-${op.idempotencyKey.value.substring(0, 8)}';

    return LayoutBuilder(
      key: const Key('transfer_result_reconnect_success_view'),
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
                    'Transfer successful',
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
                    'Sent to ${payload.recipientName} after you came back online.',
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
                        AppKeyValueRow(label: 'Reference', value: reference),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(label: 'Sent at', value: displayDate),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_success_done_button'),
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

  /// UI-SND-18: Recoverable Sync Failure & Retry view.
  Widget _buildSyncFailureView(
    BuildContext context,
    WidgetRef ref,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_sync_failure_view'),
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
                    'We could not send it yet',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Your transfer is still saved. We will keep trying, or you can try again now.',
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
                        'Nothing is lost. Your ${payload.amount.format()} transfer to ${payload.recipientName} is still waiting.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_sync_failure_retry_button'),
                    label: 'Try again now',
                    onPressed: () => _handleRetry(ref, op),
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('transfer_sync_failure_back_button'),
                    label: 'Back to wallet',
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

  /// UI-SND-11: Online Processing view.
  Widget _buildOnlineProcessingView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_processing_view'),
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
                    'Sending ${payload.amount.format()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineBold24.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'Sending to ${payload.recipientName}. Please wait, this usually takes a few seconds.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  const AppButton(label: 'Sending...', onPressed: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// UI-SND-12: Online Success view.
  Widget _buildOnlineSuccessView(
    BuildContext context,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    final displayDate = _formatDateTime(op.completedAt ?? op.createdAt);
    final reference =
        op.remoteReference ?? 'REF-${op.idempotencyKey.value.substring(0, 8)}';

    return LayoutBuilder(
      key: const Key('transfer_result_success_view'),
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
                    'Transfer successful',
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
                    'Sent to ${payload.recipientName}',
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
                        AppKeyValueRow(
                          label: 'Recipient',
                          value: payload.recipientName,
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        AppKeyValueRow(
                          label: 'Account',
                          value:
                              '${payload.bankName} • ${payload.recipientAccountNumber}',
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
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                        const AppKeyValueRow(
                          label: 'Status',
                          valueWidget: AppStatusBadge(
                            status: AppOperationStatus.completed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_success_done_button'),
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

  /// UI-SND-13: Online Immediate Failure view.
  Widget _buildTerminalFailedView(
    BuildContext context,
    WidgetRef ref,
    FinancialOperation op,
    SendMoneyPayload payload,
  ) {
    return LayoutBuilder(
      key: const Key('transfer_result_failed_view'),
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
                    'Transfer not completed',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleBold22.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVertical8,
                  Text(
                    'We could not send ${payload.amount.format()} to ${payload.recipientName}. Please try again.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVertical20,
                  const AppSystemNotification(
                    message: 'Nothing was taken from your wallet.',
                    type: SystemNotificationType.info,
                  ),
                  const Spacer(),
                  AppSpacing.gapVertical24,
                  AppButton(
                    key: const Key('transfer_failed_try_again_button'),
                    label: 'Try again',
                    onPressed: () => _handleRetry(ref, op),
                  ),
                  AppSpacing.gapVertical12,
                  AppButton(
                    key: const Key('transfer_failed_back_button'),
                    label: 'Back to wallet',
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
