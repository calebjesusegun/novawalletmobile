import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_elevation.dart';
import 'package:novawallet/design_system/tokens/app_radii.dart';
import 'package:novawallet/design_system/tokens/app_spacing.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

void main() {
  group('DSN-001 — AppColors', () {
    test('Primary Blue palette has exact hex values from style guide', () {
      expect(AppColors.blue50, equals(const Color(0xFFE6EEF8)));
      expect(AppColors.blue100, equals(const Color(0xFFC2D3EA)));
      expect(AppColors.blue200, equals(const Color(0xFF94B0D6)));
      expect(AppColors.blue300, equals(const Color(0xFF5C84BC)));
      expect(AppColors.blue400, equals(const Color(0xFF2A5C9E)));
      expect(AppColors.blue500, equals(const Color(0xFF003A78)));
      expect(AppColors.blue600, equals(const Color(0xFF00326A)));
      expect(AppColors.blue700, equals(const Color(0xFF00264F)));
      expect(AppColors.blue800, equals(const Color(0xFF001C3B)));
      expect(AppColors.blue900, equals(const Color(0xFF001328)));
    });

    test('Secondary Gold palette has exact hex values from style guide', () {
      expect(AppColors.gold50, equals(const Color(0xFFFFF3CF)));
      expect(AppColors.gold100, equals(const Color(0xFFFFE69B)));
      expect(AppColors.gold200, equals(const Color(0xFFFFDA6E)));
      expect(AppColors.gold300, equals(const Color(0xFFFECB3E)));
      expect(AppColors.gold400, equals(const Color(0xFFFDC022)));
      expect(AppColors.gold500, equals(const Color(0xFFFDB913)));
      expect(AppColors.gold600, equals(const Color(0xFFE0A00B)));
      expect(AppColors.gold700, equals(const Color(0xFFA67300)));
      expect(AppColors.gold800, equals(const Color(0xFF7A5600)));
      expect(AppColors.gold900, equals(const Color(0xFF523A00)));
    });

    test('Grey and White palette has exact hex values from style guide', () {
      expect(AppColors.grey50, equals(const Color(0xFFF4F6F9)));
      expect(AppColors.grey100, equals(const Color(0xFFE5E9EF)));
      expect(AppColors.grey200, equals(const Color(0xFFC9D1DC)));
      expect(AppColors.grey300, equals(const Color(0xFFA3AEBD)));
      expect(AppColors.grey400, equals(const Color(0xFF7B8799)));
      expect(AppColors.grey500, equals(const Color(0xFF566275)));
      expect(AppColors.grey600, equals(const Color(0xFF444F61)));
      expect(AppColors.grey700, equals(const Color(0xFF303A4A)));
      expect(AppColors.grey800, equals(const Color(0xFF1C2739)));
      expect(AppColors.grey900, equals(const Color(0xFF0E1A2B)));
      expect(AppColors.white, equals(const Color(0xFFFFFFFF)));
    });

    test('Success Green palette has exact hex values from style guide', () {
      expect(AppColors.green50, equals(const Color(0xFFE1F3E9)));
      expect(AppColors.green100, equals(const Color(0xFFB9E2CB)));
      expect(AppColors.green200, equals(const Color(0xFF8CCFAA)));
      expect(AppColors.green300, equals(const Color(0xFF5DB98A)));
      expect(AppColors.green400, equals(const Color(0xFF35A06C)));
      expect(AppColors.green500, equals(const Color(0xFF17784A)));
      expect(AppColors.green600, equals(const Color(0xFF136A41)));
      expect(AppColors.green700, equals(const Color(0xFF0F5A37)));
      expect(AppColors.green800, equals(const Color(0xFF0B472B)));
      expect(AppColors.green900, equals(const Color(0xFF073320)));
    });

    test('Warning Amber palette has exact hex values from style guide', () {
      expect(AppColors.amber50, equals(const Color(0xFFFFF0D2)));
      expect(AppColors.amber100, equals(const Color(0xFFFBDA9C)));
      expect(AppColors.amber200, equals(const Color(0xFFF7BC57)));
      expect(AppColors.amber300, equals(const Color(0xFFE89B1F)));
      expect(AppColors.amber400, equals(const Color(0xFFC77A0A)));
      expect(AppColors.amber500, equals(const Color(0xFF9A5B00)));
      expect(AppColors.amber600, equals(const Color(0xFF874F00)));
      expect(AppColors.amber700, equals(const Color(0xFF6E4000)));
      expect(AppColors.amber800, equals(const Color(0xFF553200)));
      expect(AppColors.amber900, equals(const Color(0xFF3D2400)));
    });

    test('Error Red palette has exact hex values from style guide', () {
      expect(AppColors.red50, equals(const Color(0xFFFDE8E6)));
      expect(AppColors.red100, equals(const Color(0xFFF9C4BF)));
      expect(AppColors.red200, equals(const Color(0xFFF39B93)));
      expect(AppColors.red300, equals(const Color(0xFFE86A5F)));
      expect(AppColors.red400, equals(const Color(0xFFD7473B)));
      expect(AppColors.red500, equals(const Color(0xFFC22F26)));
      expect(AppColors.red600, equals(const Color(0xFFA9271F)));
      expect(AppColors.red700, equals(const Color(0xFF8A1F19)));
      expect(AppColors.red800, equals(const Color(0xFF6B1813)));
      expect(AppColors.red900, equals(const Color(0xFF4D110E)));
    });

    test('Semantic aliases map to correct style-guide palette values', () {
      expect(AppColors.primaryAction, equals(AppColors.blue500));
      expect(AppColors.primaryActionDisabled, equals(AppColors.blue200));
      expect(AppColors.background, equals(AppColors.grey50));
      expect(AppColors.surface, equals(AppColors.white));
      expect(AppColors.textPrimary, equals(AppColors.grey900));
      expect(AppColors.textSecondary, equals(AppColors.grey500));
      expect(AppColors.textTertiary, equals(AppColors.grey400));
      expect(AppColors.border, equals(AppColors.grey200));
      expect(AppColors.borderSubtle, equals(AppColors.grey100));
      expect(AppColors.success, equals(AppColors.green500));
      expect(AppColors.successSurface, equals(AppColors.green50));
      expect(AppColors.warning, equals(AppColors.amber500));
      expect(AppColors.warningSurface, equals(AppColors.amber50));
      expect(AppColors.error, equals(AppColors.red500));
      expect(AppColors.errorSurface, equals(AppColors.red50));
    });
  });

  group('DSN-002 — AppTypography', () {
    test('fontFamily is Plus Jakarta Sans across all styles', () {
      expect(AppTypography.fontFamily, equals('Plus Jakarta Sans'));
    });

    void verifyStyle(
      TextStyle style, {
      required double fontSize,
      required double lineHeight,
      required double letterSpacing,
      required FontWeight fontWeight,
    }) {
      expect(style.fontFamily, equals('Plus Jakarta Sans'));
      expect(style.fontSize, equals(fontSize));
      expect(style.height, closeTo(lineHeight / fontSize, 0.0001));
      expect(style.letterSpacing, equals(letterSpacing));
      expect(style.fontWeight, equals(fontWeight));
    }

    test('All 14 Bold styles match approved typography scale', () {
      verifyStyle(
        AppTypography.headlineBold40,
        fontSize: 40,
        lineHeight: 48,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.headlineBold32,
        fontSize: 32,
        lineHeight: 40,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.headlineBold28,
        fontSize: 28,
        lineHeight: 36,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.headlineBold24,
        fontSize: 24,
        lineHeight: 32,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.titleBold22,
        fontSize: 22,
        lineHeight: 28,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.titleBold18,
        fontSize: 18,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.titleBold16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.titleBold14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.labelBold14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.labelBold12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.labelBold11,
        fontSize: 11,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.bodyBold16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.bodyBold14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w700,
      );
      verifyStyle(
        AppTypography.bodyBold12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.40,
        fontWeight: FontWeight.w700,
      );
    });

    test('All 12 Medium styles match approved typography scale', () {
      verifyStyle(
        AppTypography.headlineMedium32,
        fontSize: 32,
        lineHeight: 40,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.headlineMedium28,
        fontSize: 28,
        lineHeight: 36,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.headlineMedium24,
        fontSize: 24,
        lineHeight: 32,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.titleMedium22,
        fontSize: 22,
        lineHeight: 28,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.titleMedium16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.titleMedium14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.labelMedium14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.labelMedium12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.labelMedium11,
        fontSize: 11,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.bodyMedium16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.bodyMedium14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w500,
      );
      verifyStyle(
        AppTypography.bodyMedium12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.40,
        fontWeight: FontWeight.w500,
      );
    });

    test('All 12 Regular styles match approved typography scale', () {
      verifyStyle(
        AppTypography.headlineRegular32,
        fontSize: 32,
        lineHeight: 40,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.headlineRegular28,
        fontSize: 28,
        lineHeight: 36,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.headlineRegular24,
        fontSize: 24,
        lineHeight: 32,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.titleRegular22,
        fontSize: 22,
        lineHeight: 28,
        letterSpacing: 0,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.titleRegular16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.titleRegular14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.labelRegular14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.10,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.labelRegular12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.labelRegular11,
        fontSize: 11,
        lineHeight: 16,
        letterSpacing: 0.50,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.bodyRegular16,
        fontSize: 16,
        lineHeight: 24,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.bodyRegular14,
        fontSize: 14,
        lineHeight: 20,
        letterSpacing: 0.25,
        fontWeight: FontWeight.w400,
      );
      verifyStyle(
        AppTypography.bodyRegular12,
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 0.40,
        fontWeight: FontWeight.w400,
      );
    });

    test('toTextTheme generates valid Material 3 text theme', () {
      final textTheme = AppTypography.toTextTheme();
      expect(textTheme.displayLarge?.fontFamily, equals('Plus Jakarta Sans'));
      expect(textTheme.headlineMedium?.fontSize, equals(24));
      expect(textTheme.bodyLarge?.fontSize, equals(16));
      expect(textTheme.labelLarge?.fontSize, equals(14));
    });
  });

  group('DSN-004 — AppSpacing', () {
    test('Spacing values match approved 4-32 scale', () {
      expect(AppSpacing.space4, equals(4.0));
      expect(AppSpacing.space8, equals(8.0));
      expect(AppSpacing.space12, equals(12.0));
      expect(AppSpacing.space16, equals(16.0));
      expect(AppSpacing.space20, equals(20.0));
      expect(AppSpacing.space24, equals(24.0));
      expect(AppSpacing.space32, equals(32.0));
    });

    test('EdgeInsets helpers are configured accurately', () {
      expect(AppSpacing.insetsAll4, equals(const EdgeInsets.all(4.0)));
      expect(AppSpacing.insetsAll16, equals(const EdgeInsets.all(16.0)));
      expect(
        AppSpacing.insetsHorizontal16,
        equals(const EdgeInsets.symmetric(horizontal: 16.0)),
      );
      expect(
        AppSpacing.insetsVertical24,
        equals(const EdgeInsets.symmetric(vertical: 24.0)),
      );
    });

    test('SizedBox gap helpers have correct dimensions', () {
      expect(AppSpacing.gapVertical8.height, equals(8.0));
      expect(AppSpacing.gapHorizontal12.width, equals(12.0));
    });
  });

  group('DSN-005 — AppRadii', () {
    test('Radius scale matches approved values', () {
      expect(AppRadii.sm, equals(8.0));
      expect(AppRadii.md, equals(12.0));
      expect(AppRadii.lg, equals(16.0));
      expect(AppRadii.xl, equals(24.0));
      expect(AppRadii.pill, equals(999.0));
    });

    test('BorderRadius objects match respective radius values', () {
      expect(
        AppRadii.smBorderRadius,
        equals(const BorderRadius.all(Radius.circular(8.0))),
      );
      expect(
        AppRadii.mdBorderRadius,
        equals(const BorderRadius.all(Radius.circular(12.0))),
      );
      expect(
        AppRadii.lgBorderRadius,
        equals(const BorderRadius.all(Radius.circular(16.0))),
      );
      expect(
        AppRadii.xlBorderRadius,
        equals(const BorderRadius.all(Radius.circular(24.0))),
      );
      expect(
        AppRadii.pillBorderRadius,
        equals(const BorderRadius.all(Radius.circular(999.0))),
      );
    });
  });

  group('DSN-006 — AppElevation', () {
    test('Shadow matches approved elevation specification', () {
      expect(AppElevation.yOffset, equals(4.0));
      expect(AppElevation.blur, equals(48.0));
      expect(AppElevation.opacity, equals(0.02));
      expect(
        AppElevation.shadowColor,
        equals(const Color.fromRGBO(14, 26, 43, 0.02)),
      );

      const shadow = AppElevation.cardShadow;
      expect(shadow.offset, equals(const Offset(0, 4.0)));
      expect(shadow.blurRadius, equals(48.0));
      expect(shadow.spreadRadius, equals(0.0));
      expect(shadow.color, equals(const Color.fromRGBO(14, 26, 43, 0.02)));
    });
  });
}
