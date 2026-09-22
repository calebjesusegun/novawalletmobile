import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Centralized text field component for NovaWallet.
///
/// Implements DSN-008, A11Y-001, A11Y-002.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.prefixText,
    this.prefixStyle,
    this.suffixIcon,
    this.suffix,
    this.inputFormatters,
    this.semanticLabel,
  });

  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final Widget? suffixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: AppTypography.labelBold14.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
          AppSpacing.gapVertical8,
        ],
        Semantics(
          label: semanticLabel ?? label,
          textField: true,
          enabled: enabled,
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            focusNode: focusNode,
            autofocus: autofocus,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            readOnly: readOnly,
            enabled: enabled,
            onTap: onTap,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            inputFormatters: inputFormatters,
            style: AppTypography.bodyRegular16.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyRegular16.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: enabled ? AppColors.white : AppColors.grey100,
              prefix: prefix,
              prefixIcon: prefixIcon,
              prefixIconConstraints: prefixIconConstraints,
              prefixText: prefixText,
              prefixStyle: prefixStyle,
              suffixIcon: suffixIcon,
              suffix: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space16,
              ),
              border: const OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(color: AppColors.border, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.border,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.primaryAction,
                  width: 1.5,
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              disabledBorder: const OutlineInputBorder(
                borderRadius: AppRadii.mdBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          AppSpacing.gapVertical4,
          Text(
            errorText!,
            style: AppTypography.labelRegular12.copyWith(
              color: AppColors.error,
            ),
          ),
        ] else if (helperText != null && helperText!.isNotEmpty) ...[
          AppSpacing.gapVertical4,
          Text(
            helperText!,
            style: AppTypography.labelRegular12.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
