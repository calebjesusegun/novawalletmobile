import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/design_system/icons/app_icons.dart';
import 'package:novawallet/design_system/tokens/app_colors.dart';

void main() {
  group('DSN-003 — AppIcons abstraction', () {
    test('Exposes all 19 approved design-system icons', () {
      expect(AppIcons.all.length, equals(19));
      expect(AppIcons.arrowLeft, isA<IconData>());
      expect(AppIcons.arrowUpRight, isA<IconData>());
      expect(AppIcons.arrowDownLeft, isA<IconData>());
      expect(AppIcons.chevronLeft, isA<IconData>());
      expect(AppIcons.chevronRight, isA<IconData>());
      expect(AppIcons.chevronDown, isA<IconData>());
      expect(AppIcons.refresh, isA<IconData>());
      expect(AppIcons.alertCircle, isA<IconData>());
      expect(AppIcons.info, isA<IconData>());
      expect(AppIcons.wifi, isA<IconData>());
      expect(AppIcons.wifiOff, isA<IconData>());
      expect(AppIcons.backspace, isA<IconData>());
      expect(AppIcons.check, isA<IconData>());
      expect(AppIcons.close, isA<IconData>());
      expect(AppIcons.wallet, isA<IconData>());
      expect(AppIcons.piggyBank, isA<IconData>());
      expect(AppIcons.target, isA<IconData>());
      expect(AppIcons.calendar, isA<IconData>());
      expect(AppIcons.clock, isA<IconData>());
    });

    testWidgets('AppIcon renders with specified size and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon(
              AppIcons.wallet,
              size: 32.0,
              color: AppColors.blue500,
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, equals(AppIcons.wallet));
      expect(iconWidget.size, equals(32.0));
      expect(iconWidget.color, equals(AppColors.blue500));
    });

    testWidgets(
      'AppIcon with semanticLabel creates Semantics node and excludes glyph',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppIcon(
                AppIcons.arrowLeft,
                semanticLabel: 'Back to wallet',
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Back to wallet'), findsOneWidget);

        handle.dispose();
      },
    );

    testWidgets(
      'AppIcon without semanticLabel excludes icon from semantics tree',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: AppIcon(AppIcons.arrowLeft))),
        );

        expect(
          find.descendant(
            of: find.byType(AppIcon),
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );

        handle.dispose();
      },
    );
  });
}
