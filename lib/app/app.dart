import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_bottom_nav_bar.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/design_system/components/empty_states/app_empty_state.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';
import 'package:novawallet/features/wallet/presentation/screens/wallet_home_screen.dart';

/// The root application widget for NovaWallet.
///
/// Configures MaterialApp with the centralized theme and navigation shell.
class NovaWalletApp extends StatelessWidget {
  const NovaWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NovaWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const NovaWalletShell(),
    );
  }
}

/// The top-level application shell hosting the bottom navigation bar and active tab.
class NovaWalletShell extends ConsumerWidget {
  const NovaWalletShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDestination = ref.watch(appNavigationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: currentDestination.index,
          children: const [
            WalletHomeScreen(),
            SendMoneyShellTab(),
            NovaSaveShellTab(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentDestination: currentDestination,
        onDestinationSelected: (destination) {
          ref
              .read(appNavigationProvider.notifier)
              .selectDestination(destination);
        },
      ),
    );
  }
}

/// Placeholder shell tab for Send Money (Phase 6 will implement full flow).
class SendMoneyShellTab extends StatelessWidget {
  const SendMoneyShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: const Center(
        child: Padding(
          padding: AppSpacing.insetsAll24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.arrowUpRight,
                size: 48,
                color: AppColors.primaryAction,
              ),
              AppSpacing.gapVertical16,
              Text('Send Money', style: AppTypography.titleBold22),
              AppSpacing.gapVertical8,
              Text(
                'Transfer funds securely even while offline.',
                style: AppTypography.bodyRegular14,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder shell tab for NovaSave (Phase 7 will implement full flow).
class NovaSaveShellTab extends StatelessWidget {
  const NovaSaveShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NovaSave')),
      body: AppEmptyState.novaSaveGoals(),
    );
  }
}
