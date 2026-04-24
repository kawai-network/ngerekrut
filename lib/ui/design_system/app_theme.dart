import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_border_radius.dart';
import 'app_text_styles.dart';

/// Unified theme configuration for both Recruiter and Job Seeker apps
/// Uses Emerald Green as primary color
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      bottomNavigationBarTheme: _bottomNavBarTheme,
      navigationBarTheme: _navigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
      dividerTheme: _dividerTheme,
      textTheme: _textTheme,
      bottomSheetTheme: _bottomSheetTheme,
      dialogTheme: _dialogTheme,
      tabBarTheme: _tabBarTheme,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.neutral900,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      chipTheme: _chipTheme,
      bottomNavigationBarTheme: _darkBottomNavBarTheme,
      navigationBarTheme: _darkNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      snackBarTheme: _snackBarTheme,
      dividerTheme: _dividerTheme,
      textTheme: _darkTextTheme,
      bottomSheetTheme: _darkBottomSheetTheme,
      dialogTheme: _darkDialogTheme,
      tabBarTheme: _darkTabBarTheme,
    );
  }

  // Color schemes
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.secondaryDark,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.error,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    outline: AppColors.border,
    outlineVariant: AppColors.neutral300,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorDark,
    onErrorContainer: AppColors.errorLight,
    background: AppColors.neutral900,
    onBackground: AppColors.textInverse,
    surface: AppColors.neutral800,
    onSurface: AppColors.textInverse,
    outline: AppColors.neutral600,
    outlineVariant: AppColors.neutral700,
  );

  // AppBar theme
  static const AppBarTheme _appBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
    titleTextStyle: AppTextStyles.titleLarge,
    surfaceTintColor: Colors.transparent,
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: AppColors.neutral900,
    foregroundColor: AppColors.textInverse,
    iconTheme: IconThemeData(color: AppColors.textInverse),
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textInverse,
    ),
    surfaceTintColor: Colors.transparent,
  );

  // Card theme
  static const CardTheme _cardTheme = CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.medium)),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.only(bottom: AppSpacing.md),
  );

  static const CardTheme _darkCardTheme = CardTheme(
    elevation: 1,
    color: AppColors.neutral800,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.medium)),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.only(bottom: AppSpacing.md),
  );

  // Button themes
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: AppSpacing.buttonPaddingMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
      textStyle: AppTextStyles.button,
    ),
  );

  static final FilledButtonThemeData _filledButtonTheme =
      FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: AppSpacing.buttonPaddingMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
      textStyle: AppTextStyles.button,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: AppSpacing.buttonPaddingMedium,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
      textStyle: AppTextStyles.button,
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: AppSpacing.buttonPaddingMedium,
      textStyle: AppTextStyles.button,
    ),
  );

  // Input decoration theme
  static const InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: AppSpacing.buttonPaddingMedium,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: TextStyle(color: AppColors.textSecondary),
    hintStyle: TextStyle(color: AppColors.textTertiary),
  );

  static const InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.neutral800,
    contentPadding: AppSpacing.buttonPaddingMedium,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.neutral600),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.neutral600),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.inputRadius),
      ),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: TextStyle(color: AppColors.neutral400),
    hintStyle: TextStyle(color: AppColors.neutral500),
  );

  // Chip theme
  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.chip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.chipRadius),
        ),
        side: BorderSide.none,
      );

  // Bottom nav bar theme
  static const BottomNavigationBarThemeData _bottomNavBarTheme =
      BottomNavigationBarThemeData(
    elevation: 8,
    backgroundColor: AppColors.background,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    selectedLabelStyle: AppTextStyles.labelMedium,
    unselectedLabelStyle: AppTextStyles.labelMedium,
    type: BottomNavigationBarType.fixed,
  );

  static const BottomNavigationBarThemeData _darkBottomNavBarTheme =
      BottomNavigationBarThemeData(
    elevation: 8,
    backgroundColor: AppColors.neutral900,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.neutral400,
    selectedLabelStyle: AppTextStyles.labelMedium,
    unselectedLabelStyle: AppTextStyles.labelMedium,
    type: BottomNavigationBarType.fixed,
  );

  // Navigation bar theme (Material 3)
  static const NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
    elevation: 0,
    backgroundColor: AppColors.background,
    indicatorColor: AppColors.primaryLight,
    labelTextStyle: WidgetStatePropertyAll(AppTextStyles.labelMedium),
    iconTheme: WidgetStatePropertyAll(
      IconThemeData(
        color: AppColors.textSecondary,
      ),
    ),
    selectedIconTheme: WidgetStatePropertyAll(
      IconThemeData(
        color: AppColors.primary,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: AppTextStyles.semiBold,
        );
      }
      return AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
      );
    }),
  );

  static const NavigationBarThemeData _darkNavigationBarTheme =
      NavigationBarThemeData(
    elevation: 0,
    backgroundColor: AppColors.neutral900,
    indicatorColor: AppColors.primaryDark,
    labelTextStyle: WidgetStatePropertyAll(AppTextStyles.labelMedium),
    iconTheme: WidgetStatePropertyAll(
      IconThemeData(
        color: AppColors.neutral400,
      ),
    ),
    selectedIconTheme: WidgetStatePropertyAll(
      IconThemeData(
        color: AppColors.primary,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: AppTextStyles.semiBold,
        );
      }
      return AppTextStyles.labelMedium.copyWith(
        color: AppColors.neutral400,
      );
    }),
  );

  // FAB theme
  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.buttonRadius),
      ),
    ),
    extendedTextStyle: AppTextStyles.button,
  );

  // Snack bar theme
  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppBorderRadius.medium),
        ),
        contentTextStyle: AppTextStyles.bodyMedium,
      );

  // Divider theme
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  );

  // Text theme
  static TextTheme get _textTheme => TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );

  static TextTheme get _darkTextTheme => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textInverse,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textInverse,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: AppColors.textInverse,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textInverse,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textInverse,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textInverse,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textInverse,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textInverse,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textInverse,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.neutral200,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral300,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.neutral400,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textInverse,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.neutral300,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.neutral400,
        ),
      );

  // Bottom sheet theme
  static BottomSheetThemeData get _bottomSheetTheme => BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.large),
          ),
        ),
        backgroundColor: AppColors.background,
        clipBehavior: Clip.antiAlias,
      );

  static BottomSheetThemeData get _darkBottomSheetTheme => BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.large),
          ),
        ),
        backgroundColor: AppColors.neutral800,
        clipBehavior: Clip.antiAlias,
      );

  // Dialog theme
  static const DialogTheme _dialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.large),
      ),
    ),
    backgroundColor: AppColors.background,
  );

  static const DialogTheme _darkDialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(AppBorderRadius.large),
      ),
    ),
    backgroundColor: AppColors.neutral800,
  );

  // Tab bar theme
  static TabBarTheme get _tabBarTheme => TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      );

  static TabBarTheme get _darkTabBarTheme => TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.neutral400,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      );
}
