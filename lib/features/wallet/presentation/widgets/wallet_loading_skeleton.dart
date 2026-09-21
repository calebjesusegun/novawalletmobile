import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';

/// Skeleton placeholder matching UI-WAL-08 for the Wallet home screen.
///
/// Implements requirements:
/// - WAL-010 / UI-WAL-08: Skeleton loading states for balance card and activity list.
/// - A11Y-001: Exposes accessible semantics indicating loading state.
class WalletLoadingSkeleton extends StatelessWidget {
  const WalletLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading wallet data',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        children: [
          _buildBalanceCardSkeleton(),
          AppSpacing.gapVertical24,
          _buildRecentActivitySkeleton(),
        ],
      ),
    );
  }

  Widget _buildBalanceCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.lgBorderRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Available Balance" placeholder
          _buildSkeletonBox(width: 110, height: 14),
          AppSpacing.gapVertical12,
          // Large balance amount placeholder
          _buildSkeletonBox(width: 180, height: 32),
          AppSpacing.gapVertical20,
          // Two action button placeholders
          Row(
            children: [
              Expanded(
                child: _buildSkeletonBox(
                  height: 44,
                  borderRadius: AppRadii.pillBorderRadius,
                ),
              ),
              AppSpacing.gapHorizontal12,
              Expanded(
                child: _buildSkeletonBox(
                  height: 44,
                  borderRadius: AppRadii.pillBorderRadius,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          child: _buildSkeletonBox(width: 120, height: 16),
        ),
        AppSpacing.gapVertical8,
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.lgBorderRadius,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: List.generate(4, (index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space12,
                    ),
                    child: Row(
                      children: [
                        // Circular icon placeholder
                        _buildSkeletonBox(
                          width: 40,
                          height: 40,
                          borderRadius: AppRadii.pillBorderRadius,
                        ),
                        AppSpacing.gapHorizontal12,
                        // Title & subtitle placeholders
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSkeletonBox(width: 130, height: 14),
                              AppSpacing.gapVertical4,
                              _buildSkeletonBox(width: 80, height: 12),
                            ],
                          ),
                        ),
                        // Trailing amount & badge placeholder
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildSkeletonBox(width: 70, height: 14),
                            AppSpacing.gapVertical4,
                            _buildSkeletonBox(
                              width: 55,
                              height: 14,
                              borderRadius: AppRadii.smBorderRadius,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (index < 3)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                      indent: AppSpacing.space16,
                      endIndent: AppSpacing.space16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({
    double? width,
    required double height,
    BorderRadiusGeometry? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: borderRadius ?? AppRadii.smBorderRadius,
      ),
    );
  }
}
