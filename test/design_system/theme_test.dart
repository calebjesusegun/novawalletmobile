import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/theme/app_theme.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';
import 'package:novawallet/design_system/tokens/app_typography.dart';

void main() {
  group('DSN-002 / DSN-001 — AppTheme.light', () {
    test('Configures ThemeData correctly with tokens', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
      expect(theme.colorScheme.primary, equals(AppColors.primaryAction));
      expect(theme.colorScheme.secondary, equals(AppColors.gold500));
      expect(theme.colorScheme.surface, equals(AppColors.surface));
      expect(theme.colorScheme.error, equals(AppColors.error));
      expect(theme.cardTheme.color, equals(AppColors.surface));
      expect(theme.cardTheme.elevation, equals(0));
      expect(theme.appBarTheme.backgroundColor, equals(AppColors.white));
      expect(theme.appBarTheme.elevation, equals(0));
      expect(
        theme.appBarTheme.titleTextStyle,
        equals(AppTypography.titleBold18),
      );
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        equals('Plus Jakarta Sans'),
      );
    });

    testWidgets('AppTheme integrates properly into MaterialApp widget tree', (
      tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('Design System Active'));
            },
          ),
        ),
      );

      final theme = Theme.of(capturedContext);
      expect(theme.colorScheme.primary, equals(AppColors.blue500));
      expect(theme.colorScheme.surface, equals(AppColors.white));
      expect(find.text('Design System Active'), findsOneWidget);
    });
  });
}
