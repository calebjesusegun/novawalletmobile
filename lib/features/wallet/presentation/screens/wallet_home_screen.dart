import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/design_system/components/empty_states/app_empty_state.dart';
import 'package:novawallet/design_system/components/notifications/app_system_notification.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_projection.dart';
import 'package:novawallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_activity_tile.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_loading_skeleton.dart';
import 'package:novawallet/features/wallet/presentation/widgets/wallet_transaction_detail_sheet.dart';
import 'package:novawallet/sync/application/sync_coordinator_provider.dart';
import 'package:novawallet/sync/application/sync_result.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

/// The primary Wallet Home Screen (UI-WAL-01 through UI-WAL-07).
///
/// Implements requirements:
/// - WAL-001 / ASM-002: Available balance in Naira backed by integer kobo.
/// - WAL-002 / ASM-003: Reverse-chronological activity feed.
/// - WAL-003 / ASM-004: Pull-to-refresh via [RefreshIndicator].
/// - WAL-005 / ASM-009 / UI-WAL-02: Offline notification banner & last-updated balance.
/// - WAL-006 / UI-WAL-03: Pending transfer in recent activity.
/// - WAL-007 / ASM-011 / UI-WAL-04: Reconnect / syncing processing state.
/// - WAL-008 / UI-WAL-05: Confirmed balance update and completed activity.
/// - WAL-009 / UI-WAL-06: Sync failure notification banner with retry action.
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
        loading: () => const WalletLoadingSkeleton(),
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

  Widget? _buildSystemBanner(
    BuildContext context,
    WidgetRef ref, {
    required ConnectivityStatus connectivity,
    required SyncStatus syncStatus,
  }) {
    if (connectivity == ConnectivityStatus.offline) {
      return AppSystemNotification.offline();
    }
    if (syncStatus == SyncStatus.syncing ||
        projection.pendingOperations.any(
          (op) => op.status == OperationStatus.processing,
        )) {
      return AppSystemNotification.backOnline();
    }
    if (syncStatus == SyncStatus.failed || projection.hasSyncFailure) {
      return AppSystemNotification.syncFailure(
        onActionPressed: () {
          ref
              .read(syncCoordinatorProvider)
              .synchronize(trigger: SyncTrigger.userRetry);
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStatusProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final isOffline = connectivity == ConnectivityStatus.offline;
    final banner = _buildSystemBanner(
      context,
      ref,
      connectivity: connectivity,
      syncStatus: syncStatus,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryAction,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner != null) ...[banner, AppSpacing.gapVertical16],
                  WalletBalanceCard(
                    balance: projection.confirmedBalance,
                    lastUpdatedAt: projection.lastUpdatedAt,
                    isOffline: isOffline,
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
                  if (projection.activities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                      child: Text(
                        'Recent Activity',
                        style: AppTypography.titleMedium16.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (projection.activities.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space24,
                  ),
                  child: AppEmptyState.walletTransactions(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              sliver: SliverList.separated(
                itemCount: projection.activities.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                  indent: AppSpacing.space16,
                  endIndent: AppSpacing.space16,
                ),
                itemBuilder: (context, index) {
                  final item = projection.activities[index];
                  return WalletActivityTile(
                    item: item,
                    onTap: () {
                      WalletTransactionDetailSheet.show(
                        context: context,
                        item: item,
                        onRetry: item.hasSyncError
                            ? () {
                                ref
                                    .read(syncCoordinatorProvider)
                                    .synchronize(
                                      trigger: SyncTrigger.userRetry,
                                    );
                              }
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space24)),
        ],
      ),
    );
  }
}
