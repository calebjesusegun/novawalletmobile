import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Key-value information row used in confirmation and detail views.
///
/// Implements DSN-012, A11Y-001, A11Y-002.
class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.isBoldValue = true,
  }) : assert(
         value != null || valueWidget != null,
         'Either value or valueWidget must be provided',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isBoldValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodyRegular14.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppSpacing.gapHorizontal16,
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value!,
                    textAlign: TextAlign.right,
                    style:
                        (isBoldValue
                                ? AppTypography.bodyBold14
                                : AppTypography.bodyRegular14)
                            .copyWith(color: AppColors.textPrimary),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
