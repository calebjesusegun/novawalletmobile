import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_bottom_nav_bar.dart';
import 'package:novawallet/app/navigation/app_navigation_provider.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/features/novasave/presentation/screens/goals_list_screen.dart';
import 'package:novawallet/features/send_money/presentation/screens/send_money_flow_screen.dart';
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

/// Shell tab for Send Money hosting the recipient entry flow.
class SendMoneyShellTab extends StatelessWidget {
  const SendMoneyShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SendMoneyFlowScreen();
  }
}

/// Shell tab for NovaSave hosting the goals list flow (UI-NSV-01, UI-NSV-03).
class NovaSaveShellTab extends StatelessWidget {
  const NovaSaveShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoalsListScreen();
  }
}
