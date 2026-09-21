import 'package:flutter/material.dart';
import 'package:novawallet/app/navigation/app_destination.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Centralized bottom navigation bar matching UI-CMP-05.
///
/// Implements DSN-011, A11Y-001.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  final AppDestination currentDestination;
  final ValueChanged<AppDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                destination: AppDestination.wallet,
                icon: AppIcons.wallet,
              ),
              _buildNavItem(
                destination: AppDestination.send,
                icon: AppIcons.arrowUpRight,
              ),
              _buildNavItem(
                destination: AppDestination.novaSave,
                icon: AppIcons.piggyBank,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required AppDestination destination,
    required IconData icon,
  }) {
    final isSelected = currentDestination == destination;
    final color = isSelected ? AppColors.primaryAction : AppColors.grey400;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '${destination.label} tab',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onDestinationSelected(destination),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24.0, color: color),
              AppSpacing.gapVertical4,
              Text(
                destination.label,
                style:
                    (isSelected
                            ? AppTypography.labelBold12
                            : AppTypography.labelRegular12)
                        .copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
