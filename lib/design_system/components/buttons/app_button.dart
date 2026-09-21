import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text }

/// Centralized accessible button component for NovaWallet.
///
/// Implements DSN-007, A11Y-001, A11Y-002.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  bool get isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ?? label;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled
            ? AppColors.primaryAction
            : AppColors.primaryActionDisabled;
        foregroundColor = AppColors.white;
        border = BorderSide.none;
      case AppButtonVariant.secondary:
        backgroundColor = isEnabled ? AppColors.gold500 : AppColors.gold100;
        foregroundColor = isEnabled ? AppColors.grey900 : AppColors.grey400;
        border = BorderSide.none;
      case AppButtonVariant.outline:
        backgroundColor = AppColors.white;
        foregroundColor = isEnabled ? AppColors.grey900 : AppColors.grey400;
        border = BorderSide(
          color: isEnabled ? AppColors.border : AppColors.borderSubtle,
          width: 1.5,
        );
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? AppColors.primaryAction
            : AppColors.grey400;
        border = BorderSide.none;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          AppSpacing.gapHorizontal8,
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: foregroundColor),
          AppSpacing.gapHorizontal8,
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelBold14.copyWith(color: foregroundColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          AppSpacing.gapHorizontal8,
          Icon(trailingIcon, size: 20, color: foregroundColor),
        ],
      ],
    );

    final buttonWidget = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isFullWidth ? double.infinity : 48.0,
        minHeight: 48.0,
      ),
      child: Material(
        color: backgroundColor,
        shape: AppRadii.mdShape.copyWith(side: border),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppRadii.mdBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: effectiveSemanticLabel,
      excludeSemantics: true,
      child: buttonWidget,
    );
  }
}
