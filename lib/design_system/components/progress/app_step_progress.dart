import 'package:flutter/material.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// State of an individual step in [AppStepProgress].
enum StepItemState { completed, active, upcoming, failed }

/// Represents a single step item in the multi-step progress indicator.
@immutable
class StepProgressItem {
  const StepProgressItem({required this.label, required this.state});

  final String label;
  final StepItemState state;
}

/// Centralized 3-step progress track component matching the approved designs
/// (UI-SND-15, UI-SND-16, UI-SND-17, UI-SND-18, UI-NSV-14, UI-NSV-15).
///
/// Implements DSN-013, A11Y-001, A11Y-002.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({super.key, required this.steps, this.semanticLabel})
    : assert(steps.length >= 2, 'AppStepProgress requires at least two steps');

  final List<StepProgressItem> steps;
  final String? semanticLabel;

  /// Factory for the offline Pending transfer state (UI-SND-15 / UI-NSV-14).
  /// Saved (active) -> Sending (upcoming) -> Successful (upcoming).
  factory AppStepProgress.offlinePending({Key? key}) {
    return AppStepProgress(
      key: key,
      semanticLabel: 'Transfer progress: Step 1 of 3: Saved on phone',
      steps: const [
        StepProgressItem(label: 'Saved', state: StepItemState.active),
        StepProgressItem(label: 'Sending', state: StepItemState.upcoming),
        StepProgressItem(label: 'Successful', state: StepItemState.upcoming),
      ],
    );
  }

  /// Factory for the Reconnect Processing state (UI-SND-16).
  /// Saved (completed) -> Sending (active) -> Successful (upcoming).
  factory AppStepProgress.reconnectProcessing({Key? key}) {
    return AppStepProgress(
      key: key,
      semanticLabel: 'Transfer progress: Step 2 of 3: Sending to recipient',
      steps: const [
        StepProgressItem(label: 'Saved', state: StepItemState.completed),
        StepProgressItem(label: 'Sending', state: StepItemState.active),
        StepProgressItem(label: 'Successful', state: StepItemState.upcoming),
      ],
    );
  }

  /// Factory for the Reconnect Success state (UI-SND-17).
  /// Saved (completed) -> Sending (completed) -> Successful (completed).
  factory AppStepProgress.reconnectSuccess({Key? key}) {
    return AppStepProgress(
      key: key,
      semanticLabel: 'Transfer progress: Step 3 of 3: Transfer successful',
      steps: const [
        StepProgressItem(label: 'Saved', state: StepItemState.completed),
        StepProgressItem(label: 'Sending', state: StepItemState.completed),
        StepProgressItem(label: 'Successful', state: StepItemState.completed),
      ],
    );
  }

  /// Factory for the Recoverable Sync Failure state (UI-SND-18).
  /// Saved (completed) -> Not sent (failed) -> Successful (upcoming).
  factory AppStepProgress.syncFailure({Key? key}) {
    return AppStepProgress(
      key: key,
      semanticLabel: 'Transfer progress: Step 2 of 3: Not sent. Tap to retry',
      steps: const [
        StepProgressItem(label: 'Saved', state: StepItemState.completed),
        StepProgressItem(label: 'Not sent', state: StepItemState.failed),
        StepProgressItem(label: 'Successful', state: StepItemState.upcoming),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel =
        semanticLabel ??
        'Multi-step progress: ${steps.map((s) => '${s.label} (${s.state.name})').join(', ')}';

    return Semantics(
      label: effectiveLabel,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepNode(steps[i]),
            if (i < steps.length - 1)
              _buildConnector(
                isActive:
                    steps[i].state == StepItemState.completed ||
                    steps[i].state == StepItemState.active,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepNode(StepProgressItem item) {
    Color nodeColor;
    Color iconColor;
    Color textColor;
    IconData? icon;

    switch (item.state) {
      case StepItemState.completed:
        nodeColor = AppColors.blue500;
        iconColor = AppColors.white;
        textColor = AppColors.textPrimary;
        icon = AppIcons.check;
      case StepItemState.active:
        nodeColor = AppColors.blue500;
        iconColor = AppColors.white;
        textColor = AppColors.textPrimary;
        icon = null;
      case StepItemState.upcoming:
        nodeColor = AppColors.grey200;
        iconColor = AppColors.grey400;
        textColor = AppColors.textSecondary;
        icon = null;
      case StepItemState.failed:
        nodeColor = AppColors.amber500;
        iconColor = AppColors.white;
        textColor = AppColors.amber700;
        icon = AppIcons.alertCircle;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(shape: BoxShape.circle, color: nodeColor),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 14.0, color: iconColor)
                : (item.state == StepItemState.active
                      ? Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                          ),
                        )
                      : null),
          ),
        ),
        AppSpacing.gapVertical4,
        Text(
          item.label,
          style: AppTypography.labelBold12.copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          height: 2.0,
          color: isActive ? AppColors.blue500 : AppColors.grey200,
        ),
      ),
    );
  }
}
