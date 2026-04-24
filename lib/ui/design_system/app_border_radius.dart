import 'package:flutter/widgets.dart';

/// Unified border radius tokens for consistent shapes
/// Standardized to 4 values for simplicity
class AppBorderRadius {
  AppBorderRadius._();

  // Border radius values
  static const double small = 8.0;   // Chips, tags, small elements
  static const double medium = 12.0; // Cards, buttons, inputs
  static const double large = 16.0;  // Modals, sheets, containers
  static const double pill = 999.0;  // Status pills, rounded buttons

  // BorderRadius objects for direct use
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));

  // Specific component radii
  static const double cardRadius = medium;
  static const double buttonRadius = medium;
  static const double chipRadius = small;
  static const double statusPillRadius = pill;
  static const double inputRadius = medium;
  static const double sheetRadius = large;
  static const double modalRadius = large;

  // RRect helpers
  static RRect smallRRect(Rect rect) {
    return RRect.fromRectAndRadius(rect, const Radius.circular(small));
  }

  static RRect mediumRRect(Rect rect) {
    return RRect.fromRectAndRadius(rect, const Radius.circular(medium));
  }

  static RRect largeRRect(Rect rect) {
    return RRect.fromRectAndRadius(rect, const Radius.circular(large));
  }

  // Shape decorations
  static ShapeBorder smallShape = RoundedRectangleBorder(
    borderRadius: smallRadius,
  );

  static ShapeBorder mediumShape = RoundedRectangleBorder(
    borderRadius: mediumRadius,
  );

  static ShapeBorder largeShape = RoundedRectangleBorder(
    borderRadius: largeRadius,
  );
}
