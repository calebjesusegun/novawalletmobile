import 'package:flutter/material.dart';

/// Centralized radius tokens for NovaWallet.
///
/// Transcribed directly from the authoritative NovaWallet Style Guide
/// (`docs/design/pdf/NovaWallet Style Guide.pdf` p. 4) and `docs/DESIGN_SYSTEM.md` §6.
abstract final class AppRadii {
  // --- Raw values in logical pixels ---
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  // --- Radius constants ---
  static const Radius smRadius = Radius.circular(sm);
  static const Radius mdRadius = Radius.circular(md);
  static const Radius lgRadius = Radius.circular(lg);
  static const Radius xlRadius = Radius.circular(xl);
  static const Radius pillRadius = Radius.circular(pill);

  // --- BorderRadius constants ---
  static const BorderRadius smBorderRadius = BorderRadius.all(smRadius);
  static const BorderRadius mdBorderRadius = BorderRadius.all(mdRadius);
  static const BorderRadius lgBorderRadius = BorderRadius.all(lgRadius);
  static const BorderRadius xlBorderRadius = BorderRadius.all(xlRadius);
  static const BorderRadius pillBorderRadius = BorderRadius.all(pillRadius);

  // --- RoundedRectangleBorder shapes ---
  static const RoundedRectangleBorder smShape = RoundedRectangleBorder(
    borderRadius: smBorderRadius,
  );
  static const RoundedRectangleBorder mdShape = RoundedRectangleBorder(
    borderRadius: mdBorderRadius,
  );
  static const RoundedRectangleBorder lgShape = RoundedRectangleBorder(
    borderRadius: lgBorderRadius,
  );
  static const RoundedRectangleBorder xlShape = RoundedRectangleBorder(
    borderRadius: xlBorderRadius,
  );
  static const RoundedRectangleBorder pillShape = RoundedRectangleBorder(
    borderRadius: pillBorderRadius,
  );
}
