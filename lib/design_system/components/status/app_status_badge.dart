import 'package:flutter/material.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

enum AppOperationStatus { completed, pending, processing, failed }

/// Centralized status badge component for NovaWallet operations.
///
/// Implements DSN-010, A11Y-001, A11Y-002.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.status, this.customLabel});

  final AppOperationStatus status;
  final String? customLabel;

  String get label {
    if (customLabel != null) return customLabel!;
    switch (status) {
      case AppOperationStatus.completed:
        return 'Completed';
      case AppOperationStatus.pending:
        return 'Pending';
      case AppOperationStatus.processing:
        return 'Processing';
      case AppOperationStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    IconData icon;

    switch (status) {
      case AppOperationStatus.completed:
        backgroundColor = AppColors.green50;
        foregroundColor = AppColors.green600;
        borderColor = AppColors.green200;
        icon = AppIcons.check;
      case AppOperationStatus.pending:
        backgroundColor = AppColors.amber50;
        foregroundColor = AppColors.amber600;
        borderColor = AppColors.amber200;
        icon = AppIcons.clock;
      case AppOperationStatus.processing:
        backgroundColor = AppColors.blue50;
        foregroundColor = AppColors.blue600;
        borderColor = AppColors.blue200;
        icon = AppIcons.refresh;
      case AppOperationStatus.failed:
        backgroundColor = AppColors.red50;
        foregroundColor = AppColors.red600;
        borderColor = AppColors.red200;
        icon = AppIcons.close;
    }

    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.pillBorderRadius,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: AppSpacing.space4),
            Text(
              label,
              style: AppTypography.labelBold11.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}
