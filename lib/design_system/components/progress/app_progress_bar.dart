import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';

/// Centralized horizontal progress bar component for NovaSave.
///
/// Implements DSN-013, A11Y-001.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.fillColor = AppColors.blue500,
    this.backgroundColor = AppColors.grey100,
    this.semanticLabel,
  });

  /// Progress fraction between 0.0 and 1.0.
  final double progress;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentageText = (clampedProgress * 100).toInt();

    return Semantics(
      label: semanticLabel ?? 'Savings progress: $percentageText percent',
      value: '$percentageText%',
      child: ClipRRect(
        borderRadius: AppRadii.pillBorderRadius,
        child: Container(
          height: height,
          width: double.infinity,
          color: backgroundColor,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedProgress,
            child: Container(color: fillColor),
          ),
        ),
      ),
    );
  }
}
