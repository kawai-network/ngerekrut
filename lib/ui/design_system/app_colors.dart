import 'package:flutter/material.dart';

/// Unified color palette for NgeRekrut app
/// Uses Emerald Green as primary for growth/recruitment theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF10B981); // Emerald green
  static const Color primaryLight = Color(0x3410B981); // 20% opacity
  static const Color primaryDark = Color(0xFF047857); // Darker emerald

  // Secondary Colors (for AI features)
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color secondaryLight = Color(0x346366F1);
  static const Color secondaryDark = Color(0xFF4338CA);

  // Semantic Colors
  static const Color success = Color(0xFF166534);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0F766E);
  static const Color infoLight = Color(0xFFCCFBF1);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE5E7EB);
  static const Color neutral400 = Color(0xFFD1D5DB);
  static const Color neutral500 = Color(0xFF9CA3AF);
  static const Color neutral600 = Color(0xFF6B7280);
  static const Color neutral700 = Color(0xFF4B5563);
  static const Color neutral800 = Color(0xFF374151);
  static const Color neutral900 = Color(0xFF1F2937);

  // Text Colors
  static const Color textPrimary = Color(0xFF101010);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40000000); // 25% black

  // Status-specific backgrounds
  static const Color statusPublished = Color(0xFFDCFCE7);
  static const Color statusDraft = Color(0xFFF3F4F6);
  static const Color statusClosed = Color(0xFFFEE2E2);
  static const Color statusActive = Color(0xFFDCFCE7);

  // Status-specific foregrounds
  static const Color statusPublishedText = Color(0xFF166534);
  static const Color statusDraftText = Color(0xFF4B5563);
  static const Color statusClosedText = Color(0xFFB91C1C);
  static const Color statusActiveText = Color(0xFF166534);

  // Match category colors for job recommendations
  static const Color matchVeryHigh = Color(0xFF10B981);
  static const Color matchHigh = Color(0xFF3B82F6);
  static const Color matchMedium = Color(0xFFF59E0B);
  static const Color matchLow = Color(0xFF9CA3AF);

  // Gradient colors
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12372A), Color(0xFF1C6758)],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  /// Get status background color based on job status
  static Color getStatusBackground(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'published':
        return statusPublished;
      case 'draft':
        return statusDraft;
      case 'closed':
        return statusClosed;
      case 'active':
        return statusActive;
      default:
        return neutral100;
    }
  }

  /// Get status text color based on job status
  static Color getStatusText(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'published':
        return statusPublishedText;
      case 'draft':
        return statusDraftText;
      case 'closed':
        return statusClosedText;
      case 'active':
        return statusActiveText;
      default:
        return neutral700;
    }
  }

  /// Get localized status label
  static String getStatusLabel(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'published':
        return 'Aktif';
      case 'draft':
        return 'Draft';
      case 'closed':
        return 'Ditutup';
      case 'active':
        return 'Aktif';
      default:
        return status;
    }
  }
}
