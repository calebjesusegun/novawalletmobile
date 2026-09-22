import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/cards/app_card.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/send_money/domain/recipient.dart';

/// Card presenting a resolved recipient per UI-SND-04.
///
/// Shows recipient name, bank, account number, and verified check indicator.
class ResolvedRecipientCard extends StatelessWidget {
  const ResolvedRecipientCard({
    super.key,
    required this.recipient,
    this.onClear,
  });

  final Recipient recipient;
  final VoidCallback? onClear;

  String get _initials {
    final parts = recipient.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Resolved recipient: ${recipient.name}, ${recipient.bankName}, account number ${recipient.accountNumber}',
      container: true,
      child: AppCard(
        padding: AppSpacing.insetsAll16,
        child: Row(
          children: [
            // Recipient Avatar circle
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.blue50,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: AppTypography.labelBold14.copyWith(
                  color: AppColors.primaryAction,
                ),
              ),
            ),
            AppSpacing.gapHorizontal12,
            // Recipient details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipient.name,
                    style: AppTypography.titleBold18.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapVertical4,
                  Text(
                    '${recipient.bankName} • ${recipient.accountNumber}',
                    style: AppTypography.bodyRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Verified check icon
            const AppIcon(AppIcons.check, color: AppColors.green500, size: 20),
            if (onClear != null) ...[
              AppSpacing.gapHorizontal8,
              Semantics(
                button: true,
                label: 'Clear recipient',
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onClear,
                  tooltip: 'Change recipient',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
