import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';

/// Centralized project icon abstraction for NovaWallet.
///
/// Transcribed directly from the authoritative NovaWallet Style Guide
/// (`docs/design/pdf/NovaWallet Style Guide.pdf` p. 3) and `docs/DESIGN_SYSTEM.md` §8.
abstract final class AppIcons {
  // --- Navigation & Arrows ---
  static const IconData arrowLeft = Icons.arrow_back_rounded;
  static const IconData arrowUpRight = Icons.arrow_outward_rounded;
  static const IconData arrowDownLeft = Icons.south_west_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronDown = Icons.keyboard_arrow_down_rounded;

  // --- Actions & Status ---
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData alertCircle = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData backspace = Icons.backspace_outlined;

  // --- Connectivity ---
  static const IconData wifi = Icons.wifi_rounded;
  static const IconData wifiOff = Icons.wifi_off_rounded;

  // --- Domain & Features ---
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData piggyBank = Icons.savings_outlined;
  static const IconData target = Icons.track_changes_rounded;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData clock = Icons.schedule_rounded;

  /// All 19 approved icons in the design specification.
  static const List<IconData> all = [
    arrowLeft,
    arrowUpRight,
    arrowDownLeft,
    chevronLeft,
    chevronRight,
    chevronDown,
    refresh,
    alertCircle,
    info,
    wifi,
    wifiOff,
    backspace,
    check,
    close,
    wallet,
    piggyBank,
    target,
    calendar,
    clock,
  ];
}

/// Accessible icon component conforming to NovaWallet accessibility guidelines.
///
/// When [semanticLabel] is provided, screen readers announce the label while
/// excluding raw glyph codes. When [semanticLabel] is null, the icon is marked
/// as decorative and excluded from semantics.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? AppColors.textPrimary;

    return Icon(
      icon,
      size: size,
      color: effectiveColor,
      semanticLabel: semanticLabel,
    );
  }
}
