import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/buttons/app_button.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Centralized bottom-sheet layout for NovaWallet.
///
/// Implements DSN-014, A11Y-001, A11Y-002.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// Convenience function to display an [AppBottomSheet] modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? content,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        subtitle: subtitle,
        content: content,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.xl),
          topRight: Radius.circular(AppRadii.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.space24,
        right: AppSpacing.space24,
        top: AppSpacing.space12,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.grey200,
                borderRadius: AppRadii.pillBorderRadius,
              ),
            ),
          ),
          AppSpacing.gapVertical20,

          // Title
          Text(
            title,
            style: AppTypography.titleBold22,
            textAlign: TextAlign.center,
          ),

          if (subtitle != null && subtitle!.isNotEmpty) ...[
            AppSpacing.gapVertical8,
            Text(
              subtitle!,
              style: AppTypography.bodyRegular14.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (content != null) ...[AppSpacing.gapVertical16, content!],

          if (primaryActionLabel != null) ...[
            AppSpacing.gapVertical24,
            AppButton(
              label: primaryActionLabel!,
              onPressed: onPrimaryAction,
              variant: AppButtonVariant.primary,
            ),
          ],

          if (secondaryActionLabel != null) ...[
            AppSpacing.gapVertical12,
            AppButton(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
              variant: AppButtonVariant.text,
            ),
          ],
        ],
      ),
    );
  }
}
