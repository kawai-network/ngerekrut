import 'package:flutter/material.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_border_radius.dart';
import '../design_system/app_colors.dart';

/// Consistent button component that enforces the design system
enum AppButtonVariant { primary, secondary, tertiary, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
    this.fullWidth = false,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final AppButtonIconPosition iconPosition;
  final bool fullWidth;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = isEnabled && !isLoading;

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: effectiveEnabled ? onPressed : null,
          style: _getPrimaryStyle(context),
          child: _buildContent(context),
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: effectiveEnabled ? onPressed : null,
          style: _getSecondaryStyle(context),
          child: _buildContent(context),
        );
        break;
      case AppButtonVariant.tertiary:
        button = FilledButton.tonal(
          onPressed: effectiveEnabled ? onPressed : null,
          style: _getTertiaryStyle(context),
          child: _buildContent(context),
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveEnabled ? onPressed : null,
          style: _getTextStyle(context),
          child: _buildContent(context),
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == AppButtonVariant.text
              ? AppColors.primary
              : Colors.white,
        ),
      );
    }

    if (icon != null) {
      final iconWidget = Icon(icon, size: _getIconSize());
      final textWidget = Text(label);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: iconPosition == AppButtonIconPosition.left
            ? [iconWidget, const SizedBox(width: AppSpacing.sm), textWidget]
            : [textWidget, const SizedBox(width: AppSpacing.sm), iconWidget],
      );
    }

    return Text(label);
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonPaddingSmall;
      case AppButtonSize.medium:
        return AppSpacing.buttonPaddingMedium;
      case AppButtonSize.large:
        return AppSpacing.buttonPaddingLarge;
    }
  }

  ButtonStyle _getPrimaryStyle(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutral300,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
    );
  }

  ButtonStyle _getSecondaryStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.neutral400,
      padding: _getPadding(),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
    );
  }

  ButtonStyle _getTertiaryStyle(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.neutral100,
      foregroundColor: AppColors.textPrimary,
      disabledBackgroundColor: AppColors.neutral200,
      padding: _getPadding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.buttonRadius),
      ),
    );
  }

  ButtonStyle _getTextStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.neutral400,
      padding: _getPadding(),
    );
  }
}

enum AppButtonIconPosition { left, right }

/// Icon-only button for use in toolbars and cards
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final iconSize = _getIconSize();

    Widget button = IconButton(
      icon: isLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: variant == AppButtonVariant.text
                    ? AppColors.primary
                    : null,
              ),
            )
          : Icon(icon, size: iconSize),
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      style: _getButtonStyle(),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 18;
      case AppButtonSize.medium:
        return 22;
      case AppButtonSize.large:
        return 26;
    }
  }

  ButtonStyle? _getButtonStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        );
      case AppButtonVariant.secondary:
        return IconButton.styleFrom(
          foregroundColor: AppColors.primary,
        );
      case AppButtonVariant.tertiary:
        return IconButton.styleFrom(
          backgroundColor: AppColors.neutral100,
        );
      case AppButtonVariant.text:
        return null;
    }
  }
}
