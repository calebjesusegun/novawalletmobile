import 'package:flutter/material.dart';
import 'package:novawallet/design_system/components/empty_states/app_empty_state.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/domain/wallet_activity_item.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';

/// Recent Activity section of the Wallet feed.
///
/// Implements requirements:
/// - WAL-002 / ASM-003: Reverse-chronological list of recent activity items.
/// - WAL-004 / UI-WAL-09: Empty state when no transactions exist.
/// - ASM-017 / PERF-001 / HC-PERFORMANCE: Lazy rendering via [ListView.builder]
///   or [SliverList.builder].
class WalletRecentActivitySection extends StatelessWidget {
  final List<WalletActivityItem> activities;
  final void Function(WalletActivityItem item)? onItemTap;

  const WalletRecentActivitySection({
    super.key,
    required this.activities,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space24),
        child: AppEmptyState.walletTransactions(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          child: Text(
            'Recent Activity',
            style: AppTypography.titleMedium16.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
            indent: AppSpacing.space16,
            endIndent: AppSpacing.space16,
          ),
          itemBuilder: (context, index) {
            final item = activities[index];
            return WalletActivityTile(
              item: item,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            );
          },
        ),
      ],
    );
  }
}
