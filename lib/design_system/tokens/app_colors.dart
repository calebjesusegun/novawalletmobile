import 'package:flutter/material.dart';

/// Centralized color palette tokens for NovaWallet.
///
/// Transcribed directly from the authoritative NovaWallet Style Guide
/// (`docs/design/pdf/NovaWallet Style Guide.pdf` p. 1) and `docs/DESIGN_SYSTEM.md` §3.
abstract final class AppColors {
  // --- 3.1 Primary Blue ---
  static const Color blue50 = Color(0xFFE6EEF8);
  static const Color blue100 = Color(0xFFC2D3EA);
  static const Color blue200 = Color(0xFF94B0D6);
  static const Color blue300 = Color(0xFF5C84BC);
  static const Color blue400 = Color(0xFF2A5C9E);
  static const Color blue500 = Color(0xFF003A78);
  static const Color blue600 = Color(0xFF00326A);
  static const Color blue700 = Color(0xFF00264F);
  static const Color blue800 = Color(0xFF001C3B);
  static const Color blue900 = Color(0xFF001328);

  // --- 3.2 Secondary Gold ---
  static const Color gold50 = Color(0xFFFFF3CF);
  static const Color gold100 = Color(0xFFFFE69B);
  static const Color gold200 = Color(0xFFFFDA6E);
  static const Color gold300 = Color(0xFFFECB3E);
  static const Color gold400 = Color(0xFFFDC022);
  static const Color gold500 = Color(0xFFFDB913);
  static const Color gold600 = Color(0xFFE0A00B);
  static const Color gold700 = Color(0xFFA67300);
  static const Color gold800 = Color(0xFF7A5600);
  static const Color gold900 = Color(0xFF523A00);

  // --- 3.3 Grey & White ---
  static const Color grey50 = Color(0xFFF4F6F9);
  static const Color grey100 = Color(0xFFE5E9EF);
  static const Color grey200 = Color(0xFFC9D1DC);
  static const Color grey300 = Color(0xFFA3AEBD);
  static const Color grey400 = Color(0xFF7B8799);
  static const Color grey500 = Color(0xFF566275);
  static const Color grey600 = Color(0xFF444F61);
  static const Color grey700 = Color(0xFF303A4A);
  static const Color grey800 = Color(0xFF1C2739);
  static const Color grey900 = Color(0xFF0E1A2B);
  static const Color white = Color(0xFFFFFFFF);

  // --- 3.4 Success Green ---
  static const Color green50 = Color(0xFFE1F3E9);
  static const Color green100 = Color(0xFFB9E2CB);
  static const Color green200 = Color(0xFF8CCFAA);
  static const Color green300 = Color(0xFF5DB98A);
  static const Color green400 = Color(0xFF35A06C);
  static const Color green500 = Color(0xFF17784A);
  static const Color green600 = Color(0xFF136A41);
  static const Color green700 = Color(0xFF0F5A37);
  static const Color green800 = Color(0xFF0B472B);
  static const Color green900 = Color(0xFF073320);

  // --- 3.5 Warning Amber ---
  static const Color amber50 = Color(0xFFFFF0D2);
  static const Color amber100 = Color(0xFFFBDA9C);
  static const Color amber200 = Color(0xFFF7BC57);
  static const Color amber300 = Color(0xFFE89B1F);
  static const Color amber400 = Color(0xFFC77A0A);
  static const Color amber500 = Color(0xFF9A5B00);
  static const Color amber600 = Color(0xFF874F00);
  static const Color amber700 = Color(0xFF6E4000);
  static const Color amber800 = Color(0xFF553200);
  static const Color amber900 = Color(0xFF3D2400);

  // --- 3.6 Error Red ---
  static const Color red50 = Color(0xFFFDE8E6);
  static const Color red100 = Color(0xFFF9C4BF);
  static const Color red200 = Color(0xFFF39B93);
  static const Color red300 = Color(0xFFE86A5F);
  static const Color red400 = Color(0xFFD7473B);
  static const Color red500 = Color(0xFFC22F26);
  static const Color red600 = Color(0xFFA9271F);
  static const Color red700 = Color(0xFF8A1F19);
  static const Color red800 = Color(0xFF6B1813);
  static const Color red900 = Color(0xFF4D110E);

  // --- Semantic Aliases (docs/DESIGN_SYSTEM.md §3.3) ---
  static const Color primaryAction = blue500;
  static const Color primaryActionDisabled = blue200;
  static const Color background = grey50;
  static const Color surface = white;
  static const Color textPrimary = grey900;
  static const Color textSecondary = grey500;
  static const Color textTertiary = grey400;
  static const Color border = grey200;
  static const Color borderSubtle = grey100;
  static const Color success = green500;
  static const Color successSurface = green50;
  static const Color warning = amber500;
  static const Color warningSurface = amber50;
  static const Color error = red500;
  static const Color errorSurface = red50;
}
