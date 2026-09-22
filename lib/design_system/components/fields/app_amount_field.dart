import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/fields/currency_amount_input_formatter.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Specialized amount entry field for Send Money and NovaSave.
///
/// Implements DSN-008, A11Y-001, A11Y-002.
class AppAmountField extends StatelessWidget {
  const AppAmountField({
    super.key,
    this.controller,
    this.currencySymbol = '₦',
    this.hintText = '0.00',
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.focusNode,
    this.semanticLabel = 'Enter amount in Naira',
  });

  final TextEditingController? controller;
  final String currencySymbol;
  final String hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: semanticLabel,
          textField: true,
          enabled: enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => focusNode?.requestFocus() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: enabled ? AppColors.white : AppColors.grey100,
                borderRadius: AppRadii.mdBorderRadius,
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : (enabled ? AppColors.border : AppColors.borderSubtle),
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      currencySymbol,
                      style: AppTypography.headlineBold32.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontal8,
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [CurrencyAmountInputFormatter()],
                      onChanged: onChanged,
                      style: AppTypography.headlineBold32.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: hintText,
                        hintStyle: AppTypography.headlineBold32.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
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
