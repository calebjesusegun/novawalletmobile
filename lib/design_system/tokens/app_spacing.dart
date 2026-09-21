import 'package:flutter/widgets.dart';

/// Centralized spacing scale tokens for NovaWallet.
///
/// Transcribed directly from the authoritative NovaWallet Style Guide
/// (`docs/design/pdf/NovaWallet Style Guide.pdf` p. 4) and `docs/DESIGN_SYSTEM.md` §5.
abstract final class AppSpacing {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // --- EdgeInsets: All ---
  static const EdgeInsets insetsAll4 = EdgeInsets.all(space4);
  static const EdgeInsets insetsAll8 = EdgeInsets.all(space8);
  static const EdgeInsets insetsAll12 = EdgeInsets.all(space12);
  static const EdgeInsets insetsAll16 = EdgeInsets.all(space16);
  static const EdgeInsets insetsAll20 = EdgeInsets.all(space20);
  static const EdgeInsets insetsAll24 = EdgeInsets.all(space24);
  static const EdgeInsets insetsAll32 = EdgeInsets.all(space32);

  // --- EdgeInsets: Horizontal ---
  static const EdgeInsets insetsHorizontal4 = EdgeInsets.symmetric(
    horizontal: space4,
  );
  static const EdgeInsets insetsHorizontal8 = EdgeInsets.symmetric(
    horizontal: space8,
  );
  static const EdgeInsets insetsHorizontal12 = EdgeInsets.symmetric(
    horizontal: space12,
  );
  static const EdgeInsets insetsHorizontal16 = EdgeInsets.symmetric(
    horizontal: space16,
  );
  static const EdgeInsets insetsHorizontal20 = EdgeInsets.symmetric(
    horizontal: space20,
  );
  static const EdgeInsets insetsHorizontal24 = EdgeInsets.symmetric(
    horizontal: space24,
  );
  static const EdgeInsets insetsHorizontal32 = EdgeInsets.symmetric(
    horizontal: space32,
  );

  // --- EdgeInsets: Vertical ---
  static const EdgeInsets insetsVertical4 = EdgeInsets.symmetric(
    vertical: space4,
  );
  static const EdgeInsets insetsVertical8 = EdgeInsets.symmetric(
    vertical: space8,
  );
  static const EdgeInsets insetsVertical12 = EdgeInsets.symmetric(
    vertical: space12,
  );
  static const EdgeInsets insetsVertical16 = EdgeInsets.symmetric(
    vertical: space16,
  );
  static const EdgeInsets insetsVertical20 = EdgeInsets.symmetric(
    vertical: space20,
  );
  static const EdgeInsets insetsVertical24 = EdgeInsets.symmetric(
    vertical: space24,
  );
  static const EdgeInsets insetsVertical32 = EdgeInsets.symmetric(
    vertical: space32,
  );

  // --- SizedBox vertical gap helpers ---
  static const SizedBox gapVertical4 = SizedBox(height: space4);
  static const SizedBox gapVertical8 = SizedBox(height: space8);
  static const SizedBox gapVertical12 = SizedBox(height: space12);
  static const SizedBox gapVertical16 = SizedBox(height: space16);
  static const SizedBox gapVertical20 = SizedBox(height: space20);
  static const SizedBox gapVertical24 = SizedBox(height: space24);
  static const SizedBox gapVertical32 = SizedBox(height: space32);

  // --- SizedBox horizontal gap helpers ---
  static const SizedBox gapHorizontal4 = SizedBox(width: space4);
  static const SizedBox gapHorizontal8 = SizedBox(width: space8);
  static const SizedBox gapHorizontal12 = SizedBox(width: space12);
  static const SizedBox gapHorizontal16 = SizedBox(width: space16);
  static const SizedBox gapHorizontal20 = SizedBox(width: space20);
  static const SizedBox gapHorizontal24 = SizedBox(width: space24);
  static const SizedBox gapHorizontal32 = SizedBox(width: space32);
}
