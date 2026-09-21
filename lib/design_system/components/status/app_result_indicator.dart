import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/status/app_status_badge.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';

/// Hero result indicator for success, pending, processing, and failure screens.
///
/// Implements DSN-010, A11Y-001.
class AppResultIndicator extends StatelessWidget {
  const AppResultIndicator({
    super.key,
    required this.status,
    this.size = 64.0,
    this.semanticLabel,
  });

  final AppOperationStatus status;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String defaultLabel;

    switch (status) {
      case AppOperationStatus.completed:
        backgroundColor = AppColors.green50;
        iconColor = AppColors.green600;
        icon = AppIcons.check;
        defaultLabel = 'Operation completed successfully';
      case AppOperationStatus.pending:
        backgroundColor = AppColors.amber50;
        iconColor = AppColors.amber600;
        icon = AppIcons.clock;
        defaultLabel = 'Operation pending synchronization';
      case AppOperationStatus.processing:
        backgroundColor = AppColors.blue50;
        iconColor = AppColors.blue600;
        icon = AppIcons.refresh;
        defaultLabel = 'Operation currently processing';
      case AppOperationStatus.failed:
        backgroundColor = AppColors.red50;
        iconColor = AppColors.red600;
        icon = AppIcons.close;
        defaultLabel = 'Operation failed';
    }

    return Semantics(
      label: semanticLabel ?? defaultLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: size * 0.5, color: iconColor),
        ),
      ),
    );
  }
}
