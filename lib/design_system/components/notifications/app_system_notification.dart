import 'package:flutter/material.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

enum SystemNotificationType {
  offline,
  backOnline,
  syncFailure,
  savedOnPhone,
  info,
}

/// Centralized system notification banner component for NovaWallet.
///
/// Implements DSN-009, A11Y-001, A11Y-002.
class AppSystemNotification extends StatelessWidget {
  const AppSystemNotification({
    super.key,
    required this.message,
    required this.type,
    this.title,
    this.actionLabel,
    this.onActionPressed,
    this.semanticLabel,
  });

  final String message;
  final SystemNotificationType type;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final String? semanticLabel;

  /// Factory for offline state notification.
  factory AppSystemNotification.offline({
    Key? key,
    String message = "You're offline. Requests are queued securely and will process when you're back online.",
    String? title,
  }) {
    return AppSystemNotification(
      key: key,
      title: title,
      message: message,
      type: SystemNotificationType.offline,
    );
  }

  /// Factory for back-online / reconnecting notification.
  factory AppSystemNotification.backOnline({
    Key? key,
    String message = 'Back online. Syncing pending actions...',
    String? title,
  }) {
    return AppSystemNotification(
      key: key,
      title: title,
      message: message,
      type: SystemNotificationType.backOnline,
    );
  }

  /// Factory for sync failure notification.
  factory AppSystemNotification.syncFailure({
    Key? key,
    String message = "Couldn't sync pending actions. Your funds and requests are queued securely.",
    String? title,
    String? actionLabel = 'Retry',
    VoidCallback? onActionPressed,
  }) {
    return AppSystemNotification(
      key: key,
      title: title,
      message: message,
      type: SystemNotificationType.syncFailure,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// Factory for saved-on-phone / queued-securely notification.
  factory AppSystemNotification.savedOnPhone({
    Key? key,
    String message = 'Queued securely. Will be submitted once connected.',
    String? title,
  }) {
    return AppSystemNotification(
      key: key,
      title: title,
      message: message,
      type: SystemNotificationType.savedOnPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color foregroundColor;
    IconData icon;

    switch (type) {
      case SystemNotificationType.offline:
        backgroundColor = AppColors.amber50;
        borderColor = AppColors.amber200;
        foregroundColor = AppColors.amber900;
        icon = AppIcons.wifiOff;
      case SystemNotificationType.backOnline:
        backgroundColor = AppColors.green50;
        borderColor = AppColors.green200;
        foregroundColor = AppColors.green900;
        icon = AppIcons.wifi;
      case SystemNotificationType.syncFailure:
        backgroundColor = AppColors.red50;
        borderColor = AppColors.red200;
        foregroundColor = AppColors.red900;
        icon = AppIcons.alertCircle;
      case SystemNotificationType.savedOnPhone:
      case SystemNotificationType.info:
        backgroundColor = AppColors.blue50;
        borderColor = AppColors.blue200;
        foregroundColor = AppColors.blue900;
        icon = AppIcons.info;
    }

    return Semantics(
      container: true,
      label: semanticLabel ?? (title != null ? '$title: $message' : message),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.mdBorderRadius,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foregroundColor),
            AppSpacing.gapHorizontal12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null && title!.isNotEmpty) ...[
                    Text(
                      title!,
                      style: AppTypography.labelBold14.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    AppSpacing.gapVertical4,
                  ],
                  Text(
                    message,
                    style: AppTypography.bodyRegular14.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                  if (actionLabel != null && onActionPressed != null) ...[
                    AppSpacing.gapVertical8,
                    InkWell(
                      onTap: onActionPressed,
                      child: Text(
                        actionLabel!,
                        style: AppTypography.labelBold14.copyWith(
                          color: foregroundColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
