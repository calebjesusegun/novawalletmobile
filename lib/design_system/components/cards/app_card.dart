import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_elevation.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';

/// Centralized card container component for NovaWallet.
///
/// Implements DSN-012, DSN-006, A11Y-001.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.insetsAll16,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.borderSubtle,
    this.borderRadius = AppRadii.lgBorderRadius,
    this.hasShadow = true,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final bool hasShadow;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: hasShadow ? AppElevation.cardBoxShadows : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        container: true,
        label: semanticLabel,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
