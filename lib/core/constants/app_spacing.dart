import 'package:flutter/material.dart';

/// Unified spacing constants for the entire application
/// Follows 4px base unit: 4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64, 72, 80
class AppSpacing {
  // 4px base unit
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 56.0;
  static const double xl7 = 64.0;
  static const double xl8 = 72.0;
  static const double xl9 = 80.0;

  // Common combinations
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXl2 = EdgeInsets.all(xl2);

  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 50.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXl = 32.0;

  // Avatar sizes
  static const double avatarSmall = 24.0;
  static const double avatarMedium = 32.0;
  static const double avatarLarge = 48.0;
  static const double avatarXl = 64.0;

  // Touch target minimum (accessibility)
  static const double touchTargetMin = 40.0;

  // Card and component dimensions
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 8.0;
}
