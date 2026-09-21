import 'package:flutter/material.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

/// Centralized theme definition for NovaWallet.
///
/// Implements DSN-002, DSN-001, DSN-004, DSN-005, DSN-006 using centralized tokens.
abstract final class AppTheme {
  /// Canonical Light ThemeData configured for NovaWallet.
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryAction,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.blue50,
      onPrimaryContainer: AppColors.blue900,
      secondary: AppColors.gold500,
      onSecondary: AppColors.grey900,
      secondaryContainer: AppColors.gold50,
      onSecondaryContainer: AppColors.gold900,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.white,
      surfaceContainer: AppColors.grey50,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.red900,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.toTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleBold18,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: AppRadii.lgShape,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    );
  }
}
