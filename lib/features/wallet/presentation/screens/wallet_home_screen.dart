import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_recent_activity_section.dart';

/// The primary Wallet Home Screen (UI-WAL-01).
///
/// Implements requirements:
/// - WAL-001 / ASM-002: Available balance in Naira backed by integer kobo.
/// - WAL-002 / ASM-003: Reverse-chronological activity feed.
/// - WAL-003 / ASM-004: Pull-to-refresh via [RefreshIndicator].
/// - ASM-017 / PERF-001: Lazy-rendered activity list.
/// - UI-WAL-01: Default layout with shortcuts to Send Money and NovaSave.
/// - UI-WAL-07: Refreshing presentation.
class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectionAsync = ref.watch(walletProjectionProvider);
    final refreshState = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NovaWallet', style: AppTypography.titleBold18),
        elevation: 0,
        backgroundColor: AppColors.surface,
        centerTitle: false,
      ),
      body: projectionAsync.when(
        data: (projection) => _WalletContent(
          projection: projection,
          isRefreshing: refreshState.isLoading,
          onRefresh: () =>
              ref.read(walletControllerProvider.notifier).refresh(),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAction),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppSpacing.insetsAll24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to load wallet',
                  style: AppTypography.titleBold18.copyWith(
                    color: AppColors.error,
                  ),
                ),
                AppSpacing.gapVertical8,
                Text(
                  error.toString(),
                  style: AppTypography.bodyRegular14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVertical16,
                TextButton(
                  onPressed: () =>
                      ref.read(walletControllerProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletContent extends ConsumerWidget {
  final WalletProjection projection;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _WalletContent({
    required this.projection,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryAction,
      backgroundColor: AppColors.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space16,
        ),
        children: [
          WalletBalanceCard(
            balance: projection.confirmedBalance,
            isRefreshing: isRefreshing,
            onSendMoneyTap: () {
              ref
                  .read(appNavigationProvider.notifier)
                  .selectDestination(AppDestination.send);
            },
            onNovaSaveTap: () {
              ref
                  .read(appNavigationProvider.notifier)
                  .selectDestination(AppDestination.novaSave);
            },
          ),
          AppSpacing.gapVertical24,
          WalletRecentActivitySection(activities: projection.activities),
        ],
      ),
    );
  }
}
