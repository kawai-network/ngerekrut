import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unified typography system for consistent text styling
/// Based on Material Design 3 typography scale
class AppTextStyles {
  AppTextStyles._();

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Display styles (large headings)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: bold,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // Custom styles for specific use cases
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // Helper methods for colored text
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  // Context-specific styles
  static TextStyle get cardTitle => titleMedium;
  static TextStyle get cardSubtitle => bodyMedium.copyWith(
        color: AppColors.textSecondary,
      );
  static TextStyle get cardBody => bodySmall.copyWith(
        color: AppColors.textSecondary,
      );

  static TextStyle get chip => labelMedium;
  static TextStyle get statusPill => labelSmall.copyWith(
        fontWeight: semiBold,
      );

  static TextStyle get errorMessage => bodyMedium.copyWith(
        color: AppColors.error,
      );
  static TextStyle get successMessage => bodyMedium.copyWith(
        color: AppColors.success,
      );

  // Dashboard specific
  static TextStyle get metricValue => displaySmall.copyWith(
        fontSize: 32,
        fontWeight: extraBold,
      );
  static TextStyle get metricLabel => labelMedium.copyWith(
        color: AppColors.textSecondary,
      );
  static TextStyle get metricHelper => caption;
}
