import 'package:flutter/material.dart';

/// Centralized elevation and shadow tokens for NovaWallet.
///
/// Transcribed directly from the authoritative NovaWallet Style Guide
/// (`docs/design/pdf/NovaWallet Style Guide.pdf` p. 4) and `docs/DESIGN_SYSTEM.md` §7.
///
/// Specification:
/// - Y offset: 4
/// - Blur: 48
/// - Opacity: 2%
/// - Base color: grey-900 (`#0E1A2B`)
abstract final class AppElevation {
  static const double yOffset = 4.0;
  static const double blur = 48.0;
  static const double opacity = 0.02;
  static const Color shadowColor = Color.fromRGBO(14, 26, 43, opacity);

  static const BoxShadow cardShadow = BoxShadow(
    color: shadowColor,
    offset: Offset(0, yOffset),
    blurRadius: blur,
    spreadRadius: 0,
  );

  static const List<BoxShadow> cardBoxShadows = [cardShadow];
}
