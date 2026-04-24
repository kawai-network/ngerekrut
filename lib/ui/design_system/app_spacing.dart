import 'package:flutter/widgets.dart';

/// Unified spacing tokens for consistent layout
/// Uses 4px base unit (following Material Design guidelines)
class AppSpacing {
  AppSpacing._();

  // Base spacing values (4px unit)
  static const double unit = 4.0;

  // Scale
  static const double xs = 4.0;   // 1 unit
  static const double sm = 8.0;   // 2 units
  static const double md = 12.0;  // 3 units
  static const double lg = 16.0;  // 4 units
  static const double xl = 24.0;  // 6 units
  static const double xxl = 32.0; // 8 units
  static const double xxxl = 48.0; // 12 units

  // Edge Insets for common patterns
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  // Horizontal spacing
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical spacing
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  // Screen padding (standard)
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Button padding
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );

  // Section spacing
  static const double sectionGap = xl;
  static const double itemGap = md;
  static const double smallGap = sm;

  // Icon spacing
  static const double iconSpacing = sm;
  static const double iconWithTextSpacing = md;

  // Form spacing
  static const double formFieldGap = md;
  static const double formSectionGap = xl;
}
